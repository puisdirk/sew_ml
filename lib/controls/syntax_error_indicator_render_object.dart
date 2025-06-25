
import 'package:flutter/rendering.dart';
import 'package:re_editor/re_editor.dart';

class SyntaxErrorIndicatorRenderObject extends RenderBox {

  CodeLineEditingController _controller;
  CodeIndicatorValueNotifier _notifier;
  double _width;
  int _allLineCount;

  SyntaxErrorIndicatorRenderObject({
    required CodeLineEditingController controller,
    required CodeIndicatorValueNotifier notifier,
    required double width,
  }) : 
    _controller = controller,
    _notifier = notifier,
    _width = width,
    _allLineCount = controller.lineCount;

    set controller(CodeLineEditingController value) {
    if (_controller == value) {
      return;
    }
    if (attached) {
      _controller.removeListener(markNeedsPaint);
    }
    _controller = value;
    if (attached) {
      _controller.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  set notifier(CodeIndicatorValueNotifier value) {
    if (_notifier == value) {
      return;
    }
    if (attached) {
      _notifier.removeListener(markNeedsPaint);
    }
    _notifier = value;
    if (attached) {
      _notifier.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  set width(double value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    _controller.addListener(_onCodeLineChanged);
    _notifier.addListener(markNeedsPaint);
    super.attach(owner);
  }

  @override
  void detach() {
    _controller.removeListener(_onCodeLineChanged);
    _notifier.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    assert(constraints.maxHeight > 0 && constraints.maxHeight != double.infinity, 
      'SyntaxErrorIndicator should have an explicit height');
    size = Size(_width, constraints.maxHeight);
  }

  void _onCodeLineChanged() {
    if (!attached) {
      return;
    }
    if (_allLineCount != _controller.lineCount) {
      _allLineCount = _controller.lineCount;
      markNeedsPaint();
    }
  }

}