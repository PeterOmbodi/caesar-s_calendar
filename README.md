# Caesar's Puzzle

Caesar's Puzzle is a cross-platform Flutter puzzle game inspired by calendar puzzles, tangrams, and polyomino placement games. The goal is to place all pieces so that exactly two cells remain uncovered: the current month and the current day.

Live demo: [peterombodi.github.io/caesar-s_calendar](https://peterombodi.github.io/caesar-s_calendar/)

## Screenshots

| Main screen | Main screen - session started |
| --- | --- |
| <img width="360" alt="Main screen" src="https://github.com/user-attachments/assets/e03011a0-8f18-46a3-a637-e05742c5274e" /> | <img width="360" alt="Main screen - session started" src="https://github.com/user-attachments/assets/9451eff9-9ede-4ee8-bd2f-d8d8270d9c53" /> |

| History | Settings |
| --- | --- |
| <img width="360" alt="History" src="https://github.com/user-attachments/assets/dff6ec58-7be7-4bcd-b663-00d54eeec5ae" /> | <img width="360" alt="Settings" src="https://github.com/user-attachments/assets/7676f64b-082e-4576-bb9a-114c1115e60f" /> |

| Result | Custom configuration |
| --- | --- |
| <img width="360" alt="Result" src="https://github.com/user-attachments/assets/8d199a9f-4eef-4b6f-84f2-6bf105689e52" /> | <img width="360" alt="Custom configuration" src="https://github.com/user-attachments/assets/40850fd9-c0a1-48e2-80ae-6b00e1f26191" /> |

## Video

Gameplay

https://github.com/user-attachments/assets/5ee9eb2f-bec3-4dd3-becf-91759006862a

Solutions overview

https://github.com/user-attachments/assets/6a5798f9-dbef-4922-9eb7-72a822e51be6

## Features

- Daily calendar puzzle based on the selected date
- Drag-and-drop piece placement with support for touch and mouse
- Draw piece shapes directly on the calendar grid and commit matching groups into placements
- Persistent piece selection, with tap/click to select and a second tap/click to rotate
- Double tap/click on the selected piece to flip it
- Mouse wheel to rotate and right click to flip a piece, plus keyboard shortcuts for toolbar actions
- Platform-native controls, dialogs, and page transitions: Cupertino and Liquid Glass on Apple platforms, Material 3 on Android, with predictive back
- Automatic solving powered by a reusable exact-cover solver based on Dancing Links
- Hint system and full solution preview
- Undo and redo for move history
- Puzzle history with resume support for in-progress sessions
- Cross-device puzzle session sync for signed-in users on Android, iOS, and Web
- Calendar history view with per-day activity stats
- Statistics tab in the History screen with week/month/year filters and current year / all years scope, showing solve rate, hard-mode rate, best streak, hints used, time played, and average moves per solve
- Saved board layouts with a dedicated editor for repositioning fixed board blocks
- Achievements with calendar completion progress, personal milestones, and image sharing
- Contextual first-use tips and an animated how-to-play guide
- Optional move sounds and vibration on supported devices
- Theme switching: system, light, and dark
- Solving timer and solution indicators
- Localized UI with 26 language files in `lib/l10n`
- Support for Android, iOS, Windows, macOS, Linux, and Web

## How to Play

Goal:
Place all puzzle pieces on the board so that exactly two cells remain free: the cells for the selected month and day.

The current date can be changed through the history screen. Open the board layouts button in the header to choose, create, or edit a saved layout.

Controls:

1. Place pieces by dragging them from the tray onto the board, or by drawing their shape directly on free grid cells.
2. To draw a placement, drag across free grid cells to create a temporary group.
3. Double tap a valid drawn group to place the matching piece there.
4. Tap a free adjacent cell to add it to the group. Tap a cell in a drawn group to remove it.
5. Tap or click a piece to select it; tap or click it again to rotate it.
6. Double tap or double click the selected piece to flip it. You can also use the toolbar's `Rotate` and `Flip` actions.
7. Use the toolbar for `History`, `Hint`, `Undo`, and `Redo`. Its actions change when a piece is selected or a layout is being edited.
8. While viewing solutions, use the solution navigation arrows and close the preview to return to the game.
9. Open `More` for `All solutions`, `How to Play`, and `Start over`; wide screens show these actions in the side panel.
10. Open `How to Play` to view the in-app guide with animated gesture examples.
11. Open `History` to resume saved sessions or switch to another puzzle date.
12. Use `Hint` to reveal one valid move.
13. Open `Settings` from the header to change gameplay and UI behavior.

### Mouse and keyboard

With a mouse:

- drag a piece to move it
- scroll the wheel over a piece to rotate it
- right click a piece to flip it

Keyboard shortcuts (⌘ on Apple platforms, Ctrl elsewhere):

| Action | Shortcut |
| --- | --- |
| Rotate selected piece | `R` |
| Flip selected piece | `F` |
| Undo | `⌘Z` / `Ctrl+Z` |
| Redo | `⇧⌘Z` / `Ctrl+Shift+Z` |
| Hint | `?` |
| History | `H` |
| All solutions | `S` |
| Previous / next solution | `←` / `→` |
| Close solutions | `Esc` |
| Start over | `⌘⌫` / `Ctrl+Backspace` |

While editing a board layout: `⌘S` / `Ctrl+S` saves, `Esc` cancels, `⌘⌫` / `Ctrl+Backspace` resets. With a keyboard connected, `How to Play` lists the shortcuts.

Drawn groups use color feedback:

- grey means the group is too small to commit
- green means the group can be committed as a piece placement
- red means the group has enough cells but cannot be committed

Settings currently include:

- theme mode
- overlap prevention
- snap-to-grid on transform
- separate move colors
- solution indicator mode: hidden, solvability, or solution count
- solving timer visibility
- move sounds
- vibration on devices with haptic feedback

## Persistence

The app persists user settings and gameplay state locally:

- `hydrated_bloc` stores UI settings and active state
- `drift` stores puzzle history and session data
- Web builds use `sqlite3.wasm` and `drift_worker.js` for Drift persistence

## Cloud Sync

The project uses Firebase Auth and Firestore for cloud-backed data.

- Guest mode is local-only by default.
- Google sign-in and Apple sign-in enable a cloud-backed account.
- Cloud data is keyed by Firebase Auth `uid`.

The intended account and sync behavior is documented in [docs/account_sync_model.md](docs/account_sync_model.md).

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/PeterOmbodi/CaesarPuzzle.git
cd CaesarPuzzle
```

### 2. Install dependencies

The Flutter version is pinned in `.fvmrc`. With [fvm](https://fvm.app), run `fvm install` and prefix the commands below with `fvm`.

```bash
flutter pub get
```

### 3. Generate code

Generated files are not committed. Run this after cloning and after changing `freezed`, `json_serializable`, `injectable`, or Drift-related sources:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Generate localization files after cloning and when ARB files change

```bash
flutter pub global run intl_utils:generate
```

### 5. Run the app

- Android or iOS:

```bash
flutter run
```

- Web:

```bash
flutter run -d chrome
```

Release web builds use WebAssembly:

```bash
flutter build web --release --wasm
```

For Google sign-in on Web, set the OAuth Web Client ID in [web/index.html](web/index.html):

```bash
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

`--dart-define=GOOGLE_WEB_CLIENT_ID=...` is still supported as an optional override.

To keep `SharedPreferences` stable during local web development, use a fixed port:

```bash
flutter run -d chrome --web-port=5000
```

- Windows, macOS, or Linux:

```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## Web Notes

The web app depends on these runtime files in `web/`:

- `sqlite3.wasm`
- `drift_worker.js`

Rebuild the worker only when the worker entrypoint or the Drift web runtime changes:

```bash
dart compile js web/drift_worker.dart -o web/drift_worker.js
```

Database schema changes alone do not require rebuilding `drift_worker.js`.

## Project Structure

```text
lib/
  application/      business logic and use cases
  core/             shared constants, helpers, and foundational types
  domain/           puzzle entities and solving algorithms
  infrastructure/   persistence, repositories, and external integrations
  presentation/     UI, blocs/cubits, pages, themes, and widgets
  l10n/             ARB localization sources
  generated/        generated localization output
packages/
  exact_cover_dlx/  reusable exact-cover package based on Dancing Links
```

## Solver

The app now uses a reusable exact-cover package based on Dancing Links. The generic solver package lives under:

`packages/exact_cover_dlx/`

The Caesar's Puzzle mapping from board state to exact-cover constraints lives under:

`lib/domain/algorithms/exact_cover/`

The legacy in-app Dancing Links implementation is still kept under:

`lib/domain/algorithms/dancing_links/`

## Tech Stack

- Flutter
- BLoC / Cubit
- Hydrated BLoC
- Drift
- Freezed
- Injectable / GetIt
- Intl / ARB localization
  

## License

[MIT License](LICENSE)

Author: Peter Ombodi
