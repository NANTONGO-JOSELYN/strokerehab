# RehabCoach App Navigation Flow - Complete Setup

## Overview
Your Flutter stroke rehabilitation app now has a complete authentication and navigation flow with the following structure:

## Navigation Flow
```
Splash Screen (3 sec)
    ↓
    ├─→ User NOT logged in → Login Screen
    │   ├─→ New user → Sign Up Screen → Onboarding (3 pages) → Role Selection → Home
    │   └─→ Existing user → Login → Role Selection → Home
    │
    └─→ User logged in & completed onboarding → Role Selection → Home
```

## Files Created

### 1. **Authentication System**
- **lib/models/user.dart** - User model with role (Patient/Clinician)
- **lib/providers/auth_provider.dart** - State management for authentication

### 2. **Navigation Screens**
- **lib/screens/splash_screen.dart** - Initial splash screen (3 sec delay)
- **lib/screens/login_screen.dart** - Login with role selection (Patient/Clinician)
- **lib/screens/signup_screen.dart** - New user registration
- **lib/screens/onboarding_screen.dart** - 3-page onboarding tutorial
- **lib/screens/role_selection_screen.dart** - Post-login role confirmation screen

### 3. **Main App**
- **lib/main.dart** - Updated with AuthProvider and SplashScreen as entry point

## Key Features

### 🔐 Authentication
- Email/password login and sign-up
- Role selection (Patient or Clinician)
- Local persistence using SharedPreferences
- Mock authentication (replace with real API calls)

### 🎯 Onboarding
- 3-page guided tour for first-time users
- Welcome → How It Works → Get Started
- Skip option on first page
- Progress indicator

### 👤 Role Selection
- Patient: Access home dashboard and exercises
- Clinician: Access clinician portal (coming soon)
- Easy role switching

## Testing the App

### Quick Test Flow:
1. **Splash Screen** appears (3 seconds)
2. **Login Screen** - Try these test credentials:
   - Email: `test@example.com`
   - Password: `password123`
   - Select Role: Patient or Clinician
3. **Onboarding** - 3 pages to guide through features
4. **Role Selection** - Choose Patient or Clinician
5. **Home Dashboard** - Main patient interface

### Test Accounts:
```
Patient:
- Email: patient@rehab.com
- Password: patient123
- Role: Patient

Clinician:
- Email: doctor@rehab.com
- Password: doctor123
- Role: Clinician
```

## Next Steps to Complete the 15-Screen Flow

### Remaining Screens to Create:
1. **Exercise Selection** (5 exercises)
2. **Pain/Fatigue Check**
3. **BLE Device Connection**
4. **Live Monitoring**
5. **Results + Corrections**
6. **Session History** *(partially done)*
7. **Progress & Charts**
8. **Schedule & Reminders**
9. **Achievements & Badges**
10. **PDF Report Export**
11. **Clinician Portal** *(dashboard for clinicians)*

## Architecture Notes

### State Management
- **AuthProvider** - Handles login/signup/logout/onboarding state
- **RehabSessionProvider** - Existing provider for exercise sessions
- Add providers as needed for other features

### Local Storage
- User data persisted via SharedPreferences
- Remove login screen on app restart if user is authenticated
- Auto-logout functionality available

### Navigation Pattern
- Splash → Authentication → Onboarding → Main App
- Use `Navigator.pushReplacement()` to prevent back navigation at auth boundary
- Home screen has bottom navigation for main features

## Customization Points

### Change Mock Authentication to Real API:
In `lib/providers/auth_provider.dart`:
- Replace `login()` method with actual API call
- Replace `signUp()` method with actual API call
- Add token management (JWT, etc.)

### Update Colors/Branding:
- Main gradient: `Colors.blue[900]` to `Colors.purple[900]`
- Edit each screen file to customize

### Add More Onboarding Pages:
In `lib/screens/onboarding_screen.dart`:
- Add more `_OnboardingPageX` classes
- Update page count from 3 to N
- Update progress indicator logic

## Running the App

```bash
cd stroke_rehab_app
flutter pub get
flutter run
```

## Common Issues & Solutions

**Issue**: Splash screen shows forever
- **Solution**: Check that SharedPreferences initializes properly in AuthProvider

**Issue**: Can't navigate past login
- **Solution**: Ensure AuthProvider is added to MultiProvider in main.dart

**Issue**: Onboarding appears on every restart
- **Solution**: Check that `completeOnboarding()` is called and user is persisted

---

**Status**: ✅ Core authentication and navigation flow complete  
**Ready for**: Feature development (exercises, monitoring, etc.)
