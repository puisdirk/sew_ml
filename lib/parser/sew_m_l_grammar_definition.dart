
import 'dart:math';

import 'package:petitparser/petitparser.dart';
import 'package:sew_ml/ast/comment.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/parser/error_messages.dart';

/// Parses one line of sewMl
class SewMLGrammarDefinition extends GrammarDefinition {

  Map<String, Parser> getNamedParsers() {
    return {
      'point': buildFrom(point().end()),
      'line': buildFrom(line().end()),
      'curve': buildFrom(curve().end()),
      'part': buildFrom(part().end()),
      'measurement': buildFrom(measurement().end()),
      'exec': buildFrom(exec().end()),
      'layout': buildFrom(layout().end()),
      'unknown': buildFrom(command().end()),
    };
  }

  @override
  Parser<List> start() => (ref0(command).star() & string('.')).pick(0).castList();
  
  Parser<ParserElement> command() => 
    ([
        ref0(comment),
        ref0(exec),
        ref0(part), 
        ref0(measurement), 
        ref0(point), 
        ref0(line), 
        ref0(curve), 
        ref0(layout),
        failure('Expected a measurement, point, line, curve, part or layout definition'
      )].toChoiceParser(failureJoiner: selectFarthest)).cast();

  Parser<Comment> comment() => (string('#') & (word() | whitespace() | anyOf('_-')).plus()).flatten().map((res) => Comment(comment: res));

  Parser part([String message = 'Expected part definition']) =>
    string('part').trim() &
    ref0(partlabel) &
    (ref0(templinelabel) | ref0(pointlabel) | ref0(linelabel) | ref0(curvelabel)).starSeparated(char(',')).map((list) {
        return list.elements;
    });

  Parser partlabel() => (letter() | anyOf('_-') | digit()).plus().flatten().trim();
  
  Parser<String> pointlabel([String message = pointLabelError]) => 
    (
      string('origin') | 
      seq2((string('P_') | failure(pointLabelError)), (letter() | anyOf('_-') | digit()).plus())
    ).flatten().trim();

  // E.g. P_1/P_16
  Parser templinelabel([String message = 'Expected pointlabel/pointlabel']) =>
    (ref0(pointlabel) & string('/').trim() & ref0(pointlabel)).map((result) {
      return result;
    });

  // E.g. measurement M_scye-height 24cm
  Parser measurement() => 
    string('measurement').trim() & 
    (ref0(measurementLabel) | failure(measurementLabelError)) & 
    ref0(mmLength);

  // E.g. point P_1 ...
  Parser point([String message = expectedPointDefinitionError]) => 
    string('point').trim() & (ref0(pointlabel) | failure(pointLabelError)) & ref0(coordinatedefinition);

  Parser coordinatedefinition() => 
    [
      ref0(lineintersectionCoord), 
      ref0(linetouchCoord),
      ref0(relativetolineCoord),
      ref0(relativeToPoint),
    ].toChoiceParser(failureJoiner: selectFarthest);

  // E.g. point P_2 on intersection of L_1 and origin/P_1
  Parser lineintersectionCoord([String message = expectedLineIntersectionDefinitionError]) =>
    string('on intersection of').trim() &
    [ref0(linelabel), ref0(templinelabel)].toChoiceParser(failureJoiner: selectFarthest) &
    string('and').trim() &
    [ref0(linelabel), ref0(templinelabel)].toChoiceParser(failureJoiner: selectFarthest);

  Parser relativetolineCoord([String message = expectedCoordinateOnLineError]) => 
    [ref0(middleOfLine), ref0(fractionOfLine)].toChoiceParser(failureJoiner: selectFarthest);

  // E.g. point P_3 in middle of P_1/P_2
  Parser middleOfLine() =>
    (string('in middle of').trim() & [ref0(linelabel), ref0(templinelabel)].toChoiceParser(failureJoiner: selectFarthest));

  // E.g. point P_2 at fraction 1/3 on L_12
  Parser fractionOfLine() =>
    string('fraction').trim() & 
    ref0(fraction) & 
    ((string('on') | string('of')).trim() | failure('Expected \'on\' or \'of\'')) & 
    [ref0(linelabel), ref0(templinelabel)].toChoiceParser(failureJoiner: selectFarthest);

  Parser fraction([String message = expectedFractionError]) => 
    (number() & string('/').trim() & number()).map((result) {
      return result[0] / result[2];
    });

  // E.g. point P_4 as adjacent west of P_1 with hypotenuse 30cm from origin
  Parser linetouchCoord() => 
    string('as adjacent').trim() & 
    ref0(angle) & 
    string('of').trim() & 
    ref0(pointlabel) & 
    string('with hypotenuse').trim() &
    ref0(mmLength) & 
    ref0(coordinateOfPoint);

  Parser pDouble() => (digit().star() & (string('.') & digit().star()).optional()).flatten().map((d) {
    try {
      return double.parse(d);
    } catch (err) {
      return failure('Not a valid number');
    }
  });

  // TODO: inches
  // E.g. point P_1 20cm west of origin
  Parser relativeToPoint() => 
    ref0(mmLength) & ref0(angle) & ref0(coordinateOfPoint);

  Parser coordinateOfPoint() => 
    ((string('from') | string('of') | string('to')).trim() | failure(expectedToFromOrOfError))& 
    ref0(pointlabel);

  Parser mmLength() => 
    (ref0(pFormula) | failure(invalidFormulaError)) & 
    (string('cm') | string('mm') | string('"')).optionalWith('mm').trim();

  Parser angle() => 
    [ref0(angleInDegrees), ref0(angleInRadians), ref0(direction)].toChoiceParser(failureJoiner: selectFarthest);

  Parser direction() => 
    (
      string('northwest') | string('northeast') | string('southwest') | string('southeast') |
      string('north') | string('south') | string('east') | string('west') | 
      string('up') | string('down') | string('right') | string('left')
    ).trim() | failure(expectedDirectionError);

  // TODO: could put the two together and have rad as default
  // E.g. angle 45 deg 
//  Parser angleInDegrees() => (string('at').trim().optional() & string('angle').trim() & ref0(pFormula) & string('deg').trim()) | failure('Expected an angle');
  Parser angleInDegrees() => (string('at').optional().trim() & string('angle').optional().trim() & ref0(pFormula) & string('deg').trim()) | failure('Expected an angle');
  // E.g. angle 3.14 rad
  Parser angleInRadians() => (string('at').optional().trim() & string('angle').optional().trim() & ref0(pFormula) & string('rad').trim()) | failure('Expected an angle');

  Parser line() => 
    string('line').trim() & 
    (ref0(linelabel) | failure(lineLabelError)) & 
    [
      (string('as').trim() & ref0(templinelabel)), 
      (ref0(coordinateOfPoint) & ref0(coordinateOfPoint))
    ].toChoiceParser(failureJoiner: selectFarthest);

  Parser<String> linelabel([String message = lineLabelError]) => 
    seq2((string('L_') | failure(lineLabelError)), (letter() | anyOf('_-') | digit()).plus()).flatten().trim();

  Parser pFormula([String message = 'Not a valid formula']) => ref0(expression).map((d) {
    if (d is FailureParser) {
      return failure(message);
    }
    return d;
  });

  Parser pMeasurement() => ref0(measurementLabel).map((d) {
    return d;
  });

  Parser measurementLabel([String message = measurementLabelError]) => 
    seq2((string('M_') | failure(measurementLabelError)), (letter() | anyOf('_-') | digit()).plus()).flatten().trim();

  // Maths

  Parser expression() => ref0(term).map((d) {
    if (d is FailureParser) {
      return failure(d.message);
    }
    return d;
  });

  Parser term() => (ref0(add) | ref0(prod)).map((d) {
    if (d is FailureParser) {
      return failure(d.message);
    }
    return d;
  });
  
  Parser add() => (ref0(prod) & (char('+') | char('-')).trim() & ref0(term)).map((d) {
    if (d[0] is FailureParser) {
      return failure(d[2].message);
    }
    if (d[2] is FailureParser) {
      return failure(d[2].message);
    }
    return d[1] == '+' ? d[0] + d[2] : d[0] - d[2];
  });

  Parser prod() => (ref0(mul) | ref0(prim)).map((d) {
    if (d is FailureParser) {
      return failure(d.message);
    }
    return d;
  });
  
  Parser mul() => (ref0(prim) & (char('*') | char('/')).trim() & ref0(prod)).map((d) {
    if (d[0] is FailureParser) {
      return failure(d[2].message);
    }
    if (d[2] is FailureParser) {
      return failure(d[2].message);
    }
    return d[1] == '*' ? d[0] * d[2] : d[0] / d[2];
  });

  Parser prim() => (ref0(parens) | ref0(mathsfunction) | ref0(linefunction) | ref0(number)).map((d) {
    if (d is FailureParser) {
      return failure(d.message);
    }
    return d;
  });

  Parser parens() => (string('(').trim() & ref0(term) & string(')').trim()).map((result) {
    if (result[1] is FailureParser) {
      return failure(result[1].message);
    }
    return result[1];
  });

  // TODO: also allow templinelabel
  Parser linefunction() => ref0(linelabel) & string('.length');

  // Maths functions like cos(x), max(x, y), etc
  Parser mathsfunction() => seq2(
    seq2(letter(), word().star()).flatten('name expected').trim(),
    seq3(
      char('(').trim(),
      ref0(term).starSeparated(char(',')).map((list) {
        return list.elements;
      }),
      char(')').trim(),
    ).map3((_, list, __) => list)
  ).map2((name, args) {
    // Here we get a function name and the args list. E.g. cos(5) will give name cos and args [5]
    // Original would create an 'Application' here, but I'll just perform the maths right here and return
    // a double
    
    switch (args.length) {
      case 1:
        switch (name) {
          case 'cos': return cos(args[0]);
          case 'acos': return acos(args[0]);
          case 'sin': return sin(args[0]);
          case 'asin': return asin(args[0]);
          case 'tan': return tan(args[0]);
          case 'atan': return atan(args[0]);
          case 'exp': return exp(args[0]);
          case 'log': return log(args[0]);
          case 'sqrt': return sqrt(args[0]);
          case 'pow': return pow(args[0], 2);
          case 'abs': return (args[0] as double).abs();
          case 'ceil': return (args[0] as double).ceil();
          case 'floor': return (args[0] as double).floor();
          case 'round': return (args[0] as double).round();
          default:
            throw ArgumentError.value(name, 'Unknown function', 'Unknown function $name');
        }
      case 2:
        switch (name) {
          case 'atan2': return atan2(args[0], args[1]);
          case 'max': return max(args[0] as double, args[1] as double);
          case 'min': return min(args[0] as double, args[1] as double);
          case 'pow': return pow(args[0] as double, args[1] as double);

          default:
            throw ArgumentError.value(name, 'Unknown function', 'Unknown function $name');
        }
      default:
        throw ArgumentError.value(name, 'Unknown function', 'Unknown function $name');
    }
  });

  Parser number([String message = 'Expected a measurement or double']) => 
    ref0(pMeasurement) | ref0(pDouble);

  //============ Curves ==============

  Parser curve() => 
    ref0(curveThroughTwoPoints);

  // e.g. curve C_A 1/8 from P_A to P_B apex 3/4
  Parser curveThroughTwoPoints() =>
    string('curve') &
    ref0(curvelabel) &
    (string('pos') | string('neg')).optionalWith('pos').trim() &
    pFormula() &
    string('from').trim() &
    ref0(pointlabel) &
    string('to').trim() &
    ref0(pointlabel) &
    (string('apex').trim() & (ref0(fraction) | failure(expectedFractionError))).optional();


  Parser<String> curvelabel([String message = curveLabelError]) => 
    seq2((string('C_') | failure(curveLabelError)), (letter() | anyOf('_-') | digit()).plus()).flatten().trim();

  //=========== Layouts ===============

  Parser layout() =>
    string('layout').trim() &
    [ref0(relativeConstraint), ref0(partPlacement)].toChoiceParser(failureJoiner: selectFarthest);

  Parser relativeConstraint() =>
    (ref0(partlabel) | failure('Expected a part label')) & 
    (string('below') | string('above') | 
     string('right of') | string('to the right of') | 
     string('left of') | string('to the left of') |
     string('align right with') | string('align left with') |
     string('align top with') | string('align bottom with')).trim() & 
    ref0(partlabel);

  // E.g. Layout L_1 Sleeve flipped over x rotated 90deg
  Parser partPlacement() =>
    (ref0(partlabel) | failure('Expected a part label')) & 
    (string('flipped over xy') | string('flipped over x') | string('flipped over y')).trim().optionalWith('') &
    (string('rotated once') | string('rotated twice') | string('rotated thrice')).optional();

  // =========== Test commands ==============
  Parser exec() => 
    string('exec').trim() & (word() | anyOf('-_')).plus().flatten().map((result) {
      return result;
    });

}

