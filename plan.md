Create a daily expense tracking app in Flutter with the following requirements:

# App Overview
- App Name: "TrackMoney"
- Purpose: Help users track their daily expenses, categorize spending, and visualize spending patterns

# Core Features
1. User authentication:
   - Implement Firebase Authentication with Google Sign-In
   - Ensure proper user session management
2. Expense entry with:
   - Amount
   - Currency (SAR by default, with USD support)
   - Date
   - Category (customizable)
   - Payment method
   - Description
   - Optional photo receipt attachment (stored locally on device)
3. Dashboard showing:
   - Daily/weekly/monthly/yearly expense summaries
   - Category-wise expense breakdown
   - Spending trends visualization
4. Budget setting and alerts
5. Reports and expense analysis
6. Data export functionality
7. Recurring expense setup

# Firebase Implementation
1. Authentication:
   - Implement Firebase Authentication for secure user management
   - Use Google Sign-In as the primary authentication method
   - Implement proper authentication state management

2. Data Storage:
   - Use Firebase Cloud Firestore as the primary database
   - Implement proper data structure with collections and documents
   - Apply security rules to ensure users can only access their own data
   - Use user UID as the primary key for data segregation
   - Implement field-level security where appropriate

3. Offline Support:
   - Configure Cloud Firestore for offline persistence
   - Implement proper caching strategies
   - Handle synchronization conflicts appropriately
   - Provide clear UI indicators for offline/online status
   - Ensure seamless transition between offline and online modes

# Currency Management
1. Multi-currency support:
   - Support SAR (default) and USD currencies
   - Allow users to set their preferred default currency
   - Store currency preference in user settings
   - Implement a settings page for currency management
   - Design the system to be extensible for adding more currencies in the future

2. Currency Display:
   - Show appropriate currency symbols with amounts
   - Format numbers according to locale standards
   - Consider implementing a simple conversion utility

# Technical Requirements
- Use Flutter's latest stable version
- Implement clean architecture principles (presentation, domain, data layers)
- Follow SOLID design principles
- Use BLoC pattern for state management
- Implement repository pattern for data handling
- Ensure proper Firebase integration following best practices
- Implement comprehensive error handling and validation
- Write unit, widget, and integration tests (aim for 80%+ coverage)
- Use dependency injection for loose coupling
- Implement proper logging mechanism
- Follow semantic versioning

# UI/UX Guidelines
- Follow Material Design 3 principles
- Support both light and dark themes
- Ensure accessibility compliance
- Implement responsive design for different screen sizes
- Use meaningful animations for better user experience
- Provide clear feedback for user actions

# Security Requirements
- Secure storage of sensitive data using Flutter Secure Storage
- Implement proper authentication and authorization
- Sanitize all user inputs
- Encrypt locally stored data
- Configure proper Firestore security rules to ensure data isolation between users
- Implement proper error handling for authentication failures

# Performance Guidelines
- Optimize app startup time (<2 seconds)
- Minimize memory usage
- Implement efficient list rendering with pagination
- Optimize Firestore queries (use indexing appropriately)
- Implement proper caching strategies
- Monitor and optimize Firebase usage

# Code Quality Standards
- Use consistent coding style (follow Dart style guide)
- Document all public APIs and complex logic
- Implement meaningful error messages
- Use meaningful variable and function names
- Keep functions small and focused
- Apply proper exception handling
- Use linting tools (flutter_lints)

# Development Process
1. Start with detailed app architecture planning
2. Set up Firebase project and configure authentication
3. Create domain models first
4. Design and implement Firestore data structure
5. Implement core business logic
6. Build UI components
7. Connect UI with business logic
8. Implement Firebase authentication with Google Sign-In
9. Implement Firestore data persistence with offline support
10. Implement multi-currency support
11. Add local image storage for receipts
12. Implement analytics and reports
13. Polish UI/UX details
14. Optimize performance
15. Add testing
16. Configure proper Firestore security rules
17. Finalize documentation

Please implement this app following all best practices for Flutter development and Firebase integration, ensuring high code quality throughout the process.