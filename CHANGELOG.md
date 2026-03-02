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
