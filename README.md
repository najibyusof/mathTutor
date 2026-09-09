# MathTutor

A Flutter app that lets students enter a math question — by typing, handwriting or scanning it — and returns a clear, step-by-step explanation with the final answer.

The backend is a Laravel REST API + MySQL (not part of this repository yet). The app talks to it over REST/JSON with bearer-token authentication.

## Status

| Phase | Scope | State |
| --- | --- | --- |
| 1 | Project foundation: Material 3 theme, routing, core widgets, config | Done |
| 2 | Main UI: splash, onboarding, home, question input | Done |
| 3 | Authentication: login, register, forgot password, logout, secure token storage | Done |
| 4 | Custom mathematical keyboard and expression editor | Done |
| 5 | Handwriting input | Planned |
| 6 | Camera / OCR input | Planned |
| 7 | Solver and step-by-step explanations | Planned |

The solver, handwriting recognition and camera capture are intentionally **not** implemented yet; those screens are placeholders. A mock API client keeps the app fully runnable without a backend.

## Tech stack

- Flutter / Dart, Material 3, responsive phone + tablet layouts
- Clean Architecture with feature-first organisation
- REST/JSON through a thin `ApiClient` abstraction (`package:http`)
- `flutter_secure_storage` for the bearer token (never SharedPreferences)
- State via `ChangeNotifier` / `ValueNotifier` + `InheritedNotifier` — no extra state-management dependency

## Project structure

```
lib/
  core/
    config/        # environment + API base URLs (--dart-define driven)
    constants/     # strings, app constants
    di/            # composition root
    errors/        # exceptions, failures, friendly messages
    mock/          # sample data used until the API is live
    network/       # ApiClient, mock client, endpoints, Result type
    storage/       # secure token storage
    theme/         # colors, typography, spacing, light/dark themes
    utils/         # validators, formatters, logger
    widgets/       # shared UI components
  features/
    auth/          # data / domain / presentation
    camera/
    handwriting/
    history/
    home/
    math_input/    # expression model, math keyboard, input widget
    onboarding/
    profile/
    solver/
    splash/
  models/          # shared DTOs
  routes/          # named routes + router
```

## Getting started

```bash
flutter pub get
flutter run
```

The app starts in **mock API mode**, so you can sign in with the seeded demo account:

```
student@mathtutor.app / password123
```

### Running against a real backend

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Supported defines: `APP_ENV` (`development` | `staging` | `production`), `API_BASE_URL`, `API_TIMEOUT_SECONDS`, `USE_MOCK_API`.

## Expected API endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/api/register` | Create account, returns bearer token + user |
| POST | `/api/login` | Sign in, returns bearer token + user |
| POST | `/api/forgot-password` | Send reset link |
| POST | `/api/logout` | Revoke the current token |
| GET | `/api/user` | Current user, used for the start-up session check |

## Quality checks

```bash
flutter analyze
flutter test
```

Both must be clean before a phase is considered done.
