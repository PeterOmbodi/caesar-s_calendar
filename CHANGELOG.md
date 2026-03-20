## 1.6.0+27
- add Google sign-in and Apple sign-in
- add cross-device puzzle session sync for signed-in users 
- add Firebase App Check support with web debug flow for localhost
- add account and sync management section in Settings:
  - public profile toggle
  - sync status
  - manual sync action
  - sign-out and delete-account actions

## 1.5.0+26
- add manual locale selection in settings panel
- disable hint for solved puzzle
 
## 1.4.13+25
- adjust how-to-play dialog spacing on iOS

## 1.4.12+24
- fix(android): Remove deprecated display cutout flag from Android launch themes
- refactor(history): HistoryScreen UI composition and reduce initial render overhead

## 1.4.11+23
- add History page transition
- fix solvability mark size
- Use applicableSolutions to determine solved status

## 1.4.10+22
- add 24 new locale bundles
  bg — Bulgarian (български)
  cs — Czech (čeština)
  da — Danish (dansk)
  de — German (Deutsch)
  es — Spanish (español)
  et — Estonian (eesti)
  fi — Finnish (suomi)
  fr — French (français)
  hr — Croatian (hrvatski)
  hu — Hungarian (magyar)
  is — Icelandic (íslenska)
  it — Italian (italiano)
  lt — Lithuanian (lietuvių)
  lv — Latvian (latviešu)
  mk — Macedonian (македонски)
  nb — Norwegian Bokmål (norsk bokmål)
  nl — Dutch (Nederlands)
  pl — Polish (polski)
  pt — Portuguese (português)
  ro — Romanian (română)
  sk — Slovak (slovenčina)
  sl — Slovenian (slovenščina)
  sq — Albanian (shqip)
  sv — Swedish (svenska)

## 1.4.9+21
- detect custom config by actual layout
- highlight custom sessions

## 1.4.8+20
- mass upgrade dependencies
- migrate drift to 2.32/sqlite3 v3, refresh web wasm assets

## 1.4.7+19
- expand "How to Play" content:
  - add guidance for drag shadow meaning (green/red)
  - add indicator explanations for possible solutions counter, timer, and solution index
  - enhance examples with `FlipFlapDisplay`-based visuals
- add new localization keys for the updated "How to Play" section in `en` and `uk`
- fix first info-cell flip label refresh on theme switch by including theme brightness in the widget key

## 1.4.6+18
- add invalid move feedback for config-piece transforms:
  - invalid `flip`/`rotate` is shown briefly, then rolled back automatically
  - selection is cleared after rollback
- improve config transform safety by blocking overlaps between `isConfigItem` pieces
- fix drag/drop timer behavior: preserve existing `firstMoveAt` on piece drop
- rework puzzle overlay layering to keep drag stable and avoid gesture loss while preserving info overlays
- add regression tests for:
  - invalid transform feedback + rollback
  - preserving `firstMoveAt` after drag/drop
  - config-piece transform overlap scenarios

## 1.4.5+17
- prevent overlap between `isConfigItem` pieces during `flip`/`rotate` by adding a cell-overlap guard
- fix `cfgCellOffset` anchors for config pieces
- update puzzle info/counter flap behavior:
  - switch first info cell rendering to `FlipFlapDisplay` widget mode
  - disable shortest-way number animation for solution count (`useShortestWay: false`)
- add regression tests for:
  - config-piece transform overlap prevention (`flip`/`rotate`)
  - hint-based solved-state transition
  - config-cell anchor offsets

## 1.4.4+16
- refactor `PuzzleBloc`: move drag/layout/actions/solutions/session logic into separate part files
- extract piece drag/drop and collision calculations into `PuzzlePieceMovementService`
- fix solved transition when last move is a hint: set status to `solvedByUser`, stop timer correctly, show solved dialog/statistics
- add tests for movement service, drag flow, and hint-based solved-state regression

## 1.4.3+15
- stop new `ConfettiView` particles after 5 seconds while allowing active particles to finish their animation

## 1.4.2+14
- limit `ConfettiView` display to 5 seconds after puzzle completion
- prevent confetti and solved dialog when opening an already solved session from history
- show solved dialog only once per session, even after temporary unsolve/re-solve actions
- resume timer automatically when restoring an unsolved session
- keep solved session history immutable after first solve (prevent `solved -> unsolved` rewrites)
- add solved dialog metadata for level and config, with localized labels (`solvedAlertLevelLabel`, `solvedAlertConfigLabel`)

## 1.4.1+13
- make floating panel open by default on wide layouts
- keep History button visible when floating panel is open on wide layouts
- unify History/Info button paddings with other floating panel controls across web/mobile
- add History action description to "How to Play" controls section

## 1.4.0+12
- add session difficulty tracking (easy/hard) in history and persistence
- migrate `puzzle_sessions` with `difficulty` and enum-based `status` in Drift
- sync difficulty with settings when restoring a session from history
- enrich history session cards with difficulty, config type (standard/custom), and used hints count
- extend history localization keys and sort ARB files alphabetically

## 1.3.1+11
- fix history date selector theme and remove incorrect year dependency

## 1.3.0+10
- add local Drift storage for puzzle history and session persistence
- add history screen with date heatmap, resume session, and start puzzle for selected date
- improve elapsed-time handling for restored and completed sessions
- fix DateSelector edge cases including February 29 and improve history app bar icon contrast

## 1.2.1+9
- update flip-flap based solvability marker and floating menu button
- bump `flutter_flip_flap` and related dependencies
- refactor puzzle logic by extracting layout and move-history services
- refactor domain/core dependencies and solver internals (remove flutter deps from domain/core, add placement validator)

## 1.2.0+8
- update flip-flap package to a newer version
- adapt code for breaking changes in flip-flap API
- update package naming related to flap components

## 1.1.2+7
- pause timer on inactive screen
- show spent time and used hints on solved puzzle
- add swipe gesture for floating panel and tweak padding on small screens
- add "how to play" view and localize strings
- animate floating panel and cleanup unused dependency

## 1.1.1+6
- switch to updated `flip_flap_display` dependency and bump related packages

## 1.1.1+5
- add timer service with unified display for timer/solution index
- track start solving timestamp and expose timer setting
- extract flip_flap into an independent package

## 1.1.1+4
- add split-flap indicator, clean up custom painter, update analyzer settings

## 1.1.0+3
- add hint for one-piece placement (random piece from applicable solution)
- combine found solutions with user moves and highlight hinted piece
- remove redundant hint use case and tweak hint button label

## 1.0.1+2
- update Android Gradle to 8.13 and Kotlin to 2.2.20
- fix pubspec description

## 1.0.1
- add solvability settings and indicators, reduce solver calls, optimize puzzle state
- add bloc observer and show app version

## 1.0.0+1
- initial release. Support flap units
