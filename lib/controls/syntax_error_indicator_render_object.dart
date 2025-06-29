
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/parser_error.dart';
import 'package:collection/collection.dart';

class SyntaxErrorIndicatorRenderObject extends RenderBox implements MouseTrackerAnnotation {

  CodeLineEditingController _controller;
  CodeIndicatorValueNotifier _notifier;
  double _width;
  Drawing _drawing;
  int _allLineCount;
  void Function(Offset errorPosition, String errorMessage) _onShowError;
  // remember which paragraph with an error we are moving over
  int _currentlyActiveErrorParagraph = -1;

  SyntaxErrorIndicatorRenderObject({
    required CodeLineEditingController controller,
    required CodeIndicatorValueNotifier notifier,
    required double width,
    required Drawing drawing,
    required void Function(Offset errorPosition, String errorMessage) onShowError,
  }) : 
    _controller = controller,
    _notifier = notifier,
    _width = width,
    _drawing = drawing,
    _allLineCount = controller.lineCount,
    _onShowError = onShowError;

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

  set drawing(Drawing value) {
    _drawing = value;
    markNeedsPaint();
  }

  set width(double value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  set onShowError(void Function(Offset errorPosition, String errorMessage) value) {
    if (_onShowError == value) {
      return;
    }
    _onShowError = value;
    markNeedsPaint();
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit  {
    if (_currentlyActiveErrorParagraph != -1) {
      _onShowError(Offset.zero, '');
      _currentlyActiveErrorParagraph = -1;
    }
    return null;
  }

  @override
  bool get validForMouseTracker => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  MouseCursor get cursor => SystemMouseCursors.click;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerHoverEvent) {
      final Offset position = globalToLocal(event.position);
      int visibleParagraphIndex = _findParagraphIndexByPosition(position);
      int? firstVisibleIndex = _notifier.value?.paragraphs.first.index;
      int codeLineIndex = visibleParagraphIndex + (firstVisibleIndex ?? 0);
      if (codeLineIndex != _currentlyActiveErrorParagraph) {
        _currentlyActiveErrorParagraph = codeLineIndex;
        if (_currentlyActiveErrorParagraph == -1) {
          _onShowError(Offset.zero, '');
        } else {
          ParserError? error = _drawing.errors.firstWhereOrNull((e) => e.lineNumber - 1 == codeLineIndex);
          if (error == null) {
            _onShowError(Offset.zero, '');
          } else {
            CodeLineRenderParagraph? paragraph = _notifier.value?.paragraphs[visibleParagraphIndex];
            if (paragraph != null) {
              _onShowError(localToGlobal(Offset(paragraph.offset.dx + _width, paragraph.offset.dy + paragraph.height)), error.message);
            }
          }
        }
      }
    }
    super.handleEvent(event, entry);
  }

  int _findParagraphIndexByPosition(Offset position) {
    final int? index = _notifier.value?.paragraphs.indexWhere((e) => position.dy > e.top && position.dy < e.bottom);
    return index ?? -1;
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

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final CodeIndicatorValue? value = _notifier.value;
    if (value == null || value.paragraphs.isEmpty) {
      // line offsets not yet determined
      return;
    }
    canvas.clipRect(Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height));

    Paint fillPaint = Paint()..color = Colors.red.withAlpha(50)..style = PaintingStyle.fill;
    Paint borderPaint = Paint()..color = Colors.red..style = PaintingStyle.stroke;

    for (CodeLineRenderParagraph paragraph in value.paragraphs) {
      ParserError? error = _drawing.errors.firstWhereOrNull((e) => e.lineNumber - 1 == paragraph.index);
      if (error != null) {
        canvas.drawCircle(Offset(offset.dx + (_width / 2) + 2, offset.dy + paragraph.offset.dy + (paragraph.height / 2) + 2), _width / 4, fillPaint);
        canvas.drawCircle(Offset(offset.dx + (_width / 2) + 2, offset.dy + paragraph.offset.dy + (paragraph.height / 2) + 2), _width / 4, borderPaint);
      }
    }

/*    for (ParserError error in _drawing.errors) {
      if (error.lineNumber < value.paragraphs.length) {
        CodeLineRenderParagraph paragraph = value.paragraphs[error.lineNumber - 1];
        canvas.drawCircle(Offset(offset.dx + (_width / 2) + 2, offset.dy + paragraph.offset.dy + (paragraph.height / 2) + 2), _width / 4, fillPaint);
        canvas.drawCircle(Offset(offset.dx + (_width / 2) + 2, offset.dy + paragraph.offset.dy + (paragraph.height / 2) + 2), _width / 4, borderPaint);
      }
    }
*/
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

}