# datul_advmobprog3

## Lab Activity 5: Firebase Authentication & UserService Integration

### Laboratory Discussion

#### 1. Workflow for DummyJSON vs. Firebase Implementation (From Sign In to Sign Up)

This application supports a dual-authentication workflow (`LoginType.dummyJson` and `LoginType.firebase`) orchestrated through a unified service layer (`UserService`):

1. **Sign Up Workflow (`SignupScreen` -> `UserService`)**:
   - **UI & Validation (`lib/screens/signup_screen.dart`)**:
     - The user fills out the registration form containing `fName` (First Name), `lName` (Last Name), `age`, `contactNo` (Phone), `username`, `emailAddress`, and `password` (validated for format, required fields, numeric age constraints, and minimum 6-character password security).
   - **Firebase Account Creation (`createAccount` & `updateUsername`)**:
     - `UserService().createAccount(email: emailAddress, password: password)` invokes `FirebaseAuth.instance.createUserWithEmailAndPassword()` to register the user credentials securely on Firebase Authentication servers and issue a signed JWT ID token and unique `uid`.
     - Immediately after account creation, `UserService().updateUsername(username: username)` calls `currentUser!.updateDisplayName(username)` to bind the chosen username to the Firebase user profile.
   - **DummyJSON User Schema & Local Profile Persistence**:
     - Following the `https://dummyjson.com/users` schema, `UserService().registerDummyJsonUser(...)` posts the extended user attributes (`firstName`, `lastName`, `age`, `phone`, `username`, `email`, `password`) to `$host/users/add`.
     - `UserService().saveUserData(...)` persists the unified user profile and `loginType: 'firebase'` into `SharedPreferences` (including an email-indexed profile cache `firebase_profile_<email>`), then navigates to `/home`.

2. **Sign In Workflow (`SigninScreen` -> `UserService`)**:
   - **DummyJSON Sign In (`LoginType.dummyJson`)**:
     - The user enters their `username` (e.g., `emilys`) and `password` (e.g., `emilyspass`).
     - `UserService().loginUser(username, password)` sends an HTTP `POST` request to `https://dummyjson.com/auth/login` with JSON payload `{'username': username, 'password': password, 'expiresInMins': 60}`.
     - Upon receiving `200 OK`, it enriches the user data by querying `GET https://dummyjson.com/users/{id}` (retrieving `age` and `phone`/`contactNo`), sets `loginType = 'dummyJson'`, stores the `accessToken`, `refreshToken`, and profile fields in `SharedPreferences` via `saveUserData()`, and navigates to `/home`.
   - **Firebase Auth Sign In (`LoginType.firebase`)**:
     - The user enters their `emailAddress` and `password`.
     - `UserService().signIn(email: email, password: password)` calls `FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)`.
     - The Firebase SDK authenticates the user, refreshes the ID token automatically, merges the live `FirebaseAuth.instance.currentUser` properties (`uid`, `email`, `displayName`) with the stored profile fields (`firstName`, `lastName`, `age`, `contactNo`), saves `loginType = 'firebase'` in `SharedPreferences`, and redirects to `/home`.

3. **Session Persistence, Profile Management & Sign Out (`SplashScreen`, `ProfileScreen`, `SettingsScreen`)**:
   - On app startup (`SplashScreen`), `UserService().isLoggedIn()` checks whether an active `FirebaseAuth.instance.currentUser` or saved token exists in `SharedPreferences`, automatically routing authenticated users to `/home` or unauthenticated users to `/signin`.
   - On `ProfileScreen`, `UserService().getUserData()` and `getLoginType()` dynamically render user details tailored to `LoginType` (`Firebase Auth` vs. `DummyJSON API`) and expose interactive dialogs for **Update Username** (`updateUsername`), **Change Password** (`resetPasswordFromCurrentPassword` with `EmailAuthProvider.credential` re-authentication), and **Delete Account** (`deleteAccount` with re-authentication).
   - Tapping **Log Out** in either `ProfileScreen` or `SettingsScreen` invokes `UserService().signOut()`, signing out of Firebase Auth, clearing session tokens in `SharedPreferences`, and redirecting to `/signin`.

---

#### 2. Main Idea of the `UserService` Implementation

The core idea behind `UserService` (`lib/services/user_service.dart`) is **Abstraction, Encapsulation, and Single Responsibility (Facade / Service Layer Pattern)**:

- **Decoupling UI from Authentication Providers**: Screens (`SigninScreen`, `SignupScreen`, `ProfileScreen`, `SettingsScreen`, `SplashScreen`) do not directly manipulate raw HTTP requests, JSON serialization, `SharedPreferences` keys, or low-level `FirebaseAuth` credentials. Instead, they call high-level semantic methods on `UserService` (`loginUser`, `signIn`, `createAccount`, `signOut`, `updateUsername`, `deleteAccount`, `resetPasswordFromCurrentPassword`, `getUserData`).
- **Unified User State Across Multiple Backends**: By funneling both DummyJSON REST responses and Firebase `UserCredential` states into a standardized `User` model (`lib/models/user.dart`) and `SharedPreferences` store with a `LoginType` discriminator, the presentation layer can seamlessly display and manage user data regardless of which authentication backend was used.
- **Reactive Notification**: Exposing `ValueNotifier<UserService> userService` and `Stream<User?> get authStateChanges` allows the application to reactively listen to authentication state transitions.

---

#### 3. Benefits of Firebase Implementation on the Current Flutter Application

Integrating **Firebase Authentication (`firebase_core` & `firebase_auth`)** brings major production-grade advantages compared to a mock REST endpoint like DummyJSON:

1. **Real Persistent Account Registration & Management**:
   - Unlike DummyJSON (which only simulates `POST /users/add` without persisting new accounts for subsequent logins), Firebase Auth genuinely creates, stores, and authenticates real user accounts in the cloud (`createAccount` -> `signIn`).
2. **Built-in Token Lifecycle & Automatic Refresh**:
   - The `FirebaseAuth` SDK automatically manages short-lived JWT ID tokens, secure local persistence on Android/iOS keystores, and background token refreshing without requiring manual refresh token polling.
3. **Sensitive Operation Security via Re-authentication**:
   - Operations such as changing passwords (`resetPasswordFromCurrentPassword`) and deleting accounts (`deleteAccount`) enforce cryptographic re-authentication (`EmailAuthProvider.credential` + `reauthenticateWithCredential`), protecting users against unauthorized session hijacking.
4. **Enterprise Security & Scalability**:
   - Passwords are never stored or handled in plain text; Firebase handles salted password hashing, rate-limiting against brute-force attacks, and integrates directly with Firebase Security Rules across the Firebase ecosystem.

---

### Implemented Enhancements (Lab Activity 5)

- **Enhancement 1: `UserService` Functions & Logout**:
  - Implemented `signIn`, `createAccount`, `signOut`, `updateUsername`, `deleteAccount`, and `resetPasswordFromCurrentPassword` in `lib/services/user_service.dart`.
  - Added Logout button in both `ProfileScreen` and `SettingsScreen` that clears session/tokens and redirects to `/signin`.
- **Enhancement 2: DummyJSON vs. Firebase Auth & `signup_screen.dart`**:
  - Integrated DummyJSON (`https://dummyjson.com/auth/login` & `/users`) alongside Firebase Auth SDK (`FirebaseAuth.instance`).
  - Created `lib/screens/signup_screen.dart` with validated fields for `fName`, `lName`, `age`, `contactNo`, `username`, `emailAddress`, and `password`.
- **Enhancement 3: Profile Screen & Settings Integration**:
  - Updated `lib/screens/profile_screen.dart` to fetch user data via `UserService().getUserData()`, display user details dynamically based on `LoginType`, and support **Update Username**, **Change Password**, and **Delete Account** modals.
  - Updated `lib/screens/settings_screen.dart` to include **Log Out** returning to `/signin`.
