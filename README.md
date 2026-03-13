# Caesar's Puzzle

Caesar's Puzzle is a cross-platform Flutter puzzle game inspired by calendar puzzles, tangrams, and polyomino placement games. The goal is to place all pieces so that exactly two cells remain uncovered: the current month and the current day.

Live demo: [peterombodi.github.io/caesar-s_calendar](https://peterombodi.github.io/caesar-s_calendar/)

## Screenshots

<img width="778" height="578" alt="Main puzzle screen" src="https://github.com/user-attachments/assets/141bc5b8-748e-4ba5-b483-02e0d3ea1bfa" />

<img width="778" height="578" alt="Settings and puzzle UI" src="https://github.com/user-attachments/assets/f2960475-b98b-42e2-846a-459a3bebfea8" />

## Video

https://github.com/user-attachments/assets/91496d97-04af-49c6-9fc9-181f21d011be

## Features

- Daily calendar puzzle based on the selected date
- Drag-and-drop piece placement with support for touch and mouse
- Single tap/click to rotate a piece
- Double tap/click to flip a piece
- Automatic solving powered by the Dancing Links algorithm
- Hint system and full solution preview
- Undo and redo for move history
- Puzzle history with resume support for in-progress sessions
- Calendar history view with per-day activity stats
- Configurable puzzle layout by unlocking fixed board blocks
- Theme switching: system, light, and dark
- Solving timer and solution indicators
- Localized UI with 26 language files in `lib/l10n`
- Support for Android, iOS, Windows, macOS, Linux, and Web

## How to Play

Goal:
Place all puzzle pieces on the board so that exactly two cells remain free: the cells for the selected month and day.

The current date can be changed through the history screen, and the board layout can also be customized by unlocking the predefined blocked cells.

Controls:

1. Drag pieces from the tray onto the board.
2. Tap or click a piece to rotate it.
3. Double tap or double click a piece to flip it.
4. Open `Info` to view the in-app how-to-play guide.
5. Open `History` to resume saved sessions or switch to another puzzle date.
6. Use `Solve` to display an automatic solution for the current layout.
7. Use `Hint` to reveal one valid move.
8. Use `Undo` and `Redo` to navigate move history.
9. Use `Reset` to restart the current puzzle.
10. Open `Settings` to change gameplay and UI behavior.

Settings currently include:

- theme mode
- unlock/lock board configuration
- automatic re-locking of board configuration
- overlap prevention
- snap-to-grid on transform
- separate move colors
- solution indicator mode: hidden, solvability, or solution count
- solving timer visibility

## Persistence

The app persists user settings and gameplay state locally:

- `hydrated_bloc` stores UI settings and active state
- `drift` stores puzzle history and session data
- Web builds use `sqlite3.wasm` and `drift_worker.js` for Drift persistence

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/PeterOmbodi/CaesarPuzzle.git
cd CaesarPuzzle
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate code

Run this after changing `freezed`, `json_serializable`, `injectable`, or Drift-related sources:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Generate localization files when ARB files change

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
```

## Solver

The automatic solver is based on Dancing Links. The core implementation lives under:

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
