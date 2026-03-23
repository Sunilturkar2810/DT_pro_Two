# API Integration Guide - Authentication

## Overview
Your Flutter app now integrates with the backend APIs for user authentication (login and signup). The API calls are made to the backend server running on `http://localhost:5000`.

---

## 📁 New Files Created

### 1. **API Configuration** (`lib/config/api_constants.dart`)
Contains base URL and API endpoints configuration.

```dart
ApiConstants.baseUrl = 'http://localhost:5000'
ApiConstants.register = '/api/auth/register'
ApiConstants.login = '/api/auth/login'
```

### 2. **Authentication Models** (`lib/models/auth_models.dart`)
Data models for API requests and responses:
- `LoginRequest` - Login API request body
- `RegisterRequest` - Signup API request body
- `AuthUser` - User data model
- `LoginResponse` - Login API response
- `RegisterResponse` - Signup API response
- `ApiException` - Custom exception for API errors

### 3. **Authentication Service** (`lib/services/auth_service.dart`)
HTTP client for making API calls:
```dart
AuthService.login()      // Make login API call
AuthService.register()   // Make signup API call
```

### 4. **Updated Auth Provider** (`lib/provider/auth_provider.dart`)
Updated to use the API service instead of local storage:
- `login()` - Login with API
- `register()` - Register with API
- `checkAuthStatus()` - Restore session on app startup
- `logout()` - Clear authentication
- Properties: `isLoading`, `errorMessage`, `isAuthenticated`, `token`

---

## 🔄 API Endpoints Used

### 1. Login Endpoint
**URL:** `POST /api/auth/login`

**Request Body:**
```json
{
  "workEmail": "user@example.com",
  "password": "password123"
}
```

**Success Response (200 OK):**
```json
{
  "message": "Login successful",
  "token": "JWT_TOKEN_HERE",
  "user": {
    "id": "uuid-string",
    "firstName": "John",
    "lastName": "Doe",
    "workEmail": "john.doe@example.com",
    "role": "Admin"
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "message": "Invalid credentials"
}
```

---

### 2. Register Endpoint
**URL:** `POST /api/auth/register`

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "workEmail": "john.doe@example.com",
  "password": "Security@123",
  "mobileNumber": "+919876543210",
  "role": "Admin",
  "designation": "Software Engineer",
  "department": "Engineering"
}
```

**Success Response (201 Created):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid-string",
    "workEmail": "john.doe@example.com"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "message": "User with this email already exists"
}
```

---

## 🛠️ Implementation Details

### Authentication Flow

#### Login Flow:
1. User enters email and password in login screen
2. `AuthProvider.login()` is called
3. Sends POST request to `/api/auth/login`
4. On success:
   - Token and user info stored in Hive (persistent storage)
   - User navigated to Dashboard
5. On error:
   - Error message displayed to user
   - User stays on login screen

#### Registration Flow:
1. User fills signup form (name, email, password, designation, department, etc.)
2. Form validation on client side
3. `AuthProvider.register()` is called
4. Sends POST request to `/api/auth/register`
5. On success:
   - User account created on backend
   - User redirected to login screen
6. On error:
   - Error message displayed (e.g., email already exists)

---

## 📱 Updated Screens

### **Login Screen** (`lib/screen/auth/login/login.dart`)
**Changes:**
- Changed from "User ID" to "Work Email" field
- Integrated with new API endpoints
- Shows loading state during API call
- Displays error messages from API
- Responsive design maintained

**Fields:**
- Work Email (required)
- Password (required)

### **Signup Screen** (`lib/screen/auth/signup/signup_screen.dart`)
**Changes:**
- Updated to match API requirements
- Added all required fields: first name, last name, mobile, designation, department
- Form validation before API call
- Better error handling
- Responsive design maintained

**Fields:**
- First Name (required)
- Last Name (required)
- Work Email (required)
- Mobile Number (required)
- Designation (required - dropdown)
- Department (required - dropdown)
- Role (optional - defaults to User)
- Password (required, min 6 chars)
- Confirm Password (required)

---

## 🔐 Data Security

### Token Storage
- JWT token stored in Hive local storage
- Token sent in Authorization header for future API calls
- Token cleared on logout

### Session Management
- `checkAuthStatus()` restores user session on app startup
- User stays logged in even after app restart
- Logout clears all stored authentication data

---

## 🐛 Error Handling

### API Exceptions
All API errors are caught and handled gracefully:

```dart
try {
  await authService.login(...);
} on ApiException catch (e) {
  print('Error: ${e.message}');
  print('Status: ${e.statusCode}');
}
```

### User-Friendly Messages
- Network errors: "Network error: [specific message]"
- Invalid credentials: "Invalid credentials"
- User exists: "User with this email already exists"
- Validation errors: Specific field validation messages

---

## 🔧 Dependencies Added

Added to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0  # HTTP client for API calls
```

Run `flutter pub get` to install dependencies.

---

## ⚙️ Configuration

### Change API Base URL
Edit `lib/config/api_constants.dart`:
```dart
static const String baseUrl = 'http://localhost:5000'; // Change here
```

### For Production
Update for your production server:
```dart
static const String baseUrl = 'https://api.yourdomain.com';
```

---

## 🚀 How to Test

### Prerequisites
1. Backend server running on `http://localhost:5000`
2. Database migrations applied (`npm run db:push`)

### Test Login
1. Open app and go to login screen
2. Enter work email and password
3. Click Login
4. Should navigate to Dashboard if credentials are correct

### Test Signup
1. Go to signup screen
2. Fill all required fields
3. Click Sign Up
4. Should show success message and redirect to login
5. Try logging in with new credentials

### Test Session Persistence
1. Login to the app
2. Close the app completely
3. Reopen the app
4. Should be logged in directly (no need to login again)

---

## 📊 API Response Models

### AuthUser Model
```dart
AuthUser(
  id: String,           // User UUID
  firstName: String,
  lastName: String,
  workEmail: String,
  role: String,         // Admin, Manager, User
  designation: String?, // Job title
  department: String?,  // Department
  mobileNumber: String? // Contact number
)
```

### LoginResponse Model
```dart
LoginResponse(
  message: String,  // "Login successful"
  token: String,    // JWT token for subsequent requests
  user: AuthUser    // User details
)
```

### RegisterResponse Model
```dart
RegisterResponse(
  message: String,  // "User registered successfully"
  user: AuthUser    // User details
)
```

---

## 🔗 Integration with Other Features

After implementing this API integration, you can:
1. Add authorization headers to all future API calls
2. Use the stored token for protected endpoints
3. Implement token refresh mechanism for expired tokens
4. Add role-based access control (RBAC)
5. Create interceptors for API calls

---

## 📚 Next Steps

1. Test the login/signup flows thoroughly
2. Verify API responses match the expected format
3. Implement additional API endpoints (tasks, users, etc.)
4. Add JWT token validation and refresh
5. Implement offline mode with cached data
6. Add comprehensive error handling for all API calls

---

## 🆘 Troubleshooting

### "Network error" on Login/Signup
- Ensure backend server is running on `http://localhost:5000`
- Check API base URL in `api_constants.dart`
- Verify CORS is enabled on backend

### "Invalid credentials" Error
- Check email format (should be a valid email)
- Verify user exists on backend
- Check password is correct

### "User with this email already exists"
- Email already registered in database
- Use a different email for signup

### App doesn't restore session on restart
- Check Hive box 'settingsBox' is opened in main.dart
- Verify token is saved correctly during login

---

Made with ❤️ for secure authentication!
