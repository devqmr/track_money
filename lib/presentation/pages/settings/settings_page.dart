import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:track_money/core/utils/currency_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_event.dart';
import '../../bloc/settings/settings_state.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _currencyFormKey = GlobalKey<FormState>();
  final _categoryFormKey = GlobalKey<FormState>();
  final _paymentMethodFormKey = GlobalKey<FormState>();
  final _newCategoryController = TextEditingController();
  final _newPaymentMethodController = TextEditingController();
  final _newCurrencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsBloc>().add(LoadSettingsEvent(userId: authState.user.id));
    }
  }


  void _addCurrency() {
    if (_currencyFormKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<SettingsBloc>().add(
          AddCurrencyEvent(
            userId: authState.user.id,
            currency: _newCurrencyController.text.toUpperCase(),
            iconPath: '',
          ),
        );
        _newCurrencyController.clear();
      }
    }
  }

  void _addCategory() {
    if (_categoryFormKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<SettingsBloc>().add(
          AddCategoryEvent(
            userId: authState.user.id,
            category: _newCategoryController.text,
          ),
        );
        _newCategoryController.clear();
      }
    }
  }

  void _addPaymentMethod() {
    if (_paymentMethodFormKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<SettingsBloc>().add(
          AddPaymentMethodEvent(
            userId: authState.user.id,
            paymentMethod: _newPaymentMethodController.text,
          ),
        );
        _newPaymentMethodController.clear();
      }
    }
  }

  // Show confirmation dialog for resetting settings
  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset to Default Settings'),
          content: const SingleChildScrollView(
            child: Text(
              'This will reset all your currencies, categories, and payment methods to the default values. This action cannot be undone. Are you sure you want to continue?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetToDefaultSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Reset settings to default values
  void _resetToDefaultSettings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsBloc>().add(
        UpdateSettingsEvent(
          userId: authState.user.id,
          defaultCurrency: AppConstants.sarCurrency,
          currencies: [AppConstants.sarCurrency, AppConstants.usdCurrency, AppConstants.egpCurrency],
          categories: AppConstants.defaultCategories,
          paymentMethods: AppConstants.defaultPaymentMethods,
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings restored to defaults'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _newPaymentMethodController.dispose();
    _newCurrencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is SettingsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency Section
                  _buildSectionTitle('Currencies'),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.settings.currencies.length,
                    itemBuilder: (context, index) {
                      final currency = state.settings.currencies[index];
                      final isDefault = currency == state.settings.defaultCurrency;
                      final currencyColor = CurrencyUtils.getCurrencyColor(currency);
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: currencyColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              currency,
                              style: TextStyle(
                                color: currencyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        title: Text(currency),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDefault)
                              const Chip(
                                label: Text('Default'),
                                backgroundColor: Colors.green,
                              ),
                            if (!isDefault)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is AuthAuthenticated) {
                                    context.read<SettingsBloc>().add(
                                      RemoveCurrencyEvent(
                                        userId: authState.user.id,
                                        currency: currency,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          if (!isDefault) {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              context.read<SettingsBloc>().add(
                                SetDefaultCurrencyEvent(
                                  userId: authState.user.id,
                                  currency: currency,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _currencyFormKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newCurrencyController,
                            decoration: const InputDecoration(
                              labelText: 'New Currency Code',
                              hintText: 'e.g., EUR',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a currency code';
                              }
                              if (state.settings.currencies.contains(value.toUpperCase())) {
                                return 'Currency already exists';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCurrency,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories Section
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.settings.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.settings.categories[index];
                      return ListTile(
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              context.read<SettingsBloc>().add(
                                RemoveCategoryEvent(
                                  userId: authState.user.id,
                                  category: category,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _categoryFormKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'New Category',
                              hintText: 'e.g., Entertainment',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a category';
                              }
                              if (state.settings.categories.contains(value)) {
                                return 'Category already exists';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCategory,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods Section
                  _buildSectionTitle('Payment Methods'),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.settings.paymentMethods.length,
                    itemBuilder: (context, index) {
                      final paymentMethod = state.settings.paymentMethods[index];
                      return ListTile(
                        title: Text(paymentMethod),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              context.read<SettingsBloc>().add(
                                RemovePaymentMethodEvent(
                                  userId: authState.user.id,
                                  paymentMethod: paymentMethod,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _paymentMethodFormKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newPaymentMethodController,
                            decoration: const InputDecoration(
                              labelText: 'New Payment Method',
                              hintText: 'e.g., Credit Card',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a payment method';
                              }
                              if (state.settings.paymentMethods.contains(value)) {
                                return 'Payment method already exists';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addPaymentMethod,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Reset to Default Settings Button
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _showResetConfirmationDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restore, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Restore Default Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No settings available'));
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
} 