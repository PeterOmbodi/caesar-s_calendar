---

## Caesar's Puzzle 

Caesar's Puzzle is a cross-platform puzzle game built with Flutter, where players assemble pieces on a board in a style reminiscent of Tetris or Tangram. The project supports Android, iOS, Windows, macOS, Linux, and Web.

---
You can try it **here**: [Live demo][demo]

[demo]: https://peterombodi.github.io/caesar-s_calendar/

---

## Screenshots

<img width="778" height="578" alt="image" src="https://github.com/user-attachments/assets/141bc5b8-748e-4ba5-b483-02e0d3ea1bfa" />

<img width="778" height="578" alt="image" src="https://github.com/user-attachments/assets/f2960475-b98b-42e2-846a-459a3bebfea8" />

---

## Video

https://github.com/user-attachments/assets/91496d97-04af-49c6-9fc9-181f21d011be

---

## Features

- Intuitive drag-and-drop interface for placing puzzle pieces
- Rotate pieces with a single tap or click
- Flip pieces with a double tap/click
- Automatic puzzle solver powered by the Dancing Links algorithm
- Move history with undo and redo functionality
- Supports screen rotation and dynamic resizing
- Light and dark themes with manual override
- Multi-platform support: Android, iOS, Windows, macOS, Linux, Web
- Modern UI built with Flutter

---

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

### 3. Run code generation for libraries like freezed, injectable etc:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run code generation for internationalized strings:
```
flutter pub global run intl_utils:generate
```

### 5. Run on your desired platform

- **Android/iOS:**  
  Open the project in Android Studio or VS Code and run on an emulator/device.
- **Web:**  
  ```bash
  flutter run -d chrome
  ```
  Use a fixed port to ensure persistent `SharedPreferences` in development:
  ```bash
  flutter run -d chrome --web-port=5000
  ```

- **Windows/macOS/Linux:**  
  ```bash
  flutter run -d windows   # or macos, linux
  ```

---

## Project Structure

```
lib/
  application/         // Business logic (use cases)
  core/                // Models and utilities
  domain/              // Entities and algorithms
  infrastructure/      // Algorithm implementations and DTOs
  presentation/        // UI, BLoC, pages, widgets
```

---

## How to Play

**Goal:**
Place all puzzle pieces on the board so that _exactly two cells remain free_ - the ones corresponding to the current month and current day.
Every day the target cells change, creating a new unique challenge.
For even more variety, you can modify the layout by moving the predefined blocks.

1. **Drag & Drop** pieces onto the board.
2. **Rotate** pieces with a single tap/click.
3. **Flip** pieces with a double tap/click.
4. Use the **Solve** button to see the automatic solution.
5. Press **Hint** to reveal one move for a random piece.
6. Use **Undo** / **Redo** to revert or repeat your last actions.
7. Press **Reset** to return to the initial puzzle state.
8. Open **Settings** to:
    - switch theme
    - lock/unlock configuration (move predefined blocks to create your own layout)
    - enable/disable overlapping and snapping to grid
    - highlight pieces when using a hint
    - display solvability status
    - show the number of possible solutions for the current configuration and already placed pieces
    - track the time spent on solving the puzzle

---

## Automatic Solver

The project features a Dancing Links algorithm for solving the puzzle.  
You can find the implementation in `lib/domain/algorithms/dancing_links/`.

---

## Contributing

Pull requests and suggestions are welcome!  
Please open issues for bugs and feature ideas.

---

## License

[MIT License](LICENSE)

---

**Author:** Peter Ombodi

---

