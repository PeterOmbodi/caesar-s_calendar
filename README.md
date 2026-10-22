# Caesar's Calendar

A daily calendar puzzle for Android, iOS, and the web. Place all pieces on the board so that only today's month and day stay uncovered.

[Get it on Google Play](https://play.google.com/store/apps/details?id=com.peter_ombodi.caesar_puzzle) · App Store — coming soon · [Play in the browser](https://peterombodi.github.io/caesar-s_calendar/)

<p align="center">
  <img alt="Caesar's Calendar on Android, iPhone and the web" src="https://github.com/user-attachments/assets/eb474a46-e203-4b88-bfcb-2e8449aa058c" width="860">
</p>

https://github.com/user-attachments/assets/d15a24e8-19d0-4503-9e96-90d2472d0844

<details>
<summary><b>More screenshots</b></summary>

| Main screen — iOS | Main screen — Android |
| --- | --- |
| <img width="300" alt="Main screen on iOS" src="https://github.com/user-attachments/assets/6c5cf149-74e5-4bfd-ba47-2a10741dd23a" /> | <img width="300" alt="Main screen on Android" src="https://github.com/user-attachments/assets/ee0d2d31-f880-46a4-b1d8-47f16584fb87" /> |

| Phone landscape | Web on desktop |
| --- | --- |
| <img width="420" alt="Phone in landscape" src="https://github.com/user-attachments/assets/2dc85c85-7e79-4742-b758-39250556594f" /> | <img width="420" alt="Web app in a desktop browser" src="https://github.com/user-attachments/assets/23f942d0-07d2-4f90-9e75-3cb5796d3126" /> |

| Dragging a piece | Drawing a piece |
| --- | --- |
| <img width="300" alt="Dragging a piece onto the board" src="https://github.com/user-attachments/assets/df1fd573-ca1d-420d-a319-5e9078655673" /> | <img width="300" alt="Drawing a piece on the board" src="https://github.com/user-attachments/assets/5d467eaf-d840-4bbd-92ad-26e8545fcb92" /> |

| History — iOS | History — Android |
| --- | --- |
| <img width="300" alt="History on iOS" src="https://github.com/user-attachments/assets/9b2808aa-c4a5-4943-8f8f-7f8939d41ebe" /> | <img width="300" alt="History on Android" src="https://github.com/user-attachments/assets/28bb4752-8c30-4e4f-bf53-362c59441308" /> |

| Settings — iOS | Settings — Android |
| --- | --- |
| <img width="300" alt="Settings on iOS" src="https://github.com/user-attachments/assets/7ade7798-3419-4718-ba28-6e1085485967" /> | <img width="300" alt="Settings on Android" src="https://github.com/user-attachments/assets/a329524a-3e17-4fef-b72d-8c9e803cea54" /> |

| Achievements | Custom board layout |
| --- | --- |
| <img width="300" alt="Achievements" src="https://github.com/user-attachments/assets/36403fad-c307-4e83-bbac-bdc2caca3c37" /> | <img width="300" alt="Custom board layout" src="https://github.com/user-attachments/assets/9bec82fd-07ba-430c-b09d-a028481a9a10" /> |

</details>

## Features

**Gameplay**
- A new puzzle for every date, with a solver that can tell whether the board is still solvable
- Drag pieces from the tray, or draw their shape directly on the board
- Rotate and flip with taps, toolbar actions, the mouse, or the keyboard
- Hints, undo and redo, and a preview of all solutions
- Three difficulty levels, from a live solution count to no help at all
- Saved board layouts with an editor for the fixed blocks

**Progress**
- History with a yearly heatmap, resumable sessions, and a date picker shaped like the board
- Statistics by week, month, and year: solve rate, streaks, hints, time played
- Achievements with calendar progress, milestones, and a shareable image
- Optional Google or Apple sign-in to sync sessions across Android, iOS, and the web

**Platforms**
- Native look on each platform: Liquid Glass and Cupertino on iOS, Material 3 with predictive back on Android, a desktop layout in desktop browsers
- Phone, tablet, landscape, and wide-window layouts
- Light and dark themes, move sounds, haptics, basic VoiceOver support on the game screen
- 26 languages
- Web build in WebAssembly

## How to Play

Place all pieces so that exactly two cells stay free: the month and the day of the selected date. Pick another date in `History`, and another board layout with the layouts button in the header.

### Touch

1. Drag a piece from the tray onto the board.
2. Or draw it: drag across free cells, tap neighbouring cells to add or remove them, then double tap the group to place the matching piece. The group is grey while it is too small, green when a piece fits, and red when no piece matches.
3. Tap a piece to select it, tap again to rotate, double tap to flip. The toolbar has `Rotate` and `Flip` too.
4. Use the toolbar for `History`, `Hint`, `Undo`, and `Redo`; `More` has `All solutions`, `How to Play`, and `Start over`. Wide screens show these actions in a side panel.

### Mouse and keyboard

Drag a piece to move it, scroll over it to rotate, right click to flip.

Shortcuts use ⌘ on Apple platforms and Ctrl elsewhere. With a keyboard connected, `How to Play` lists them too.

| Action | Shortcut |
| --- | --- |
| Rotate / flip selected piece | `R` / `F` |
| Undo / redo | `⌘Z` / `⇧⌘Z` |
| Hint | `?` |
| History | `H` |
| All solutions | `S` |
| Previous / next solution | `←` / `→` |
| Close solutions | `Esc` |
| Start over | `⌘⌫` |
| Layout editor: save / cancel / reset | `⌘S` / `Esc` / `⌘⌫` |

## Development

### Getting started

The Flutter version is pinned in `.fvmrc`. With [fvm](https://fvm.app), run `fvm install` and prefix the commands with `fvm`.

```bash
git clone https://github.com/PeterOmbodi/caesar-s_calendar.git
cd caesar-s_calendar
flutter pub get
flutter pub global run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Generated code and localizations are not committed: rerun the last two commands after changing ARB files or `freezed`, `json_serializable`, `injectable`, or Drift sources.

The solver package has its own dependencies:

```bash
dart pub get --directory packages/exact_cover_dlx
```

### Web

```bash
flutter run -d chrome --web-port=5000         # fixed port keeps SharedPreferences between runs
flutter build web --release --wasm
```

- Google sign-in needs the OAuth Web Client ID in [web/index.html](web/index.html) (`google-signin-client_id`); `--dart-define=GOOGLE_WEB_CLIENT_ID=...` overrides it.
- Drift on the web uses `web/sqlite3.wasm` and `web/drift_worker.js`. Rebuild the worker only when its entrypoint or the Drift web runtime changes; schema changes do not need it:

```bash
dart compile js web/drift_worker.dart -o web/drift_worker.js
```

Every push to `master` runs analysis and tests and deploys the web build to GitHub Pages.

### Desktop

Windows, macOS, and Linux targets build with `flutter run -d windows|macos|linux`, but they are not released yet.

### Data and sync

- `hydrated_bloc` keeps settings and the active game; Drift stores history and sessions.
- Guests play locally. Google or Apple sign-in syncs sessions through Firebase Auth and Firestore, keyed by the user's `uid`. See [docs/account_sync_model.md](docs/account_sync_model.md).

### Project structure

```text
lib/
  application/      use cases and repository contracts
  core/             shared constants, models, and helpers
  domain/           puzzle entities and solving algorithms
  infrastructure/   persistence, sync, and external integrations
  presentation/     UI, blocs/cubits, pages, themes, and widgets
  l10n/             ARB localization sources
packages/
  exact_cover_dlx/  reusable exact-cover solver based on Dancing Links
```

The puzzle is solved as an exact-cover problem: `lib/domain/algorithms/exact_cover/` maps the board to constraints for the generic solver in `packages/exact_cover_dlx/`. The earlier in-app implementation is kept in `lib/domain/algorithms/dancing_links/`.

### Tech stack

Flutter · BLoC / Cubit · Hydrated BLoC · Drift · Freezed · Injectable / GetIt · Firebase · Intl / ARB · liquid_glass_widgets

## License

[MIT](LICENSE) · Peter Ombodi
