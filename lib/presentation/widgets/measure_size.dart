import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports the laid-out size of [child] after the frame, whenever it changes.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(final BuildContext context, final _RenderMeasureSize renderObject) =>
      renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

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
