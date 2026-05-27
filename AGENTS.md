# LTvLauncher Agent Guidelines

This document provides important guidelines, architectural decisions, and context for AI agents (like Jules) working on the LTvLauncher project. Read these instructions carefully before making modifications to ensure consistency, performance, and stability.

## Project Overview

- **Name:** LTvLauncher (a fork of FLauncher)
- **Language:** Dart / Flutter
- **Platform:** Android TV
- **Package Names:** `com.leanbitlab.ltvL` (and legacy `me.efesser.flauncher`)
- **Legacy Java Package:** Both `com.leanbitlab.ltvL` and `me.efesser.flauncher` packages exist under `android/app/src/main/java/` with nearly identical source files. When modifying Java files, **always apply the same changes to both packages** to keep them in sync.

## Architecture & State Management

- **State Management:** The project uses the `provider` package (`Selector`, `ChangeNotifierProvider`, `context.read`) for state management and dependency injection.
- **Service Logic:** Complex logic involving joining categories and applications, and visibility filtering, is handled in `AppsService._refreshState` rather than the database layer. Tests for these behaviors reside in `test/providers/apps_service_test.dart`.
- **Race Conditions:** To prevent race conditions in asynchronous `ChangeNotifier` methods that update state, use a sequence counter (e.g., `_callCount`) incremented at method entry and compare it to a local snapshot before calling `notifyListeners()`.
- **Localization:** Managed with `flutter gen-l10n` via `.arb` files in `lib/l10n/`. The generated `AppLocalizations` classes must be imported via `package:flutter_gen/gen_l10n/app_localizations.dart` (do not use relative paths).
- **Settings Service Optimization:** Cache SharedPreferences values in local fields initialized during construction. Setters must update both the local cache and SharedPreferences to avoid N+1 synchronous read overhead. Use a `Key` suffix for SharedPreferences string constants (e.g., `_themesKey`).
- **Backward Compatibility:** When renaming or refactoring settings features, preserve the underlying SharedPreferences string keys (e.g., `'wifi_usage_period'`) to maintain compatibility for existing users.
- **Cache Invalidation:** In `AppsService`, ensure cache invalidation methods are called not only when the primary collection (`_categoriesById`) changes, but also when mutable properties of individual items (e.g., `category.name`) are updated.

## Testing & Mocking

- **Test Framework:** Use `mockito` and `flutter_test`. Run the test suite with `flutter test` (do not use `dart test`).
- **Mock Generation:** Mocks are defined in `test/mocks.dart` using `@GenerateMocks`. To generate new mocks, append the target class to the array and run `flutter pub run build_runner build --delete-conflicting-outputs`.
- **Model Tests:** Unit tests for data models should be organized under `test/models/` mirroring `lib/models/`.
- **Database Testing:**
  - Instantiate the database with `FLauncherDatabase.inMemory()` to avoid side effects.
  - When testing Drift database operations with foreign keys, ensure parent records are inserted first (e.g., `database.persistApps()`).
- **Provider / UI Widget Testing:**
  - Wrap the test widget in a `MultiProvider` and `Directionality` (e.g., `textDirection: TextDirection.ltr`).
  - Provide default stubs for visual preference getters in mocked `SettingsService` (e.g., `accentColorHex`, `theme`, `appHighlightAnimationEnabled`) to prevent null/type errors.
  - For `intl` date formatting (like `DateTimeWidget`), call `await initializeDateFormatting('en_US');` in `setUpAll`.
- **FocusNode Geometry:** When testing FocusNode geometry or traversal (critical for Android TV), use `WidgetTester` with `Stack` and `Positioned` to explicitly lay out nodes, as they need to be attached to a rendered widget tree to have dimensions.
- **AppsService Testing:**
  - Wait for the service to signal completion by polling the `initialized` property (`while (!appsService.initialized) { await Future.delayed(...); }`).
  - Ensure `MockFLauncherChannel` is stubbed for `getApplicationIcon` and `getApplicationBanner` to avoid `MissingStubError`.
- **Asynchronous Interactions:** Use `await Future.delayed(Duration.zero);` to allow the microtask queue to clear before making assertions on unawaited asynchronous calls.
- **SharedPreferences & Channels:** Initialize test environments using `SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();` and mock channel calls via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`.
- **Test File Naming:** Avoid versioned suffixes like `_v2` in filenames; use descriptive names (e.g., `apps_service_batch_test.dart`).

## Performance & Optimization

- **File I/O:** Avoid synchronous file I/O (e.g., `File.existsSync`) on the main UI thread. Prefer `File.exists` and `await` the result to prevent jank.
- **Map Lookups:** Prefer a single lookup with a null check (`final val = map[key]; if (val != null)`) over `containsKey` followed by a forced unwrap (`map[key]!`).
- **Concurrency:** Use `package:pool` to manage concurrency limits for unawaited background tasks, particularly for intensive operations like fetching app icons and banners.
- **Database Operations (Drift):** Use the `batch` API for multiple insertions, or rely on existing custom batch methods (like `insertAppsCategories`) for efficient single-transaction operations. Bulk operations (e.g., `addAllToCategory`) prevent N+1 query patterns.
- **Migration Safety:** In `database.dart`, use precise version range guards (e.g., `from <= 1 && to >= 2`) and check column existence via `PRAGMA table_info` before running `DROP COLUMN` or schema changes. This prevents crashes on databases that already have partial migrations applied.
- **Logging:** Prefer `log` from `dart:developer` over `print`. Use the `name` parameter to provide class context (e.g., `name: 'NetworkService'`) and pass exceptions to the `error` parameter.
- **Image Rebuilding:** To force an `Image` widget to rebuild when a `FileImage` changes but its path remains the same, append a version counter or timestamp to its `Key` (e.g., `Key("background_$version")`).

## UI & Interactions

- **Painting Order:** In `ListView` or `GridView`, items are painted sequentially. To prevent scaled-up focused items (like app banners) from being visually cropped by siblings, cap the maximum scale factor relative to the item's `maxWidth` using `LayoutBuilder` so expansion stays within spacing gaps.
- **Keyboard Events:** When migrating from `onKey` to `onKeyEvent`, ensure `KeyRepeatEvent` is explicitly handled alongside `KeyDownEvent` to preserve continuous/long-press interactions.
- **Accessibility Settings:** A dedicated `AccessibilityPage` (route: `accessibility`) is available from the main settings panel. It displays the current default launcher status via `LauncherState.isDefaultLauncher` and provides a button to open the system home app picker. The status refreshes on page entry via `LauncherState.refresh()`.

## Platform / Android Specifics

- **Java Compatibility:** The Android project is configured with Java 21 compatibility (source and target).
- **URI Injection Prevention:** Validate `packageName` strings received from Flutter MethodChannels (e.g., regex `^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$`) before using them in `Uri.fromParts` to construct Intents.
- **NetworkStatsManager:** When querying `querySummaryForDevice`, ensure the `subscriberId` parameter is passed as `null` rather than an empty string `""`.
- **Backups:** Android backups are explicitly disabled via `android:allowBackup="false"` and removing `android:fullBackupContent` in `AndroidManifest.xml` to prevent unauthorized data extraction via adb backup.
- **Multi-Manifest:** The project follows a multi-manifest structure with source sets for `main`, `debug`, and `profile` located under `android/app/src/`.
- **Default Launcher Settings:** The `openDefaultLauncherSettings` method channel (in `FLauncherChannel`, handled in `MainActivity`) opens Android's home app picker. The Java implementation tries `Settings.ACTION_HOME_SETTINGS` first (Android TV), then `Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS`, falling back to main settings. The `isDefaultLauncher` method resolves `CATEGORY_HOME` intent and compares the package name.

## Build, Environment, and Tooling

- **Git & Environment Files:** The `.gitignore` can be updated to exclude auto-generated files that are not needed for builds (e.g., `drift_schemas/`, `test/generated_migrations/`, `test/mocks.mocks.dart`, dev tooling configs). Keep only source code, assets, build configs, and files needed for reproducible F-Droid/IzzyOnDroid builds.
- **Dependency Issues (Environment Constraints):**
  - Commands like `flutter pub get` or `flutter test` might unintentionally update `pubspec.lock` with newer/beta SDK constraints. Restore `pubspec.lock` (e.g., `git restore pubspec.lock`) before committing.
  - Constant evaluation errors (`FontWeight`) might occur when `google_fonts` >= 6.3.0. Pinning `google_fonts` to a lower version like `6.2.1` in `pubspec.yaml` can bypass this during test compilation.
  - The execution environment may encounter timeouts (>400s) on network-heavy commands (`flutter pub get`, `flutter test`, `flutter analyze`). Missing `.dart_tool/` triggers `pub get` automatically.
  - Use `dart analyze <file> | grep "<diagnostic_code>"` to quickly verify specific static analysis fixes without resolving all environment dependencies.
  - Standard Git network operations (e.g., `git fetch`) might timeout. Use `git restore` and manual re-application if necessary for merge conflicts.
- **Android Gradle:** To execute Android Gradle commands (`gradle test`), the `android/local.properties` file must define `sdk.dir` and `flutter.sdk` (`/opt/flutter` in this environment).
- **Releases & Fastlane:**
  - When updating `versionCode` in `pubspec.yaml`, rename the corresponding Fastlane changelog file in `fastlane/metadata/android/en-US/changelogs/` to match (e.g., `6101.txt`).
  - For Reproducible Builds (RB) on F-Droid / IzzyOnDroid, ensure release tags exactly match the commit where the `pubspec.yaml` version aligns with the published APK (e.g., `version: 3.2.2+6101`).
