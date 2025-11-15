
import 'dart:math';

import 'package:petitparser/petitparser.dart';
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/maths_helper.dart';
import 'package:sew_ml/ast/measurement.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/part.dart';
import 'package:sew_ml/ast/part_layout_placement.dart';
import 'package:sew_ml/ast/parts_layout.dart';
import 'package:sew_ml/ast/point.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';
import 'package:sew_ml/ast/relative_placement.dart';
import 'package:sew_ml/ast/sub_commands_group.dart';
import 'package:sew_ml/controls/syntax_error_indicator_render_object.dart';
import 'package:sew_ml/parser/error_messages.dart';
import 'package:sew_ml/parser/sew_m_l_grammar_definition.dart';
import 'package:sew_ml/service/templates_service.dart';

//final _definition = SewMLParserDefinition();
//Parser<ParserElement> drawCommandParser() => _definition.buildFrom(_definition.start()).end();

/// Overrides to map to our AST objects
class SewMLParserDefinition extends SewMLGrammarDefinition {

  @override
  Map<String, Parser> getNamedParsers() {
    return {
      'point': buildFrom(point().end()),
      'line': buildFrom(line().end()),
      'curve': buildFrom(curveThroughTwoPoints().end()),
      'part': buildFrom(part().end()),
      'measurement': buildFrom(measurement().end()),
      'exec': buildFrom(exec().end()),
      'layout': buildFrom(layout().end()),
      'unknown': buildFrom(command().end()),
    };
  }

  int _currentLineNumber = 0;

  // The points, lines and curves thus far
  final Map<String, ParserElement> _parserElements = {
    'origin': Point(label: 'origin', coordinate: Coordinate(0.0, 0.0))};

  SewMLParserDefinition();

  // We get a list of ParserElement
  @override
  Parser<List<ParserElement>> start() {
    _currentLineNumber = 1;
    return super.start().castList();
  }

  // Increment line number
  @override
  Parser<ParserElement> command() => super.command().map((result) {
    _currentLineNumber = _currentLineNumber + 1;
    return result;
  });

  // We get ['part', <partlabel>, <list of labels>]
  @override
  Parser<Part> part([String message = 'Expected part definition']) {
    return super.part(message).map((result) {
      List<ParserElement> elements = [];
      for (dynamic label in result[2]) {
        if (label is String) {
          if (!_parserElements.containsKey(label)) {
            throw ArgumentError('$label is not defined');
          }
          final element = _parserElements[label];
          if (element is! ParserElement) {
            throw ArgumentError('$label is not defined');
          }
          elements.add(element);
        } else {
          elements.add(_findOrCreateLine(label));
        }
      }
      return Part(/*fromLineNumber: _currentLineNumber, */label: result[1], elements: elements);
    });
  }

  // We get [<length in mm>, <angle in radians>, <start coordinate>]. From this, we need to return a new Coordinate.
  @override
  Parser<Coordinate> relativeToPoint() => super.relativeToPoint().map((result) {
    double distance = result[0];
    double theta = result[1];
    Coordinate from = result[2];
    return MathsHelper.relativepointatangle(from, distance, theta);
  });

  /*
    E.g.
    point P_1 20cm south of origin
    line L_1 from origin to P_1
    point P_2 as adjacent west of P_1 with hypotenuse 60cm from origin
    line L_2 from P_1 to P_2
    line L_3 from origin to P_2
    point P_3 as adjacent east of P_1 with hypotenuse 30cm from origin
    line L_4 from origin to P_3
    line L_5 from P_1 to P_3
  */
  // I get ['as adjacent', <angle>, 'of', <pointlabel>, 'with hypotenuse', <hypotenuse>, <distancesource-coordinate>]
  @override
  Parser linetouchCoord() => super.linetouchCoord().map((result) {
    double angle = result[1];
    String pointLabel = result[3];
    double hypotenuse = result[5];
    Coordinate source = result[6];

    // get the opposite from pointlabel and source
    if (!_parserElements.containsKey(pointLabel)) {
      throw ArgumentError('Could not find point $pointLabel');
    }
    final refpoint = _parserElements[pointLabel];
    if (refpoint is! Point) {
      throw ArgumentError('$pointLabel is not a Point');
    }
    Line opposite = Line(label: 'helper', startPoint: source, endPoint: refpoint.coordinate);

    double adjacent = MathsHelper.adjacentFromHypotenuseAndOpposite(hypotenuse, opposite.lengthInMM());

    return MathsHelper.relativepointatangle(refpoint.coordinate, adjacent, angle);
  });

  // We get [length, <cm/mm/">]. We return the length in mm
  @override
  Parser mmLength() => super.mmLength().map((result) {
    if (result[0] is FailureParser) {
      // TODO: does this work or should I throw an ArgumentError?
      return failure('Expected a length');
    }
    double multiplier = 1.0;
    if (result[1] == 'cm') {
      multiplier = 10.0;
    } else if (result[1] == 'mm') {
      multiplier = 1.0;
    } else if (result[1] == '"') {
      multiplier = 25.4;
    }
    return multiplier * result[0];
  });

  // We get a direction string and return the corresponding angle in radians
  @override
  Parser<double> direction() => super.direction().map((result) {
    if (result == 'north' || result == 'up') {
      return pi / 2.0;  // 90.0;
    }
    if (result == 'east' || result == 'right') {
      return 2.0 * pi; // 0;
    }
    if (result == 'west' || result == 'left') {
      return pi; // 180.0;
    }
    if (result == 'south' || result == 'down') {
      return (pi * 3.0) / 2.0; // 270.0;
    }

    if (result == 'northeast') {
      return  MathsHelper.degreesToRadians(45.0);
    }
    if (result == 'northwest') {
      return  MathsHelper.degreesToRadians(135.0);
    }
    if (result == 'southeast') {
      return  MathsHelper.degreesToRadians(315.0);
    }
    if (result == 'southwest') {
      return  MathsHelper.degreesToRadians(225.0);
    }


    throw Exception('Unexpected input for direction: "$result"');
  });

  // We get ['at'|null, 'angle', <angle in degrees>, 'deg'] and return the angle in radians
  @override
  Parser angleInDegrees() {
    return super.angleInDegrees().map((result) { 
      return MathsHelper.degreesToRadians(result[2]);
    });
  }

  // We get ['at'|null, 'angle', <angle in radians>, 'rad'] and return the angle in radians
  @override
  Parser angleInRadians() => super.angleInRadians().map((result) {
    return result[2];
  });

  // We get ['from/of/to', <pointlabel>]
  @override
  Parser<Coordinate> coordinateOfPoint() {
    return super.coordinateOfPoint().map((result) {
      String pointLabel = result[1];
      if (!_parserElements.containsKey(pointLabel)) {
        throw ArgumentError('$noSuchPointError $pointLabel');
      }
      final p = _parserElements[pointLabel];
      if (p is! Point) {
        throw ArgumentError('$pointLabel is not a Point');
      }

      return p.coordinate;
    });
  }

  // we get ['measurement', <label>, <mmlength>]
  @override
  Parser measurement() => super.measurement().map((result) {
    String label = result[1];
    label = label.trim();
    if (result[2] is FailureParser) {
      throw ArgumentError(expectedMeasurementDefinitionError);
    }
    double length = result[2];

    if (_parserElements.containsKey(label)) {
      if (_parserElements[label] is Measurement) {
        // return the existing one
        return _parserElements[label]!;
      } else {
        throw ArgumentError('An element with label $label already exists');
      }
    }

    Measurement m = Measurement(label: label, valueInMMorRad: length);
    _parserElements[label] = m;
    return m;
  });

  // We get ['point', <point label>, <coord>]. We create a new Point.
  @override
  Parser<Point> point([String message = 'Expected point definition']) => super.point().map((result) {
    String label = result[1];
    if (_parserElements.containsKey(label)) {
      throw ArgumentError('$label $alreadyExistsError');
    }
    Coordinate coord = result[2];
    coord.setPrecision(2);
    final Point p = Point(
//      fromLineNumber: _currentLineNumber,
      label: label,
      coordinate: coord,
    );
    _parserElements.putIfAbsent(p.label, () => p);
    return p;
  });

  // we get ['line', <line label>, <coord1>, <coord2>]. We create a new Line
  @override
  Parser<Line> line() => super.line().map((result) {
    String label = result[1];
    if (_parserElements.containsKey(label)) {
      throw ArgumentError('$label $alreadyExistsError');
    }

    if (result[2][0] == 'as') {
      Line l = _findOrCreateLine(result[2][1], useLabel: label);
      _parserElements.putIfAbsent(label, () => l);
      return l;
    } else {
      final Coordinate coord1 = result[2][0];
      final Coordinate coord2 = result[2][1];
      Line l =  Line(/*fromLineNumber: _currentLineNumber, */label: label, startPoint: coord1, endPoint: coord2);
      _parserElements.putIfAbsent(l.label, () => l);
      return l;
    }
  });

  @override
  Parser<double> pMeasurement() => super.pMeasurement().map((result) {
    String measurementName = result;
    measurementName = measurementName.trim();
    if (!_parserElements.containsKey(measurementName)) {
      throw ArgumentError('$noSuchMeasurement $measurementName');
    }

    if (_parserElements[measurementName] is! Measurement) {
      throw ArgumentError('$measurementName is not a Measurement');
    }
    return (_parserElements[measurementName]! as Measurement).valueInMMorRad;
  });

  // E.g. point P_2 on intersection of L_1 and origin/P_1
  @override
  Parser lineintersectionCoord([String message = 'Expected lines intersection']) => super.lineintersectionCoord(message).map((result) {
    final firstLinelabel = result[1];
    final secondLinelabel = result[3];

    final Line firstLine = _findOrCreateLine(firstLinelabel);
    final Line secondLine = _findOrCreateLine(secondLinelabel);

    List<Coordinate> intersections = firstLine.intersections(secondLine);
    if (intersections.isEmpty) {
      return firstLine.startPoint;
    } else {
      return intersections.first;
    }
  });

  // Find an existing line or create a temp line from point names
  // linelabel: label of an exising line in form L_somename (string), or a list of startpointlabel, '/', endpointlabel 
  Line _findOrCreateLine(dynamic linelabel, {String? useLabel}) {

    final Line line;

    if (linelabel is String) {
      if (!_parserElements.containsKey(linelabel)) {
        throw ArgumentError.value(linelabel, 'Unknown line label', 'Unknown line label $linelabel');
      }

      final l = _parserElements[linelabel];
      if (l is! Line) {
        throw ArgumentError('Element $linelabel is not a line');
      }
      line = l;
    } else {
      String startPointLabel = linelabel[0];
      String endPointLabel = linelabel[2];

      if (!_parserElements.containsKey(startPointLabel)) {
        throw ArgumentError('Could not find point $startPointLabel');
      }
      final startPoint = _parserElements[startPointLabel];
      if (startPoint is! Point) {
        throw ArgumentError('$startPointLabel is not a Point');
      }

      if (!_parserElements.containsKey(endPointLabel)) {
        throw ArgumentError('Could not find point $endPointLabel');
      }
      final endPoint = _parserElements[endPointLabel];
      if (endPoint is! Point) {
        throw ArgumentError('$endPointLabel is not a Point');
      }

      line = Line(label: useLabel ?? 'temp', startPoint: startPoint.coordinate, endPoint: endPoint.coordinate);
    }

    return line;
  }

  /// point P_2 in middle of L_1|P_1/P_2
  /// point P_2 fraction 1/4 on L_2|P_1/P_2
  @override
  Parser relativetolineCoord([String message = 'Expected coordinate on line']) => super.relativetolineCoord(message).map((result) {

    int linelabelpos = 1;
    if (result[0] == 'fraction') {
      linelabelpos = 3;
    }

    final Line line = _findOrCreateLine(result[linelabelpos]);

    if (result[0] == 'fraction') {
      // result[1] is the fraction
      return line.coordAt(result[1]);
    } else {
      return line.middle();
    }
  });

  // We get [<linelabel>, <.functionname, e.g. .length>]
  // Currently only supports .length, but we could have .perpendicular or .parallel
  @override
  Parser linefunction() => super.linefunction().map((result) {
    String linelabel = result[0];
    String functionname = result[1];

    if (!_parserElements.containsKey(linelabel)) {
      throw ArgumentError.value(linelabel, 'Unknown line label', 'Unknown line label $linelabel');
    }

    final l = _parserElements[linelabel];
    if (l is! Line) {
      throw ArgumentError('Element $linelabel is not a line');
    }

    switch(functionname) {
      case '.length':
        return l.lengthInMM();

      default:
        throw ArgumentError('Unknown function $functionname');
    }
  });

  // We receive ['curve', <curvelabel>, <intensityfraction>, 'from', <pointlabel>, 'to', <pointlabel>, ['apex', <apexfraction>]]
  @override
  Parser<QuadraticBezier> curveThroughTwoPoints([String message = 'Expected a curve definition']) =>
    super.curveThroughTwoPoints().map((result) {
      String curvelabel = result[1];
      String direction = result[2]; // 'pos' or 'neg'
      if (result[3] is FailureParser) {
        throw ArgumentError('$expectedFractionError after the curve label (${result[3].message})');
      }
      double intensityfraction = result[3];
      String startPointLabel = result[5];
      String endPointLabel = result[7];

      if (_parserElements.containsKey(curvelabel)) {
        throw ArgumentError('$curvelabel $alreadyExistsError');
      }

      if (!_parserElements.containsKey(startPointLabel)) {
        throw ArgumentError('Could not find point $startPointLabel');
      }
      final startPoint = _parserElements[startPointLabel];
      if (startPoint is! Point) {
        throw ArgumentError('$startPointLabel is not a Point');
      }

      if (!_parserElements.containsKey(endPointLabel)) {
        throw ArgumentError('Could not find point $endPointLabel');
      }
      final endPoint = _parserElements[endPointLabel];
      if (endPoint is! Point) {
        throw ArgumentError('$endPointLabel is not a Point');
      }

      // We put a control point above the midpoint at a fraction of the line length.
      // E.g. points 0,0 and 10,0 with fraction 1/5 will put the control point at 5,2
      //            0
      //            |
      //  0--------------------0
      final double linelength = MathsHelper.distance(startPoint.coordinate, endPoint.coordinate);
      final double deviationfromline = linelength * intensityfraction;

      final Coordinate apexpoint;
      if (result[8] == null) {
        apexpoint = MathsHelper.middleOfLine(startPoint.coordinate, endPoint.coordinate);
      } else {
        Line l = _findOrCreateLine([startPoint.label, '/', endPoint.label]);
        apexpoint = l.coordAt(result[8][1]);
      }
      
      final angleOfLine = MathsHelper.angleOfLine(startPoint.coordinate, endPoint.coordinate);
      final perpendicularAngle = direction == 'pos' ? angleOfLine + (pi / 2.0) : angleOfLine - (pi / 2.0);
      final Coordinate controlPointCoordinate = MathsHelper.relativepointatangle(apexpoint, deviationfromline, perpendicularAngle);

      QuadraticBezier b = QuadraticBezier(
//        fromLineNumber: _currentLineNumber, 
        label: curvelabel, 
        startPoint: startPoint.coordinate, 
        endPoint: endPoint.coordinate, 
        controlPoint: controlPointCoordinate);
      _parserElements.putIfAbsent(b.label, () => b);
      return b;
    });

    //================== Functions/Samples ==============
    // We get exec <name>
    @override
    Parser<SubCommandsGroup> exec() => super.exec().map((result) {
      String label = result[1];

      // TODO: could do a lot with this. For now, it is just for samples

      if (TemplatesService().templateNames.contains(label)) {
        return TemplatesService().getTemplate(label);
      }

      throw ArgumentError('Don\'t know how to execute $label');
    });

    //================== Layouts =====================
    @override
    Parser<PartsLayout> layout() {
      return super.layout().map((result) {
        PartsLayout layout = _parserElements.putIfAbsent(PartsLayout.defaultLayoutLabel, () => PartsLayout()) as PartsLayout;
        String partLabel = result[1][0];
        String flipTypeOrPlacement = result[1][1];
        if (['below', 'above', 'right of', 'to the right of', 'left of', 'to the left of',
          'align right with', 'align left with', 'align top with', 'align bottom with'].contains(flipTypeOrPlacement)) {
          String sourcePartName = result[1][2];
          RelativeConstraint constraint;
          if (flipTypeOrPlacement == 'below') {
            constraint = RelativeConstraint.below;
          } else if (flipTypeOrPlacement == 'above') {
            constraint = RelativeConstraint.above;
          } else if (flipTypeOrPlacement.contains('left of')) {
            constraint = RelativeConstraint.left;
          } else if (flipTypeOrPlacement.contains('right of')) {
            constraint = RelativeConstraint.right;
          } else if (flipTypeOrPlacement == 'align right with') {
            constraint = RelativeConstraint.alignRight;
          } else if (flipTypeOrPlacement == 'align left with') {
            constraint = RelativeConstraint.alignLeft;
          } else if (flipTypeOrPlacement == 'align bottom with') {
            constraint = RelativeConstraint.alignBottom;
          } else if (flipTypeOrPlacement == 'align top with') {
            constraint = RelativeConstraint.alignTop;
          } else {
            throw ArgumentError('Unknown layout placement constraint $flipTypeOrPlacement');
          }
          layout.addConstraint(RelativePlacement(targetPartLabel: partLabel, sourcePartLabel: sourcePartName, constraint: constraint));
        }

        if (!layout.placements.any((p) => p.partName == partLabel)) {
          Flip flip = Flip.none;
          if (flipTypeOrPlacement == 'flipped over x') {
            flip = Flip.x;
          } else if (flipTypeOrPlacement == 'flipped over y') {
            flip = Flip.y;
          } else if (flipTypeOrPlacement == 'flipped over xy') {
            flip = Flip.xy;
          }

          String? rotation = result[1][2];
          double rotationRad = 0;
          if (rotation == 'rotated once') {
            rotationRad = MathsHelper.degreesToRadians(90);
          } else if (rotation == 'rotated twice') {
            rotationRad = MathsHelper.degreesToRadians(180);
          } else if (rotation == 'rotated thrice') {
            rotationRad = MathsHelper.degreesToRadians(270);
          }
          layout.addPart(PartLayoutPlacement(partName: partLabel, flip: flip, orientationRad: rotationRad));
        }

        return layout;
      }
    );
  }
  
}
