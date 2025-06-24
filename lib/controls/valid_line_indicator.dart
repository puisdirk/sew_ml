


import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/controls/valid_line_indicator_render_object.dart';

class ValidLineIndicator extends LeafRenderObjectWidget {

  final CodeLineEditingController controller;
  final CodeIndicatorValueNotifier notifier;
  final double width;
  final int maxValidLineNumber;
  final void Function(int newMaxValidLineNumber) onSelection;

  const ValidLineIndicator({
    required this.controller,
    required this.notifier,
    required this.width,
    required this.maxValidLineNumber,
    required this.onSelection,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => ValidLineIndicatorRenderObject(
    controller: controller,
    notifier: notifier,
    width: width,
    maxValidLineNumber: maxValidLineNumber,
    onSelection: onSelection,
  );

  @override
  void updateRenderObject(BuildContext context, covariant ValidLineIndicatorRenderObject renderObject) {
    renderObject
      ..controller = controller
      ..notifier = notifier
      ..width = width
      ..maxValidLineNumber = maxValidLineNumber
      ..onSelection = onSelection;
    super.updateRenderObject(context, renderObject);
  }

}