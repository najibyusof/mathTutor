# MathTutor

MathTutor is a Material 3 Flutter application for entering, recognizing and learning from mathematics questions. Students can type an expression, write it with touch/stylus input, or scan a question. The application presents a deterministic solution, optional tutor mode, history and backend-provided educational explanations.

The Laravel REST API and MySQL database are separate from this repository. The Flutter client never contains API or AI-provider secrets.

## Project Overview

Implemented application flows:

- Splash, onboarding and responsive home screens
- Keyboard expression editor with validation, cursor movement and undo/redo
- Handwriting canvas with stylus/touch support, eraser, export and recognition boundary
- Camera/gallery capture, crop, validation and upload compression
- Login, registration, password reset, logout and secure token storage
- Unified question recognition and review workflow
- Deterministic arithmetic and linear-equation solving
- Structured solution display and interactive tutor mode
- Optional backend AI explanation boundary
- Paginated, searchable and filterable history
- Light/dark Material 3 themes and accessible shared UI states

Recognition, solving and AI explanation providers are replaceable. The deterministic solver remains responsible for mathematical calculation and validation; AI only explains structured solver output.

## Architecture

The project uses Clean Architecture with feature-first organization:

```text
UI / Screen
  -> Controller or ChangeNotifier
    -> Repository interface
      -> Data source / provider
        -> ApiClient
          -> Laravel REST API
```

Cross-cutting responsibilities:

- `ApiClient`: JSON encoding, bearer headers, timeout, safe GET retry and HTTP error mapping
- `TokenStorage`: Android Keystore/iOS Keychain through `flutter_secure_storage`
- `AppConfig`: compile-time environment configuration through `--dart-define`
- `AppDependencies`: composition root for production, staging, development and mock providers
- `Failure` types: domain-safe errors converted to user-friendly messages
- `AppLogger`: development diagnostics with credential/token redaction; disabled in production

## Folder Structure

```text
lib/
  app.dart                         # root widget and dependency scopes
  main.dart                        # production entry point
  core/
    config/                        # environment and API configuration
    constants/                     # app strings and constants
    di/                            # dependency composition and scopes
    errors/                        # exceptions, failures and messages
    mock/                          # local sample data
    network/                       # ApiClient, endpoints, Result and mock API
    storage/                       # secure token storage
    theme/                         # Material 3 colors, type and spacing
    utils/                         # logging, validation and formatting
    widgets/                       # reusable UI components
  features/
    ai_explanation/                # provider abstraction and AI controller
    auth/                          # auth data, domain and presentation
    camera/                        # image capture, processing and recognition
    handwriting/                   # vector canvas and recognition
    history/                       # paginated history screen
    home/                          # home experience
    math/                           # Laravel math repository and controller
    math_input/                    # expression model and keyboard
    onboarding/
    recognition/                   # unified recognition and review
    solver/                        # parser, solver, validation and solution UI
    tutor/                         # interactive deterministic tutor mode
    profile/
    splash/
  models/                          # shared DTO/domain models
  routes/                          # named routes and router
test/                              # unit, repository, API and widget tests
```

## Flutter Version

Verified development toolchain:

```text
Flutter 3.41.5 • Dart 3.11.3 • DevTools 2.54.2
```

Use the same or a newer compatible stable Flutter release. Android builds currently use Java 17 and Android compile SDK 37.

## Setup

Prerequisites:

- Flutter stable
- Dart SDK supplied by Flutter
- Android SDK 37 for Android builds
- Java 17 for Android Gradle builds
- Xcode and CocoaPods for iOS builds (macOS only)
- A running Laravel API for non-mock environments

Install dependencies:

```bash
flutter pub get
flutter analyze
flutter test
```

## Environment Configuration

Configuration is compile-time and uses `--dart-define`. No `.env` file or secret is bundled with the application.

Supported values:

- `APP_ENV`: `development`, `staging` or `production`
- `API_BASE_URL`: Laravel API root, normally ending in `/api`
- `API_TIMEOUT_SECONDS`: request timeout, default `30`
- `USE_MOCK_API`: `true` or `false`; forced off for production configuration

### Development

Android emulator, with the Laravel server running on the host machine:

```bash
flutter run -d emulator-5554 \
  --dart-define=APP_ENV=development \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For the fully offline UI/mock experience, omit the defines or set `USE_MOCK_API=true`.

### Staging

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://MathTutor.padat.net/api/v1
```

### Production

Production must use HTTPS. The app rejects a non-HTTPS production API URL:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://MathTutor.padat.net/api/v1
```

Never put API keys, signing passwords, AI credentials or user credentials in these arguments, source files or README examples.

## Running the Application

Mock mode:

```bash
flutter run
```

Android emulator:

```bash
flutter devices
flutter run -d <device-id>
```

The local mock service is intended for development only. It does not represent production authentication or solver behavior.

## Running Tests

```bash
flutter analyze
flutter test
```

Focused examples:

```bash
flutter test test/core/network/api_client_test.dart
flutter test test/features/solver
flutter test test/features/auth
flutter test test/features/history
```

## Building Android

Debug APK:

```bash
flutter build apk --debug
```

Production bundle:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://MathTutor.padat.net/api/v1
```

Before a real release, replace the current debug signing configuration in `android/app/build.gradle.kts` with a CI-provided release keystore. Do not commit `key.properties`, keystores or signing passwords.

## Building iOS

iOS builds require macOS, Xcode, CocoaPods, a valid Apple signing team and provisioning profile:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release \
  --dart-define=APP_ENV=production \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://MathTutor.padat.net/api/v1
```

Configure the bundle identifier, signing team, certificates, provisioning profile and App Store capabilities in Xcode. iOS cannot be built or signed on Windows.

## API Configuration

All paths below are relative to the base URL (`.../api/v1`). The base URL,
not each path, carries the version segment.

Authentication endpoints:

| Method | Path             | Purpose                             |
| ------ | ---------------- | ----------------------------------- |
| POST   | `/auth/login`    | Sign in and receive a bearer token  |
| POST   | `/auth/register` | Register and receive a bearer token |
| POST   | `/auth/logout`   | Revoke the current session          |
| GET    | `/auth/user`     | Restore the current session         |

Questions, recognition, solving and history endpoints:

| Method | Path                          | Purpose                                               |
| ------ | ----------------------------- | ----------------------------------------------------- |
| POST   | `/questions`                  | Create a question (required before solving)           |
| POST   | `/questions/{id}/solve`       | Solve an already-created question                     |
| POST   | `/recognition/image`          | Submit a photo for OCR (async, returns 202 + poll id) |
| POST   | `/recognition/handwriting`    | Submit a rendered canvas image (async, poll id)       |
| GET    | `/recognition/{id}`           | Poll recognition status until completed/failed        |
| POST   | `/solutions/{id}/explanation` | AI explanation for an already-solved, verified answer |
| POST   | `/solutions/{id}/hint`        | AI hint for an already-solved, verified answer        |
| GET    | `/history`                    | Paginated history list                                |
| GET    | `/history/{id}`               | Read one history item                                 |
| DELETE | `/history/{id}`               | Delete one history item                               |

The Laravel API must enforce authentication, ownership checks, request validation, rate limits, HTTPS and server-side secret management.

## Troubleshooting

### Android build reports Java compatibility errors

Use Java 17 and configure Flutter to use its JDK directory:

```bash
flutter config --jdk-dir <path-to-java-17>
flutter doctor -v
```

### `flutter_secure_storage` requires a newer Android SDK

Install Android SDK 37 and keep `compileSdk = 37` in `android/app/build.gradle.kts`.

### The Android emulator cannot reach Laravel

Use `10.0.2.2` instead of `localhost` from the Android emulator. For a physical device, use the host machine's LAN address and configure the development server accordingly.

### The app has stale Gradle/Kotlin caches

Stop other Flutter/Gradle builds, then run:

```bash
flutter clean
flutter pub get
flutter run
```

### iOS build fails on Windows

iOS compilation and signing require macOS with Xcode. The Flutter source can still be analyzed and tested on Windows.

### Production signing fails

Configure a release keystore in Android Studio/Gradle or a CI secret store. Configure Apple certificates, provisioning and signing team in Xcode. These credentials must remain outside the repository.

## Production Readiness Checklist

- [x] Feature-first Clean Architecture
- [x] Central API client and repository boundaries
- [x] Secure bearer-token storage
- [x] Production HTTPS enforcement
- [x] Central HTTP timeout, error mapping and safe GET retry
- [x] Redacted development logging
- [x] No API or AI secrets in Flutter source
- [x] In-memory image processing with upload-size limits
- [x] Light/dark themes and responsive constraints
- [x] Accessible loading, error, empty and interactive states
- [x] Unit, repository, API-client and widget coverage
- [x] `flutter analyze` clean
- [x] `flutter test` clean
- [ ] Configure Android release keystore and signing credentials
- [ ] Configure iOS Apple team, certificates and provisioning profiles
- [ ] Confirm production Laravel TLS, auth, authorization and rate limits
- [ ] Confirm production API response contracts against deployed Laravel version
- [ ] Set final production application identifiers and store metadata
- [ ] Perform manual QA on supported Android phones, iPhones and tablets
