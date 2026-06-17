# Story Pilot (Scene Context)

Flutter web app for exploring movie/TV scene context: TMDB metadata, AI scene briefs, and natural-language Q&A.

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
   - **Story Pilot — Web**: Cloud Functions (production).
   - **Story Pilot — Web (emulator)**: local Functions emulator.
3. TMDB metadata is served by [story-pilot-server](../story-pilot-server/) (`tmdb` callable). Configure `TMDB_API_KEY` in the server `.env` file.

## Setup

```bash
flutter pub get
```

### Cloud Functions (TMDB + scene context + AI)

Title search, detail, and cast call the **`tmdb`** callable on [story-pilot-server](../story-pilot-server/). Movie detail pages call **`ensureTitlePlayback`** in the background; the scene screen polls **`getTitlePreprocessing`** until breakdown is ready, then **`getSceneContext`** and **`sceneAsk`** for Q&A. API keys never leave the backend.

For local development against the Functions emulator:

```bash
# Terminal 1 (story-pilot-server/)
firebase emulators:start --only functions,firestore,storage --project storypilot-35945

# Terminal 2 (story-pilot-app/)
flutter run -d chrome \
  --dart-define=USE_FUNCTIONS_EMULATOR=true
```

Set `TMDB_API_KEY`, `GEMINI_API_KEY`, and `OPENSUBTITLES_API_KEY` in `story-pilot-server/functions/.env.storypilot-35945` (see server README).

### Firebase Auth (email magic link)

Login is optional but required after 3 AI questions per day for anonymous users.

**Firebase Console setup (one-time):**

1. Open [Firebase Console](https://console.firebase.google.com/) → project `storypilot-35945` → **Authentication**.
2. Enable **Email/Password** provider and turn on **Email link (passwordless sign-in)**.
3. Under **Settings → Authorized domains**, add `localhost` (dev) and your production domain.
4. Magic links redirect to `{origin}/login` (handled automatically by the app).

No extra dart-defines are needed; web config is in `lib/firebase_options.dart`.

## Flow

1. Search title (via Cloud Functions → TMDB)
2. View detail + cast
3. Open scene → backend returns duration and scene metadata
4. Set timestamp → scene context + AI brief
5. Ask questions (Gemini via Cloud Functions)

## Tests

```bash
flutter test
```

## Build

```bash
flutter build web
```

## Deploy (Firebase Hosting)

Production URLs:

- https://storypilot-35945.web.app
- https://storypilot-35945.firebaseapp.com

Every push to `develop` runs [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml): tests → `flutter build web --release` → Firebase Hosting deploy to **live**.

Every PR to `develop` runs [`.github/workflows/firebase-preview.yml`](.github/workflows/firebase-preview.yml): tests → `flutter build web --release` → deploy to a temporary **Preview Channel** with ID `pr-<PR_NUMBER>`.

- Preview URLs are posted automatically as a PR comment by the Firebase action.
- The preview channel expires after `7d`.
- When a PR is closed, the workflow deletes its preview channel.

### GitHub Secrets (one-time)

In **Settings → Secrets and variables → Actions**, add:

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | Full JSON from Firebase Console → Project settings → Service accounts → Generate new private key |

Production web uses **Firebase Callable Functions** for TMDB metadata, scene context, and AI via [story-pilot-server](../story-pilot-server/). TMDB and other API keys live only on the server. For local dev against the emulator, add `--dart-define=USE_FUNCTIONS_EMULATOR=true` and run `firebase emulators:start --only functions,firestore,storage` in `story-pilot-server/`.

The service account needs at least **Firebase Hosting Admin** (or **Firebase Admin** for simplicity).

### Firebase Console (one-time)

1. **Hosting** — enabled automatically on first deploy.
2. **Authentication → Settings → Authorized domains** — add:
   - `storypilot-35945.web.app`
   - `storypilot-35945.firebaseapp.com`
3. Confirm **Email link (passwordless sign-in)** is enabled under Email/Password provider.

### Manual deploy (optional)

```bash
flutter build web --release

firebase deploy --only hosting
```

Requires [Firebase CLI](https://firebase.google.com/docs/cli) and `firebase login`.
