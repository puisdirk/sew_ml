import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

class ValidLineIndicatorRenderObject extends RenderBox implements MouseTrackerAnnotation {

  CodeLineEditingController _controller;
  CodeIndicatorValueNotifier _notifier;
  double _width;
  int _maxValidLineNumber;
  void Function(int newMaxValidLineNumber) _onSelection;
  int _allLineCount;

  ValidLineIndicatorRenderObject({
    required CodeLineEditingController controller,
    required CodeIndicatorValueNotifier notifier,
    required double width,
    required int maxValidLineNumber,
    required void Function(int newMaxValidLineNumber) onSelection,
  }) : 
    _controller = controller,
    _notifier = notifier,
    _width = width,
    _maxValidLineNumber = maxValidLineNumber,
    _onSelection = onSelection,
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

  set maxValidLineNumber(int value) {
    if (_maxValidLineNumber == value) {
      return;
    }
    _maxValidLineNumber = value;
    markNeedsPaint();
  }

  set onSelection(void Function(int newMaxValidLineNumber) value) {
    if (_onSelection == value) {
      return;
    }
    _onSelection = value;
    markNeedsPaint();
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  MouseCursor get cursor => SystemMouseCursors.click;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final Offset position = globalToLocal(event.position);
      final CodeLineRenderParagraph? paragraph = _findParagraphByPosition(position);
      if (paragraph != null) {
        if (paragraph.index >= (_allLineCount - 1)) {
          _onSelection(-1);
        } else {
          _onSelection(paragraph.index + 1);
        }
      }
    }
    super.handleEvent(event, entry);
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
      'ValueLineIndicator should have an explicit height');
    size = Size(_width, constraints.maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final CodeIndicatorValue? value = _notifier.value;
    if (value == null || value.paragraphs.isEmpty) {
      // line offsets are not yet determined
      return;
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height));

    Paint redPaint = Paint()..color = Colors.red.withAlpha(100)..style = PaintingStyle.fill;
    Paint greenPaint = Paint()..color = Colors.green.withAlpha(100)..style = PaintingStyle.fill;

    for (final CodeLineRenderParagraph paragraph in value.paragraphs) {
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy + paragraph.offset.dy, size.width, paragraph.height), 
        (_maxValidLineNumber == -1 || paragraph.index < _maxValidLineNumber) ? greenPaint : redPaint);
    }
    canvas.restore();
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

  CodeLineRenderParagraph? _findParagraphByPosition(Offset position) {
    final int? index = _notifier.value?.paragraphs.indexWhere((e) => position.dy > e.top
      && position.dy < e.bottom);
    if (index == null || index < 0) {
      return null;
    }
    return _notifier.value?.paragraphs[index];
  }

}