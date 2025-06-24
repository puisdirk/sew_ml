
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/measurement.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/part.dart';
import 'package:sew_ml/ast/point.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';

class DrawingControl extends StatelessWidget {
  final List<String> commands;
  final int maxValidLineNumber;
  final Map<String, Measurement> _measurements = {};
  
  DrawingControl({
    required this.commands,
    required this.maxValidLineNumber,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    List<String> validCommands = List.from(commands);
    if (maxValidLineNumber != -1) {
      validCommands = validCommands.sublist(0, maxValidLineNumber);
    }
    Drawing drawing = Drawing.parse(validCommands, _measurements);

  /*
    // TODO: Could use following to check line per line if the grammar is correct, but still doesn't
    // give me proper error messages
    SewMLGrammarDefinition def = SewMLGrammarDefinition();
    Parser p = def.buildFrom(def.command()).end();
    for (String command in commands) {
      Result accepted = p.parse('$command|');
      if (accepted is Failure) {
        print('line $command has an error');
      }
    }
  */

    return Center(
      child: Column(
        children: [
          CustomPaint(
            size: Size((screenSize.width / 2) * 0.9, (screenSize.height / 2) * 0.9),
            painter: DrawingPainter(drawing: drawing),
          ),
          drawing.hasError ? Text('Position: ${drawing.errorPosition}: ${drawing.errorMessage}') : const Text('valid'),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {

  final Drawing drawing;

  DrawingPainter({
    required this.drawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset midpoint = Offset(size.width / 2.0, size.height / 2.0);

    Paint originPaint = Paint()
    ..color = Colors.red.shade600
    ..style = PaintingStyle.stroke;

    Paint pointsPaint = Paint()
    ..color = Colors.grey.shade600
    ..style = PaintingStyle.stroke;

    Paint linesPaint = Paint()
    ..color = Colors.grey.shade600
    ..style = PaintingStyle.stroke;

    Paint curvesPaint = Paint()
    ..color = Colors.grey.shade600
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

    Paint borderPaint = Paint()
    ..color = Colors.grey.shade400
    ..style = PaintingStyle.stroke;

    Paint partPaint = Paint()
    ..color = Colors.green.shade700
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromCenter(center: midpoint, width: size.width, height: size.height), borderPaint);

    double maxHalfHeight = 0;
    double maxHalfWidth = 0;

    List<ParserElement> elements = List.from(drawing.elements);
//    elements.sort((a, b) => a.fromLineNumber.compareTo(b.fromLineNumber));

    // First determine scale
    for (ParserElement el in elements) {
      if (el is Point) {
        if (el.coordinate.x.abs() > maxHalfWidth) {
          maxHalfWidth = el.coordinate.x.abs();
        }
        if (el.coordinate.y.abs() > maxHalfHeight) {
          maxHalfHeight = el.coordinate.y.abs();
        }
      }
    }
    Rect bounds = Rect.fromCenter(center: midpoint, width: maxHalfWidth * 2, height: maxHalfHeight * 2);
    bounds = bounds.inflate((bounds.longestSide * 10) / 100);
    double scale = 1;
    if (bounds.width >= bounds.height) {
      scale = size.width / bounds.width;
    } else {
      scale = size.height / bounds.height;
    }
    canvas.scale(scale);
    Size newSize = Size.copy(size);
    newSize /= scale;
    midpoint = Offset(newSize.width / 2, newSize.height / 2);

    // Prepare for text drawing
    var style = TextStyle(color: Colors.grey[400]);

    // Now draw
    for (ParserElement el in elements) {
      if (el is Point) {
        canvas.drawCircle(Offset(el.coordinate.x, -(el.coordinate.y)) + midpoint, 2, el.label == 'origin' ? originPaint : pointsPaint);

        // draw point label
        final ParagraphBuilder paragraphBuilder = ParagraphBuilder(
          ParagraphStyle(
            fontSize: 10,
            fontFamily: style.fontFamily,
            fontStyle: style.fontStyle,
            fontWeight: style.fontWeight,
            textAlign: TextAlign.justify,
          ),
        )
        ..pushStyle(style.getTextStyle())
        ..addText(el.label);

        final Paragraph paragraph = paragraphBuilder.build()
        ..layout(ParagraphConstraints(width: size.width));

        canvas.drawParagraph(paragraph, Offset(el.coordinate.x, -(el.coordinate.y)) + midpoint);
      }
      if (el is Line) {
        canvas.drawLine(Offset(el.startPoint.x, -(el.startPoint.y)) + midpoint, Offset(el.endPoint.x, -(el.endPoint.y)) + midpoint, linesPaint);
      }
      if (el is QuadraticBezier) {
        Offset start = Offset(el.startPoint.x, -(el.startPoint.y)) + midpoint;
        Offset end = Offset(el.endPoint.x, -(el.endPoint.y)) + midpoint;
        Offset control = Offset(el.controlPoint.x, -(el.controlPoint.y)) + midpoint;
        Path p = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        canvas.drawPath(p, curvesPaint);
      }
      if (el is Part) {
        print('=================${el.label}================');
        for (ParserElement partElement in el.elements) {
          if (partElement is Point) {
            canvas.drawCircle(Offset(partElement.coordinate.x, -(partElement.coordinate.y)) + midpoint, 2, partPaint);
          } else if (partElement is Line) {
            canvas.drawLine(Offset(partElement.startPoint.x, -(partElement.startPoint.y)) + midpoint, Offset(partElement.endPoint.x, -(partElement.endPoint.y)) + midpoint, partPaint);
            print('canvas.drawLine(Offset(${partElement.startPoint.x}, -(${partElement.startPoint.y})), Offset(${partElement.endPoint.x}, -(${partElement.endPoint.y})), partPaint);');
          } else if (partElement is QuadraticBezier) {
            Offset start = Offset(partElement.startPoint.x, -(partElement.startPoint.y)) + midpoint;
            Offset end = Offset(partElement.endPoint.x, -(partElement.endPoint.y)) + midpoint;
            Offset control = Offset(partElement.controlPoint.x, -(partElement.controlPoint.y)) + midpoint;
            Path p = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
            canvas.drawPath(p, partPaint);
            print('Path p = Path()..moveTo(${start.dx}, ${start.dy})..quadraticBezierTo(${control.dx}, ${control.dy}, ${end.dx}, ${end.dy});');
            print('canvas.drawPath(p, partPaint);');
          }
        }
      }
    }
    
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return drawing != oldDelegate.drawing;
  }

}