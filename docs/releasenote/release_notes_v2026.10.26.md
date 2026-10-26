### 💖 Support Our Work

As an open-source, community-funded project, we operate on a very limited budget. If LTvLauncher helps you daily, please consider supporting us on [GitHub Sponsors](https://github.com/sponsors/LeanBitLab) or [Open Collective](https://opencollective.com/leanbitlab-org). Sharing LTvLauncher with friends and family makes a huge difference!

## 🚀 What's New in v2026.10.26

### 📺 Screensaver Animations & Enhancements
- **DVD Bounce Animation**:
  - Classic DVD logo floating animation with smooth 60Hz wall collision detection and vibrant color cycling.
  - Reduced DVD bounce animation speed by ~45% for calm, non-distracting TV playback.
  - Eliminated the top-screen dead-zone (reduced 150px margin down to 48px and expanded vertical bounds) so the clock moves naturally across the entire screen including the upper area.
- **Animation Options & Navigation Fixes**:
  - Added Minimal Fade and Character Scatter animation styles.
  - Resolved remote focus and D-pad OK activation (`ButtonActivateIntent`) in screensaver settings so selections persist reliably.
  - Hardened native screensaver ambient mode dispatch for Android 14+ compatibility.

### ⚙️ Launcher Settings & Organization
- **Auto-Add Newly Installed Apps Toggle**:
  - Added a new toggle under Settings -> Interface -> Miscellaneous to control whether newly installed apps are automatically added to launcher sections.
  - When disabled, new apps remain safely stored in the database and accessible via Settings -> Applications without cluttering home screen categories.
- **Continue Watching Completion Filter**:
  - Added Hide Threshold setting (e.g. 90%, 95%) to automatically filter out completed and nearly completed movies and episodes from the home screen.

### 🚑 App Updates & Reliability
- **Hidden Apps Stay Hidden Across Updates (#158)**:
  - Fixed an issue where apps marked as hidden were unexpectedly restored to categories when updated in the background.
  - Consolidated package event handling to preserve custom banners, action intents, and custom category positions during background updates.

### 🌍 Localization & Translation
- **Slovenian Language Support**:
  - Added complete Slovenian (`sl`) localization, refined with native speaker feedback.
- **Complete Multi-Language Coverage**:
  - Localized all new settings and screensaver options across all 15 supported languages (Arabic, German, English, Spanish, French, Hindi, Italian, Japanese, Korean, Portuguese, Russian, Slovenian, Turkish, Ukrainian, Chinese).
- **Automated Translation Quality Assurance**:
  - Added automated translation completeness checker script, git hook, and unit test suite to guarantee 100% key parity across all language catalogs.

## 📦 Downloads (Choose Your Architecture)

| File | Target Devices | Architecture |
|:---|:---|:---|
| **`LTvLauncher-universal-release.apk`** | All Android TV & Fire TV devices (Universal) | Universal |
| **`LTvLauncher-arm64-v8a-release.apk`** | Chromecast with Google TV, Nvidia Shield, modern 64-bit Android TVs | 64-bit ARM (`arm64-v8a`) |
| **`LTvLauncher-armeabi-v7a-release.apk`** | Fire TV Stick (Lite, 4K, 4K Max), older smart TVs | 32-bit ARM (`armeabi-v7a`) |
