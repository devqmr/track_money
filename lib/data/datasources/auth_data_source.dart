import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

abstract class AuthDataSource {
  /// Sign in with Google account
  Future<UserModel> signInWithGoogle();
  
  /// Sign out current user
  Future<void> signOut();
  
  /// Get current authenticated user
  Future<UserModel?> getCurrentUser();
  
  /// Update user settings
  Future<UserModel> updateUserSettings({
    required String userId, 
    String? defaultCurrency,
  });
  
  /// Check if user is currently signed in
  Future<bool> isSignedIn();
}

class AuthDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  
  AuthDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  }) : 
    _firebaseAuth = firebaseAuth,
    _googleSignIn = googleSignIn,
    _firestore = firestore;
  
  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign-In was canceled by the user');
      }
      
      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a credential with the token
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the credential
      final firebase_auth.UserCredential userCredential = 
        await _firebaseAuth.signInWithCredential(credential);
        
      final firebase_auth.User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }
      
      // Check if the user exists in Firestore
      final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();
        
      // User data to be stored in Firestore
      final now = DateTime.now();
      
      UserModel userModel;
      
      if (!userDoc.exists) {
        // Create new user profile in Firestore
        userModel = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'User',
          photoUrl: firebaseUser.photoURL ?? '',
          defaultCurrency: AppConstants.sarCurrency,
          createdAt: now,
          lastLoginAt: now,
        );
        
        // Save user data to Firestore
        await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toJson());
      } else {
        // Update last login time for returning user
        await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .update({'lastLoginAt': now.toIso8601String()});
          
        // Get the user data
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Update the lastLoginAt field in the local copy
        userData['lastLoginAt'] = now.toIso8601String();
        
        userModel = UserModel.fromJson(userData);
      }
      
      return userModel;
    } catch (e) {
      print('Google Sign-In error: $e');
      if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('ApiException: 10')) {
        throw Exception('Sign-in failed. Please verify your Firebase configuration and try again.');
      } else {
        throw Exception('Authentication failed: ${e.toString()}');
      }
    }
  }
  
  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
    
    if (firebaseUser == null) {
      return null;
    }
    
    // Get user data from Firestore
    final userDoc = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(firebaseUser.uid)
      .get();
      
    if (!userDoc.exists) {
      return null;
    }
    
    return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
  }
  
  @override
  Future<UserModel> updateUserSettings({
    required String userId, 
    String? defaultCurrency,
  }) async {
    // Build update map with only provided values
    final Map<String, dynamic> updates = {};
    
    if (defaultCurrency != null) {
      updates['defaultCurrency'] = defaultCurrency;
    }
    
    // Add updatedAt timestamp
    updates['updatedAt'] = DateTime.now().toIso8601String();
    
    // Update Firestore
    await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .update(updates);
      
    // Fetch updated user data
    final userDoc = await _firestore
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .get();
      
    return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
  }
  
  @override
  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }
} 