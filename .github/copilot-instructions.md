# TimeFlow - AI Coding Agent Instructions

## Architecture Overview
TimeFlow is a Flutter time-tracking app using BLoC pattern for state management. Authentication is handled via `AuthBloc` and `AuthRepository`, currently simulating a backend with hardcoded users in `lib/repositories/auth_repository.dart`. Time punches are managed by `PontoService` and stored locally using `shared_preferences` as JSON.

Key components:
- **State Management**: BLoC (`lib/blocs/auth/`) for authentication logic
- **Data Layer**: `AuthRepository` for user operations, `PontoService` for time tracking
- **UI**: Pages in `lib/pages/`, themed with custom colors in `lib/theme/`
- **Persistence**: `shared_preferences` for user sessions and time records

## Data Flows
- **Authentication**: UI triggers `AuthEvent` → `AuthBloc` validates fields → calls `AuthRepository.login()` → saves session to `shared_preferences` → emits `LoginSuccess`
- **Time Tracking**: `PontoService.registrarPonto()` stores entries as `Map<String, Map<String, String>>` in `shared_preferences` under key `'registros'`
- **Session Management**: `AuthRepository.saveUserSession()` persists user data; `getUserSession()` retrieves it

## Developer Workflows
- **Setup**: `flutter pub get` to install dependencies
- **Run**: `flutter run` for development; specify device with `--device-id`
- **Test**: `flutter test` for unit tests (currently minimal)
- **Analyze**: `flutter analyze` for linting
- **Build**: `flutter build apk` for Android; `flutter build ios` for iOS
- **Debug**: Use Flutter DevTools for BLoC state inspection

## Project Conventions
- **Language**: UI strings and comments in Portuguese (e.g., error messages like "Email ou senha incorretos")
- **Validation**: Field validation occurs in `AuthBloc` handlers before repository calls (e.g., email format, password strength)
- **Error Handling**: Exceptions from repository are caught in BLoC, emitted as `AuthError` states
- **Theming**: Use `AppColors` class for consistent colors; `AppTextStyles` for typography
- **Navigation**: Routes defined in `main.dart`; use `BlocProvider` at app root for `AuthBloc`
- **Persistence Keys**: User session: `'isLoggedIn'`, `'userEmail'`, etc.; Time records: `'registros'`, balance: `'month_balance'`

## Patterns & Examples
- **BLoC Events**: Define events in `auth_event.dart` (e.g., `LoginRequested`), handle in `auth_bloc.dart` with async validation
- **Repository Methods**: Simulate API delays with `Future.delayed`; return `Map<String, dynamic>` for user data
- **Service Usage**: `PontoService.registrarPonto(context, 'entrada')` shows snackbar via `CustomSnackbar`
- **State Emission**: Always emit `_fieldsState` after errors to reset loading indicators
- **Date Handling**: Use `intl` package for formatting (e.g., `DateFormat('yyyy-MM-dd')`)

## Integration Points
- **External Deps**: `image_picker` for profile images (stored as file path in user data)
- **Platform**: Supports Android, iOS, Web, Windows via Flutter
- **Future Backend**: TODO comments indicate planned API integration (e.g., HTTP calls in `AuthRepository`)

Reference: [lib/repositories/auth_repository.dart](lib/repositories/auth_repository.dart), [lib/blocs/auth/auth_bloc.dart](lib/blocs/auth/auth_bloc.dart), [lib/services/ponto_service.dart](lib/services/ponto_service.dart)</content>
<parameter name="filePath">c:\Users\KauanPonte\TimeFlow\.github\copilot-instructions.md