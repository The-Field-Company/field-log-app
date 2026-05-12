# FieldLog Mobile

Flutter app for scientific field data collection. Works offline-first via PowerSync, syncing submissions when connectivity is restored.

## Prerequisites

- Flutter 3.38+
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
| `GLITCHTIP_DSN` | GlitchTip DSN for error tracking — obtain from GlitchTip after creating a project (`Projects → [project] → Project Settings → Client Keys (DSN)`) |

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

## Releases

Production APKs are built and signed automatically by GitHub Actions.

**To ship a new release:**
```bash
git tag v1.x.x
git push --tags
```
The signed APK appears on the [Releases page](https://github.com/The-Field-Company/field-log-poc/releases) within ~10 minutes.

**To build a test APK from any branch:**

Push any change to `mobile/` — GitHub Actions builds an APK and uploads it as an artifact under the [Actions tab](https://github.com/The-Field-Company/field-log-poc/actions). Artifacts expire after 30 days.

**To build locally:**
```bash
flutter build apk --release --dart-define-from-file=.env.json
```
Requires `android/key.properties` and `android/fieldlog-release.jks` — see the signing setup in `docs/deployment.md`.
