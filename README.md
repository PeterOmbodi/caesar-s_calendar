---

## CaesarPuzzle

CaesarPuzzle is a cross-platform puzzle game built with Flutter, where players assemble pieces on a board in a style reminiscent of Tetris or Tangram. The project supports Android, iOS, Windows, macOS, Linux, and Web.

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

