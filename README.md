# Kubar Vastu — Flutter Vāstu Śāstra App

A production-grade Flutter app that brings five traditional Vāstu chakras to life using the device compass, camera, and floor plans.

## Features

- **Premium startup** - generated Android/iOS launcher icons, animated splash, and offline startup chime
- **High-precision compass** - adaptive circular low-pass filtering, native accuracy status, and calibration guidance
- **Discover** - cached in-app YouTube playback, searchable/paginated blogs, testimonials, and moderated feedback
- **Responsive Material 3** - premium navigation, persisted light/dark preference, shimmer/error/empty states

- 🧭 **Live compass** — smoothed magnetic-north heading, direction name, deity and element insight
- 🌀 **5 Chakras** rendered natively with `CustomPainter`:
  - **16 Directions** — smooth color-gradient ring
  - **32 Padas** — devta ring matching traditional Vastu texts
  - **45 Devta** — full Brahma Mandala (32 outer + 8 middle + 4 corner + Brahma)
  - **5 Elements (Panchamahabhuta)** — gradient ring with 4-point compass star
  - **Life Aspects** — 16 outer aspects + 5 elements + 3 doshas
- 📐 **Floor plan analysis** — pick a plan image, rotate/scale it, overlay any chakra with opacity control
- 📷 **Live AR compass** — rear camera view with rotating chakra overlay + heading HUD
- 🔒 **Lockable direction** to analyze a specific entry
- 💾 **Save readings** with timestamp

## Setup

### 1. Prerequisites
- Flutter **3.19+** (Dart 3.3+)
- Android Studio / Xcode
- A physical device (emulators usually lack a magnetometer)

### 2. Create the Flutter project shell

This archive contains only the app-specific files. Generate the platform scaffolding first:

```bash
flutter create divinewall --org com.divinewall --platforms android,ios
cd divinewall
```

Then **replace/merge** these files from this archive into the generated project:

| From archive | Into project |
|---|---|
| `pubspec.yaml` | `pubspec.yaml` |
| `lib/**/*` | `lib/` (replace entirely) |
| `android/app/src/main/AndroidManifest.xml` | same path (replace) |
| `android/app/build.gradle` | same path (merge min SDK 21) |
| `ios/Runner/Info.plist` | same path (replace) |

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

```bash
flutter run
```

### 5. Run the PHP + MySQL backend

The complete backend is in `backend-php/`. Copy `backend-php/.env.example` to `backend-php/.env` and configure MySQL. The database and all missing tables are created automatically when it starts:

```powershell
powershell -ExecutionPolicy Bypass -File backend-php/start-local.ps1
```

The backend runs on `http://localhost:4000`.

The app uses the production backend by default:

```text
https://admin.kubervastu.com/public
```

To override it during local development:

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:4000
```

Use `10.0.2.2` for an Android emulator. On a physical phone, use your computer's local network IP address instead of `localhost`.

### Dynamic content configuration

YouTube credentials are kept on the backend so the API key is never bundled in
Android, iOS, or web builds:

Set `YOUTUBE_API_KEY` and `YOUTUBE_CHANNEL_ID` in `backend-php/.env`. The YouTube Data API v3 must be
enabled for the key. The app requests `/api/content/videos`. Blogs and testimonials use MySQL through
`/api/blogs` and `/api/testimonials`. New feedback is stored as `pending` and
must be changed to `approved` through:

```text
PUT /api/admin/testimonials/:id/status
{ "status": "approved" }
```

Create a blog through `POST /api/admin/blogs`. App content is cached locally and
remains readable when the device is offline.

For a physical Android phone, build with the reachable backend address:

```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.10:4000
```

## Permissions required

**Android** (handled automatically via `permission_handler`):
- `CAMERA` — live Vāstu lens
- `ACCESS_FINE_LOCATION` — magnetometer calibration on Android
- `READ_MEDIA_IMAGES` — pick floor plan from gallery

**iOS** (pre-declared in `Info.plist`):
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMotionUsageDescription`

## Project structure

```
lib/
├── main.dart                       # Entry point, theme init
├── theme/
│   └── app_theme.dart              # Colors, fonts, glass decorations
├── models/
│   └── vastu_data.dart             # Direction meanings, devtas, chakra registry
├── services/
│   └── compass_service.dart        # Flutter Compass stream + smoothing
├── chakras/
│   ├── chakra_painters.dart        # Base painter + 16 Directions
│   └── chakra_variants.dart        # 32 Padas, 45 Devta, 5 Elements, Life Aspects
├── widgets/
│   └── shared_widgets.dart         # ChakraDisplay, chip selector, insight card
└── screens/
    ├── home_shell.dart             # Bottom nav + drawer + info modal
    ├── home_screen.dart            # Hero, preview, action grid
    ├── compass_screen.dart         # Live compass + chakra + insights
    ├── map_screen.dart             # Floor plan upload + overlay
    └── camera_screen.dart          # Live AR camera + chakra
```

## How each chakra works

All five chakras are drawn with `CustomPainter` — no images, no network calls. Colors, names, angles are all defined in code so they render crisply at any size.

Each painter accepts a `rotation` argument (device heading in degrees). The `CompassService` stream drives this rotation, so the chakra counter-rotates to keep true North always pointing to magnetic North.

The fixed red compass needle at the top of the compass screen is an overlay — it doesn't rotate. Only the chakra beneath it does, matching the behaviour of a physical Vāstu compass.

## Typography

- **Display:** Cormorant Garamond (loaded via `google_fonts`)
- **UI:** Inter
- **Sanskrit:** Noto Serif Devanagari (for "वास्तु शास्त्र")

Fonts auto-download on first launch and cache locally.

## Troubleshooting

### App crashes on startup
**Solution**: The most common cause is missing Gradle files or incorrect Android configuration.
1. Make sure you ran `flutter create divinewall` first to generate the base project
2. Verify `android/gradle.properties` and `android/settings.gradle` exist
3. Run `flutter clean && flutter pub get`
4. Try `flutter run --release` instead of debug mode

### "Compass not available" on real device
**Solution**: This is usually a permission issue.
1. Go to Android Settings → Apps → Kubar Vastu → Permissions
2. Enable "Location" permission (required for magnetometer access on Android)
3. Restart the app
4. If still not working, your device may lack a magnetometer sensor

### Camera preview black or crashes
**Solution**: 
1. Grant camera permission in Settings → Apps → Kubar Vastu → Permissions
2. The app uses `ResolutionPreset.medium` to reduce memory usage
3. On very old devices, try restarting the app if camera fails to initialize
4. Make sure no other app is using the camera

### Floor plan doesn't show or app crashes when uploading
**Solution**:
1. Grant "Photos" or "Storage" permission
2. The app checks if the file exists before rendering to prevent crashes
3. Try taking a photo with the camera instead of picking from gallery
4. Very large images (>10MB) may cause memory issues on low-end devices

### Chakras look blurry or render slowly
**Solution**: The app optimized rendering to 120 gradient segments (down from 180) for better performance on mid-range devices. If still slow:
1. Use the simpler "32 Padas" or "45 Devta" chakras instead of "16 Directions"
2. Reduce chakra size in the Map screen
3. Close background apps to free memory

### App crashes when rotating device
**Solution**: The app is locked to portrait mode. If you see this crash:
1. Make sure `android/app/src/main/AndroidManifest.xml` has `android:screenOrientation="portrait"` in the activity tag
2. Verify `main.dart` calls `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`

### Saved readings or map settings don't persist
**Solution**: This uses `SharedPreferences` which requires storage permission on some Android versions:
1. Grant storage permission in app settings
2. Check Android logs with `adb logcat | grep "Kubar Vastu"` for any "Failed to persist" errors
3. The app has built-in error handling so it won't crash, but data may not save

### General debugging
Run with verbose logging:
```bash
flutter run --verbose
```

Check Android system logs:
```bash
adb logcat | grep -E "flutter|Kubar Vastu"
```

Force clean rebuild:
```bash
flutter clean
rm -rf android/build
flutter pub get
flutter run --release
```
"# kubervastu" 
