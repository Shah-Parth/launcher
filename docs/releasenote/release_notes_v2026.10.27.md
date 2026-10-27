### 💖 Support Our Work

As an open-source, community-funded project, we operate on a very limited budget. If LTvLauncher helps you daily, please consider supporting us on [GitHub Sponsors](https://github.com/sponsors/LeanBitLab) or [Open Collective](https://opencollective.com/leanbitlab-org). Sharing LTvLauncher with friends and family makes a huge difference!

## 🚀 What's New in v2026.10.27

### 🔒 Reproducible Builds Restored (#160)
- **Deterministic Release Binaries**:
  - Removed non-deterministic Dart symbol obfuscation and symbol-splitting flags from the release workflow.
  - Releases are once again 100% byte-for-byte reproducible across independent build environments, ensuring compliance with F-Droid and IzzyOnDroid verification.

### 🛡️ Navigation & Framework Stability
- **Modernized Back Navigation (`PopScope`)**:
  - Migrated from legacy `WillPopScope` to modern `PopScope` and `onPopInvokedWithResult` across settings panels and dialogs.
  - Improves back navigation responsiveness and supports Android 14+ predictive back gestures cleanly without stack race conditions.
- **Flutter Framework API Modernization**:
  - Updated all `MaterialStateProperty` and `MaterialState` instances to the unified `WidgetStateProperty` / `WidgetState` APIs.
  - Cleaned deprecated theme attributes (such as `colorScheme.background`) to eliminate all framework analyzer warnings.
  - Verified full test suite (328 tests passing) with clean analyzer reports.

## 📦 Downloads (Choose Your Architecture)

| File | Target Devices | Architecture |
|:---|:---|:---|
| **`LTvLauncher-universal-release.apk`** | All Android TV & Fire TV devices (Universal) | Universal |
| **`LTvLauncher-arm64-v8a-release.apk`** | Chromecast with Google TV, Nvidia Shield, modern 64-bit Android TVs | 64-bit ARM (`arm64-v8a`) |
| **`LTvLauncher-armeabi-v7a-release.apk`** | Fire TV Stick (Lite, 4K, 4K Max), older smart TVs | 32-bit ARM (`armeabi-v7a`) |
