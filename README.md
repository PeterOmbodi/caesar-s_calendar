---

## CaesarPuzzle

CaesarPuzzle is a cross-platform puzzle game built with Flutter, where players assemble pieces on a board in a style reminiscent of Tetris or Tangram. The project supports Android, iOS, Windows, macOS, Linux, and Web.

---

## Screenshots

![2025-07-03_15-34-27](https://github.com/user-attachments/assets/987cd75e-3ce1-4df9-9767-9e9e903ef748)

---

## Video

![2025-07-03_15-52-14](https://github.com/user-attachments/assets/ed4a544d-1f22-47e7-a033-cdf5a1d0c637)

![2025-07-03_18-53-20](https://github.com/user-attachments/assets/a071c559-6365-4aad-9987-26736ab00c0a)

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

