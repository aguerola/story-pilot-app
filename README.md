# Story Pilot (Scene Context)

Flutter web app for exploring movie/TV scene context: TMDB metadata, OpenSubtitles, character detection, and natural-language Q&A.

## Architecture

```
Widget → BloC → Repository → Service → API
```

- **UI** organized by feature (`lib/ui/<feature>/`)
- **Domain** shared models (`lib/domain/models/`)
- **Data** repositories + services (`lib/data/`)

## Run in Cursor / VS Code

1. Install the **Dart** and **Flutter** extensions.
2. Open **Run and Debug** (`Cmd+Shift+D`) and pick a configuration from `.vscode/launch.json`:
   - **Story Pilot — Web (stub)**: Chrome, no API keys (Ask uses local stub).
   - **Story Pilot — Web (dev)**: reads `TMDB_API_KEY`, `OPENSUBTITLES_API_KEY`, `CORS_PROXY` from your environment.
   - **Story Pilot — Web (Firebase AI)**: same as dev + Firebase dart-defines for Gemini.
3. Export keys in `~/.zshrc` (see `.vscode/launch.local.json.example`).

## Setup

```bash
flutter pub get
```

### API keys (dart-define)

```bash
flutter run -d chrome \
  --dart-define=TMDB_API_KEY=your_tmdb_key \
  --dart-define=OPENSUBTITLES_API_KEY=your_opensubtitles_key
```

Optional CORS proxy for web development:

```bash
--dart-define=CORS_PROXY=https://corsproxy.io/?url=
```

### Firebase AI (optional, phase 5b)

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE_AI=true \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

Without `USE_FIREBASE_AI`, Ask uses the local stub (offline rules).

## Flow

1. Search title (TMDB)
2. View detail + cast
3. Download subtitles (OpenSubtitles)
4. Set timestamp → scene context + characters
5. Ask questions (stub or Gemini)

## Tests

```bash
flutter test
```

## Build

```bash
flutter build web
```
