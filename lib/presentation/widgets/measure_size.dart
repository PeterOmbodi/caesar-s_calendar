import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports the laid-out size of [child] after the frame, whenever it changes.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(final BuildContext context) => RenderMeasureSize(onChange);

  @override
  void updateRenderObject(final BuildContext context, final RenderMeasureSize renderObject) =>
      renderObject.onChange = onChange;
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final measured = size;
    if (measured == _reported) {
      return;
    }
    _reported = measured;
    WidgetsBinding.instance.addPostFrameCallback((final _) => onChange(measured));
  }
}
