import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:petitparser/petitparser.dart';
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/maths_helper.dart';
import 'package:sew_ml/ast/measurement.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/parser_error.dart';
import 'package:sew_ml/ast/part.dart';
import 'package:sew_ml/ast/part_layout_placement.dart';
import 'package:sew_ml/ast/parts_layout.dart';
import 'package:sew_ml/ast/point.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';
import 'package:sew_ml/ast/relative_placement.dart';
import 'package:sew_ml/ast/sub_commands_group.dart';
import 'package:sew_ml/parser/sew_m_l_grammar_definition.dart';
import 'package:sew_ml/parser/sew_m_l_parser_definition.dart';

class Drawing {
  Map<String, Measurement> _measurements;

  List<ParserElement> _parserElements = [];
  
  List<ParserError> _errors = [];

  factory Drawing.parse(List<String> drawCommands, [Map<String, Measurement>? measurements]) {
    SewMLParserDefinition parserDefinition = SewMLParserDefinition(measurements);
    Parser<ParserElement> parser = parserDefinition.buildFrom(parserDefinition.command()).end();

    List<ParserElement> elements = _getElements(parser, drawCommands);

    return Drawing(measurements, elements);
  }

  factory Drawing.checkSyntax(List<String> drawCommands) {
    SewMLGrammarDefinition grammar = SewMLGrammarDefinition();
    Map<String, Parser> parsers = grammar.getNamedParsers();

    List<ParserError> errors = _checkSyntax(parsers, drawCommands);

    return Drawing.errors(null, errors);
  }

  static List<ParserError> _checkSyntax(Map<String, Parser> parsers, List<String> drawCommands) {
    List<ParserError> errors = [];

    int lineNumber = 1;
    for (String drawCommand in drawCommands) {
      String keyword = 'unknown';
      int end = drawCommand.indexOf(' ');
      if (end != -1) {
        keyword = drawCommand.substring(0, end);
      }

      Parser parser = parsers.containsKey(keyword) ? parsers[keyword]! : parsers['unknown']!;

      switch (parser.parse(drawCommand)) {
        case Success():
          break;
        case Failure(position: final position, message: final message):
          errors.add(ParserError(message: message, lineNumber: lineNumber, linePosition: position));
      }
    }

    return errors;
  }

  static List<ParserElement> _getElements(Parser<ParserElement> parser, List<String> drawCommands) {
    List<ParserElement> elements = [];
    
    for (String drawCommand in drawCommands) {
      switch(parser.parse(drawCommand)) {
        case Success(value: final value):
          if (value is SubCommandsGroup) {
            // We got back a list of commands, we recurse
            elements.addAll(_getElements(parser, value.subCommands));
          } else {
            // Got back a ParserElement
            elements.add(value);
          }
        case Failure(position: final position, message: final message):
          //throw ArgumentError('$message at position $position');
      }
    }
    return elements;
  }

  Drawing(Map<String, Measurement>? measurements, List<ParserElement> parserElements) : _measurements = measurements == null ? {} : Map.from(measurements), _parserElements = List.from(parserElements)..add(Point(label: 'origin', coordinate: Coordinate(0.0, 0.0)));
  Drawing.errors(Map<String, Measurement>? measurements, List<ParserError> errors) : _measurements = measurements == null ? {} : Map.from(measurements), _errors = List.from(errors);

  List<ParserElement> get elements => _parserElements;
  Map<String, Measurement> get measurements => _measurements;

  bool get hasError => _errors.isNotEmpty;
  List<ParserError> get errors => _errors;
  String get errorsSummary {
    String summary = '';
    for (ParserError error in _errors) {
      summary += error.toString();
    }
    return summary;
  }
  
  bool get hasLayout => _parserElements.any((el) => el is PartsLayout);
  PartsLayout get layout => _parserElements.firstWhere((el) => el is PartsLayout) as PartsLayout;

  Map<String, Path> getLayoutPaths({Offset midpoint = Offset.zero, bool applyFlips = true, bool applyRotation = true, applyRelativeConstraints = true}) {
    Map<String, Path> paths = {};

    if (hasLayout) {
      PartsLayout layout = this.layout;
      for (PartLayoutPlacement placement in layout.placements) {
        final Part part = elements.firstWhere((el) => el.label == placement.partName) as Part;
        Path partPath = Path();
        for (ParserElement partElement in part.elements) {
          if (partElement is Point) {
            Offset pointCenter = Offset(partElement.coordinate.x, -(partElement.coordinate.y)) + midpoint;
            partPath.addOval(Rect.fromCenter(center: pointCenter, width: 2, height: 2));
          } else if (partElement is Line) {
            Offset start = Offset(partElement.startPoint.x, -(partElement.startPoint.y)) + midpoint;
            Offset end = Offset(partElement.endPoint.x, -(partElement.endPoint.y)) + midpoint;
            partPath.moveTo(start.dx, start.dy);
            partPath.lineTo(end.dx, end.dy);
          } else if (partElement is QuadraticBezier) {
            Offset start = Offset(partElement.startPoint.x, -(partElement.startPoint.y)) + midpoint;
            Offset end = Offset(partElement.endPoint.x, -(partElement.endPoint.y)) + midpoint;
            Offset control = Offset(partElement.controlPoint.x, -(partElement.controlPoint.y)) + midpoint;
            partPath.moveTo(start.dx, start.dy);
            partPath.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
          }
        }

        Matrix4 transform = Matrix4.identity();
        Rect bounds = partPath.getBounds();

        if (applyFlips) {
          final double rad180 = MathsHelper.degreesToRadians(180);

          // Flip and rotate
          if (placement.flip == Flip.x || placement.flip == Flip.xy) {
            transform.translate(0.0, bounds.top + (bounds.height / 2));
            transform.rotateX(rad180);
            transform.translate(0.0, -(bounds.top + (bounds.height / 2)));
          }
          if (placement.flip == Flip.y || placement.flip == Flip.xy) {
            transform.translate(bounds.left + (bounds.width / 2));
            transform.rotateY(rad180);
            transform.translate(-(bounds.left + (bounds.width / 2)));
          }
        }

        if (applyRotation) {
          if (placement.orientationRad != 0.0) {
            transform.translate(bounds.left + (bounds.width / 2), bounds.top + (bounds.height / 2));
            transform.rotateZ(placement.orientationRad);
            transform.translate(-(bounds.left + (bounds.width / 2)), -(bounds.top + (bounds.height / 2)));
          }
        }
        
        paths[part.label] = transform == Matrix4.identity() ? partPath : partPath.transform(transform.storage);
        
      }

      if (applyRelativeConstraints) {
        for (RelativePlacement relativePlacement in layout.relativePlacements) {
          if (!paths.containsKey(relativePlacement.sourcePartLabel)) {
            throw ArgumentError('Attempt to use undefined part ${relativePlacement.sourcePartLabel}');
          }
          if (!paths.containsKey(relativePlacement.targetPartLabel)) {
            throw ArgumentError('Attempt to use undefined part ${relativePlacement.targetPartLabel}');
          }
          Path sourcePath = paths[relativePlacement.sourcePartLabel]!;
          Path targetPath = paths[relativePlacement.targetPartLabel]!;

          Rect sourcePathBounds = sourcePath.getBounds();
          Rect targetPathBounds = targetPath.getBounds();
          const double gap = 6.0;

          Matrix4 transform = Matrix4.identity();
          switch (relativePlacement.constraint) {
            case RelativeConstraint.above:
              transform.translate(0.0, (sourcePathBounds.top - targetPathBounds.top) - targetPathBounds.height - gap);
              break;
            case RelativeConstraint.below:
              transform.translate(0.0, sourcePathBounds.bottom - targetPathBounds.top + gap);
              break;
            case RelativeConstraint.right:
              transform.translate(sourcePathBounds.right - targetPathBounds.left + gap);
              break;
            case RelativeConstraint.left:
              transform.translate((sourcePathBounds.left - targetPathBounds.left) - targetPathBounds.width - gap);
              break;
            case RelativeConstraint.alignBottom:
              transform.translate(0.0, sourcePathBounds.bottom - targetPathBounds.top - targetPathBounds.height);
              break;
            case RelativeConstraint.alignTop:
              transform.translate(0.0, sourcePathBounds.top - targetPathBounds.top);
              break;
            case RelativeConstraint.alignLeft:
              transform.translate(sourcePathBounds.left - targetPathBounds.left);
              break;
            case RelativeConstraint.alignRight:
              transform.translate(sourcePathBounds.right - targetPathBounds.right);
              break;
            default:
          }

          if (!transform.isIdentity()) {
            paths[relativePlacement.targetPartLabel] = targetPath.transform(transform.storage);
          }
        }
      }
    }

    return paths;
  }

  Rect getLayoutBounds() {
    Map<String, Path> paths = getLayoutPaths();

    Path completePattern = Path();
    for (Path partPath in paths.values) {
      completePattern.addPath(partPath, Offset.zero);
    }

    return completePattern.getBounds();
  }

  @override
  int get hashCode => super.hashCode ^ measurements.hashCode ^ _parserElements.hashCode ^ _errors.hashCode;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Drawing &&
      runtimeType == other.runtimeType &&
      mapEquals(_measurements, other._measurements) &&
      listEquals(_parserElements, other._parserElements) &&
      _errors == other._errors;
}