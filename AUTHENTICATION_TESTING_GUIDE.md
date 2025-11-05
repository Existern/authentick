# Authentication API Testing Guide

This guide will help you test the authentication API integration in your Flutter app, even if you're new to Flutter.

## Prerequisites

Before testing, you need to:

1. **Update the API Base URL**
   - Open `lib/features/common/remote/api_client.dart`
   - Find line 17: `static const String _baseUrl = 'https://your-api-url.com/api';`
   - Replace `'https://your-api-url.com/api'` with your actual API URL
   - Example: `static const String _baseUrl = 'https://api.example.com/api';`

2. **Ensure your backend API is running and accessible**

## How to Run the App

### For Android:
```bash
flutter run
```

### For iOS (requires macOS):
```bash
flutter run
```

### For Web:
```bash
flutter run -d chrome
```

### For Windows:
```bash
flutter run -d windows
```

## Testing the Google Sign-In Authentication

### Step 1: Launch the App
Run the app using one of the commands above.

### Step 2: Navigate to Sign-In Screen
The app should show you a registration/sign-in screen with a "Sign in with Google" button.

### Step 3: Click "Sign in with Google"
1. Click the Google sign-in button
2. Select your Google account or sign in with your credentials
3. Grant the necessary permissions

### Step 4: What Happens Behind the Scenes
When you click "Sign in with Google", the app will:

1. **Get Google ID Token**: The app uses Google Sign-In SDK to authenticate and get an ID token
2. **Send to Your Backend**: The app sends a POST request to `/auth/authenticate` with:
   ```json
   {
     "google_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
     "username": "user"
   }
   ```
3. **Receive Response**: Your backend should verify the Google token and respond with:
   ```json
   {
     "success": true,
     "data": {
       "token": "your-auth-token",
       "user": {
         "id": "user123",
         "email": "user@gmail.com",
         "first_name": "John",
         "last_name": "Doe",
         "username": "johndoe",
         ...
       }
     },
     "meta": {...}
   }
   ```
4. **Store Token**: The app saves the auth token locally in SharedPreferences
5. **Update UI**: The app navigates to the home screen

## Checking if Authentication Worked

### Method 1: Check the Debug Console
Look for log messages in your IDE's debug console:

```
FMR REQUEST[POST] => PATH: /auth/authenticate
FMR Headers: {Authorization: Bearer null, Content-Type: application/json, ...}
FMR Data: {google_token: ..., username: ...}
FMR RESPONSE[200] => PATH: /auth/authenticate
FMR Data: {success: true, data: {...}}
```

### Method 2: Check App Behavior
- If authentication succeeds, you should be redirected to the main/home screen
- If it fails, you'll see an error message

### Method 3: Verify Token Storage
The authentication token is stored in SharedPreferences with key `auth_token_key`.

On Android, you can check using:
```bash
adb shell run-as com.your.app.id cat /data/data/com.your.app.id/shared_prefs/FlutterSharedPreferences.xml
```

## Testing Different Scenarios

### Test Case 1: New User Registration
1. Sign in with a Google account that doesn't exist in your backend
2. Expected: Backend creates new user account
3. Check: `isRegisterSuccessfully` should be `true` in the app

### Test Case 2: Existing User Login
1. Sign in with a Google account that already exists in your backend
2. Expected: Backend returns existing user data
3. Check: `isSignInSuccessfully` should be `true` in the app

### Test Case 3: Authentication Error (401)
1. Configure your backend to reject authentication
2. Expected: App shows error message "Unauthorized access"

### Test Case 4: Network Error
1. Turn off your backend server or disconnect from internet
2. Expected: App shows error message "No internet connection" or "Connection timeout"

## Debugging Common Issues

### Issue 1: "Connection timeout" or "No internet connection"
**Causes:**
- Backend API is not running
- Wrong API base URL in `api_client.dart`
- Firewall blocking the connection
- Using `localhost` on physical device (use computer's IP address instead)

**Solutions:**
- Verify backend is running: `curl https://your-api-url.com/api/auth/authenticate`
- Check API base URL in `lib/features/common/remote/api_client.dart`
- Use your computer's IP address instead of localhost (e.g., `http://192.168.1.100:3000/api`)

### Issue 2: "Unauthorized access" (401 error)
**Causes:**
- Backend failed to verify Google ID token
- Google token expired

**Solutions:**
- Check backend logs to see why verification failed
- Ensure your backend has Google OAuth client ID configured

### Issue 3: "Google sign in was cancelled"
**Causes:**
- User cancelled the Google sign-in flow
- Google Sign-In not properly configured

**Solutions:**
- Try signing in again
- Check Google Sign-In configuration in your Firebase project (if using Firebase)

### Issue 4: Build errors after code generation
**Causes:**
- Missing generated files

**Solutions:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Using API Testing Tools

You can also test the API directly using tools like Postman or curl:

### Example: Test with curl (Google Token)
```bash
curl -X POST https://your-api-url.com/api/auth/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "google_token": "YOUR_GOOGLE_ID_TOKEN",
    "username": "testuser"
  }'
```

### Example: Test with curl (Bearer Token)
```bash
curl -X POST https://your-api-url.com/api/auth/authenticate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_BEARER_TOKEN" \
  -d '{
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User"
  }'
```

## Monitoring Network Requests

### Using Flutter DevTools:
1. Run your app with `flutter run`
2. Open Flutter DevTools in your browser (URL shown in console)
3. Go to "Network" tab
4. Perform authentication
5. You'll see all HTTP requests/responses

### Using Charles Proxy or Proxyman:
1. Install Charles Proxy or Proxyman
2. Configure your device/emulator to use the proxy
3. Perform authentication
4. View the complete request/response details

## Understanding the Code Flow

When you click "Sign in with Google", here's what happens:

```
1. UI (sign_in_with_google.dart)
   ↓ User clicks button

2. ViewModel (authentication_view_model.dart)
   ↓ Calls signInWithGoogle()

3. Repository (authentication_repository.dart)
   ↓ Gets Google ID token
   ↓ Calls authenticate() method

4. API Client (api_client.dart)
   ↓ Sends POST to /auth/authenticate
   ↓ With Authorization header (if bearer token provided)

5. Your Backend API
   ↓ Verifies Google token
   ↓ Creates/retrieves user
   ↓ Returns AuthResponse

6. Repository
   ↓ Saves auth token to SharedPreferences
   ↓ Sets isLogin = true

7. ViewModel
   ↓ Updates profile with user data
   ↓ Sets authentication state

8. UI
   ↓ Navigates to home screen
```

## Key Files to Know

| File | Purpose |
|------|---------|
| `lib/features/common/remote/api_client.dart` | HTTP client, configure base URL here |
| `lib/features/authentication/repository/authentication_repository.dart` | Authentication logic, API calls |
| `lib/features/authentication/model/auth_request.dart` | Request model |
| `lib/features/authentication/model/auth_response.dart` | Response model |
| `lib/features/authentication/model/user.dart` | User data model |
| `lib/features/authentication/ui/view_model/authentication_view_model.dart` | State management |
| `lib/constants/constants.dart` | Constants including SharedPreferences keys |

## Next Steps

After successful testing:

1. **Add Error Handling**: Customize error messages in your UI
2. **Add Loading Indicators**: Show spinners during authentication
3. **Implement Token Refresh**: Add logic to refresh expired tokens
4. **Add Logout**: Implement sign-out functionality (already partially implemented)
5. **Secure Token Storage**: Consider using `flutter_secure_storage` instead of SharedPreferences for production

## Need Help?

If you encounter issues:

1. Check the debug console for error messages
2. Verify your backend API is working with curl/Postman
3. Ensure API base URL is correct in `api_client.dart`
4. Check that your Google OAuth configuration is correct
5. Look for compilation errors after running build_runner

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Freezed Code Generation](https://pub.dev/packages/freezed)
- [Riverpod State Management](https://riverpod.dev/)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
