import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum WindowClass {
  compact,
  medium,
  expanded;

  factory WindowClass.fromSize(final Size size) {
    if (size.height < compactHeightMax || size.width < mediumMinWidth) {
      return WindowClass.compact;
    }
    // Wide portrait windows (iPad Pro 13 in portrait) keep the stacked medium layout.
    if (size.width < expandedMinWidth || size.width <= size.height) {
      return WindowClass.medium;
    }
    return WindowClass.expanded;
  }

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 1024;
  // Lower windows are compact regardless of width, so a phone in landscape stays compact.
  static const double compactHeightMax = 480;
}

enum ChromeFamily {
  glass,
  material,
  web;

  factory ChromeFamily.forPlatform(final TargetPlatform platform, {required final bool isWeb}) {
    if (isWeb) {
      return ChromeFamily.web;
    }
    return switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => ChromeFamily.glass,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => ChromeFamily.material,
    };
  }

  static ChromeFamily? debugOverride;
}

enum BoardArrangement { stacked, sideBySide }

enum ToolbarPlacement { bottomBar, compactRail, labeledRail }

@immutable
class ScreenSpec {
  const ScreenSpec({required this.size, required this.family});

  factory ScreenSpec.of(final BuildContext context) {
    final platformFamily = ChromeFamily.forPlatform(Theme.of(context).platform, isWeb: kIsWeb);
    final family = kDebugMode ? ChromeFamily.debugOverride ?? platformFamily : platformFamily;
    return ScreenSpec(size: MediaQuery.sizeOf(context), family: family);
  }

  static const double dockedSettingsMinWidth = 1124;

  static const double compactMaxCell = 56;
  static const double mediumMaxCell = 72;
  static const double expandedMaxCell = 80;

  static const double compactTrayScale = 0.7;
  static const double tabletTrayScale = 0.75;

  final Size size;
  final ChromeFamily family;

  WindowClass get window => WindowClass.fromSize(size);

  bool get isLandscape => size.width > size.height;

  BoardArrangement get arrangement => isLandscape ? BoardArrangement.sideBySide : BoardArrangement.stacked;

  ToolbarPlacement get toolbar => switch (window) {
    WindowClass.expanded => ToolbarPlacement.labeledRail,
    WindowClass.compact when isLandscape => ToolbarPlacement.compactRail,
    _ => ToolbarPlacement.bottomBar,
  };

  double get maxCell => switch (window) {
    WindowClass.compact => compactMaxCell,
    WindowClass.medium => mediumMaxCell,
    WindowClass.expanded => expandedMaxCell,
  };

  double get trayScale => window == WindowClass.compact ? compactTrayScale : tabletTrayScale;

  bool get settingsDocked => size.width >= dockedSettingsMinWidth;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is ScreenSpec && other.size == size && other.family == family;

  @override
  int get hashCode => Object.hash(size, family);

  @override
  String toString() => 'ScreenSpec($size, $window, $family)';
}
