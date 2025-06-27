
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/controls/syntax_error_indicator_render_object.dart';

class SyntaxErrorIndicator extends LeafRenderObjectWidget {
  final CodeLineEditingController controller;
  final CodeIndicatorValueNotifier notifier;
  final Drawing drawing;
  final double width;
  final void Function(Offset errorPosition, String errorMessage) onShowError;

  const SyntaxErrorIndicator({
    required this.controller,
    required this.notifier,
    required this.drawing,
    required this.width,
    required this.onShowError,
    super.key,
  });
  
  @override
  RenderObject createRenderObject(BuildContext context) => SyntaxErrorIndicatorRenderObject(
    controller: controller,
    notifier: notifier,
    width: width,
    drawing: drawing,
    onShowError: onShowError,
  );

  @override
  void updateRenderObject(BuildContext context, covariant SyntaxErrorIndicatorRenderObject renderObject) {
    renderObject
      ..controller = controller
      ..notifier = notifier
      ..width = width
      ..drawing = drawing
      ..onShowError = onShowError;
    super.updateRenderObject(context, renderObject);
  }
  
}