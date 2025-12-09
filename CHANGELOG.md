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
