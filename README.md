---

## CaesarPuzzle

CaesarPuzzle is a cross-platform puzzle game built with Flutter, where players assemble pieces on a board in a style reminiscent of Tetris or Tangram. The project supports Android, iOS, Windows, macOS, Linux, and Web.

---

## Screenshots

<!--
//todo
-->

---

## Video

<!--
//todo
-->

---

## Features

- Intuitive drag-and-drop interface for placing puzzle pieces
- Rotate pieces with a single tap/click
- Flip pieces with a double tap/click
- Automatic puzzle solver (Dancing Links algorithm)
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

### 3. Run on your desired platform

- **Android/iOS:**  
  Open the project in Android Studio or VS Code and run on an emulator/device.
- **Web:**  
  ```bash
  flutter run -d chrome
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

1. Drag and drop pieces onto the board.
2. Rotate pieces with a single tap/click.
3. Flip pieces with a double tap/click.
4. Use the "Solve" button to see the automatic solution.

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

