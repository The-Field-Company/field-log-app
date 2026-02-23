# FieldLog Mobile

Flutter app for scientific field data collection. Works offline-first via PowerSync, syncing submissions when connectivity is restored.

## Prerequisites

- Flutter 3.19+
- Android SDK / Xcode (for iOS)
- Backend running locally (`make up` from the project root)

## Environment setup

Copy the example env file and fill in your values:

```bash
cp .env.json.example .env.json
```

`.env.json` is gitignored — never commit it.

| Key | Description |
|---|---|
| `SERVER_URL` | FieldLog API base URL |
| `POWERSYNC_URL` | PowerSync service URL |

## Running locally

```bash
flutter run --dart-define-from-file=.env.json
```

> In debug builds, URLs can also be overridden at runtime via the **Settings screen** (gear icon on the entry screen). Changes there are saved on-device and persist across restarts.

## Running on an Android device (USB)

1. Enable **USB debugging** on your device (Developer Options)
2. Plug in via USB and confirm the prompt on the device
3. Set up ADB reverse port forwarding so the device can reach your local backend:

```bash
adb reverse tcp:8000 tcp:8000
adb reverse tcp:8080 tcp:8080
```

4. Run the app:

```bash
flutter run --dart-define-from-file=.env.json -d <device-id>
```

To find your device ID: `flutter devices`

## Running on the Android emulator

The emulator reaches your host machine via `10.0.2.2`. The defaults in `.env.json.example` are already set for this — just copy and run:

```bash
cp .env.json.example .env.json
flutter run --dart-define-from-file=.env.json
```

## Running on iOS (simulator)

The iOS simulator reaches your host machine via `127.0.0.1`. Update `.env.json`:

```json
{
  "SERVER_URL": "http://127.0.0.1:8000",
  "POWERSYNC_URL": "http://127.0.0.1:8080"
}
```

Then run:

```bash
flutter run --dart-define-from-file=.env.json -d <simulator-id>
```

To list available simulators: `flutter devices`

## Building for release

```bash
# Android APK
flutter build apk --dart-define-from-file=.env.json

# iOS
flutter build ios --dart-define-from-file=.env.json
```
