
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/controls/syntax_error_indicator_render_object.dart';

class SyntaxErrorIndicator extends LeafRenderObjectWidget {
  final CodeLineEditingController controller;
  final CodeIndicatorValueNotifier notifier;
  final double width;

  const SyntaxErrorIndicator({
    required this.controller,
    required this.notifier,
    required this.width,
    super.key,
  });
  
  @override
  RenderObject createRenderObject(BuildContext context) => SyntaxErrorIndicatorRenderObject(
    controller: controller,
    notifier: notifier,
    width: width,
  );

  @override
  void updateRenderObject(BuildContext context, covariant SyntaxErrorIndicatorRenderObject renderObject) {
    renderObject
      ..controller = controller
      ..notifier = notifier
      ..width = width;
    super.updateRenderObject(context, renderObject);
  }
  
}