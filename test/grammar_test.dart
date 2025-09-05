
import 'package:flutter_test/flutter_test.dart';
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/measurement.dart';
import 'package:sew_ml/ast/point.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';
import 'package:sew_ml/parser/error_messages.dart';

void main() {
/*    test('linter', () {
      SewMLParserDefinition parserDefinition = SewMLParserDefinition();
      Parser<List<ParserElement>> parser = parserDefinition.buildFrom(parserDefinition.start()).end();
      expect(linter(parser, excludedTypes: {LinterType.info}), isEmpty);
    });
*/

  group('measurements', () {
    group('success', () {
      test('measurement in cm', () {
        Drawing drawing = Drawing.parse(['measurement M_test 20cm']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_test', valueInMMorRad: 200)), true);
      });

      test('measurement in mm', () {
        Drawing drawing = Drawing.parse(['measurement M_test 200mm']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_test', valueInMMorRad: 200)), true);
      });

      test('mm are default', () {
        Drawing drawing = Drawing.parse(['measurement M_test 200']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_test', valueInMMorRad: 200)), true);
      });

      test('measurement with formula', () {
        Drawing drawing = Drawing.parse(['measurement M_test 200 + 2mm']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_test', valueInMMorRad: 202)), true);
      });

      test('measurement with formula 2', () {
        Drawing drawing = Drawing.parse(['measurement M_test 20 + 0.2cm']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_test', valueInMMorRad: 202)), true);
      });

      test('measurement with formula 3', () {
        Drawing drawing = Drawing.parse([
          'measurement M_1 20cm',
          'measurement M_2 2cm',
          'measurement M_3 M_1 + M_2 mm'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 4);
        expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 200)), true);
        expect(drawing.elements.contains(Measurement(label: 'M_2', valueInMMorRad: 20)), true);
        expect(drawing.elements.contains(Measurement(label: 'M_3', valueInMMorRad: 220)), true);
      });

      group('Measurements always come back in mm', () {
        // Whenever you use a measurement you previously defined, you get it back in mm.
        test('wrong assumption', () {
          Drawing drawing = Drawing.parse([
            'measurement M_1 20cm',
            'measurement M_2 M_1 + 2cm'
          ]);
          expect(drawing.hasError, false);
          expect(drawing.elements.length, 3);
          expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 200)), true);
          // The expression M_1 + 2cm receives 200, adds 2, and then converts that 
          // 202 to 2020mm; not the 220mm you would expect.
          // TODO: to fix by keeping unit? By adding cm/mm to formula?
          expect(drawing.elements.contains(Measurement(label: 'M_2', valueInMMorRad: 2020)), true);
        });

        test('Measurements always come back in mm, but protecting the cm will not work', () {
          Drawing drawing = Drawing.parse([
            'measurement M_1 20cm',
            'measurement M_2 M_1 + (2cm)'
          ]);
          expect(drawing.hasError, true);
          expect(drawing.elements.length, 2);
          expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 200)), true);
          expect(drawing.errorsSummary, '$expectedMeasurementDefinitionError on line 2');
        });

        test('Measurements always come back in mm, so you need to add values in mm to it', () {
          Drawing drawing = Drawing.parse([
            'measurement M_1 20cm',
            'measurement M_2 M_1 + 20'
          ]);
          expect(drawing.hasError, false);
          expect(drawing.elements.length, 3);
          expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 200)), true);
          expect(drawing.elements.contains(Measurement(label: 'M_2', valueInMMorRad: 220)), true);
        });
      });

      test('inches', () {
        Drawing drawing = Drawing.parse(['measurement M_1 1/8"']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 3.175)), true);
      });

      test('measurements do not get overwritten', () {
        // When redefining a measurement, the system doesn't cause an error and does not
        // overwrite the previous value (allowing one to execute a template with different
        // measurements)
        final Drawing drawing = Drawing.parse([
          'measurement M_1 20cm',
          'measurement M_1 50cm'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Measurement(label: 'M_1', valueInMMorRad: 200)), true);
      });
    }); // end measurement success

    group('error', () {
      test('missing definition', () {
        Drawing drawing = Drawing.parse(['measurement M_1 ']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$expectedMeasurementDefinitionError on line 1');
      });

      test('invalid formula', () {
        Drawing drawing = Drawing.parse(['measurement M_1 hiho mm']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$expectedMeasurementDefinitionError on line 1');
      });

      test('invalid label', () {
        final Drawing drawing = Drawing.parse(['measurement w_1 20cm']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$measurementLabelError on line 1 at position 12');
      });
    });

  });

  group('point', () {

    group('success', () {
      test('relativepoint1', () {
        final drawing = Drawing.parse(['point P_A 20cm east of origin']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Point(label: 'P_A', coordinate: Coordinate(200, 0))), true);
      });

      test('relativepoint2', () {
        final drawing = Drawing.parse(['point P_A 200mm up from origin']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Point(label: 'P_A', coordinate: Coordinate(0, 200))), true);
      });

      test('relativepointdeg', () {
        final drawing = Drawing.parse(['point P_A 200mm at 45deg from origin']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Point(label: 'P_A', coordinate: Coordinate(141.42, 141.42))), true);
      });

      test('two points', () {
        final drawing = Drawing.parse(['point P_A 200mm up from origin','point P_B 10cm left of P_A']);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(Point(label: 'P_A', coordinate: Coordinate(0, 200))), true);
        expect(drawing.elements.contains(Point(label: 'P_B', coordinate: Coordinate(-100, 200))), true);
      });
    });

    group('errors', () {
      test('relativepointdeg without at', () {
        final drawing = Drawing.parse(['point P_A 200mm 45deg from origin']);
//        expect(drawing.hasError, true);
//        expect(drawing.elements.length, 1);
//        expect(drawing.errorsSummary, '$expectedDirectionError on line 1 at position 16');
        // Note: 'at' became optional
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 2);
        expect(drawing.elements.contains(Point(label: 'P_A', coordinate: Coordinate(141.42, 141.42))), true);
      });

      test('misspelled direction', () {
        final drawing = Drawing.parse(['point P_A 200mm orth from origin']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$expectedDirectionError on line 1 at position 16');
      });

      test('not a point', () {
        final drawing = Drawing.parse(['point P_A 200mm north of L_1']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$pointLabelError on line 1 at position 25');
      });

      test('missing relativepointdeg', () {
        final drawing = Drawing.parse(['point P_A 200mm north from P_B']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$noSuchPointError P_B on line 1');
      });

      test('missing to-from-of', () {
        final drawing = Drawing.parse(['point P_A 200mm north origin']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$expectedToFromOrOfError on line 1 at position 22');
      });

      test('invalid label', () {
        final drawing = Drawing.parse(['point z_A 200mm north of origin']);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 1);
        expect(drawing.errorsSummary, '$pointLabelError on line 1 at position 6');
      });
    });

  });

  group('lines', () {

    group('success', () {
      test('single line', () {
        final drawing = Drawing.parse([
          'point P_A 20cm east of origin',
          'line L_A from P_A to origin'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(Line(label: 'L_A', startPoint: Coordinate(200, 0), endPoint: Coordinate(0, 0))), true);
      });

      test('temp line notation', () {
        final drawing = Drawing.parse([
          'point P_A 20cm east of origin',
          'line L_A as origin/P_A'
        ]);
        expect(drawing.hasError, false, reason: 'drawing should not have errors');
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(Line(label: 'L_A', startPoint: Coordinate(0, 0), endPoint: Coordinate(200, 0))), true);
      });
    });

    group('errors', () {
      test('invalid label', () {
        final Drawing drawing = Drawing.parse([
          'point P_A 20cm east of origin',
          'line P_B from P_A to origin'
        ]);
        expect(drawing.hasError, true);
        expect(drawing.elements.length, 2);
        expect(drawing.errorsSummary, '$lineLabelError on line 2 at position 5');
      });
    });
  });

  group('curves', () {
    group('success', () {
      test('curve', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve C_1 1/2 from origin to P_1'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(
          QuadraticBezier(
            label: 'C_1', 
            startPoint: Coordinate(0, 0), 
            endPoint: Coordinate(200, 0), 
            controlPoint: Coordinate(100, 100))
          ), true);
      });

      test('pos curve', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve C_1 pos 1/2 from origin to P_1'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(
          QuadraticBezier(
            label: 'C_1', 
            startPoint: Coordinate(0, 0), 
            endPoint: Coordinate(200, 0), 
            controlPoint: Coordinate(100, 100))
          ), true);
      });

      test('curve with apex', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve C_1 1/2 from origin to P_1 apex 1/4'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(
          QuadraticBezier(
            label: 'C_1', 
            startPoint: Coordinate(0, 0), 
            endPoint: Coordinate(200, 0), 
            controlPoint: Coordinate(50, 100))
          ), true);
      });

      test('curve with formula', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve C_1 1/4 + 1/4 from origin to P_1'
        ]);
        expect(drawing.hasError, false);
        expect(drawing.elements.length, 3);
        expect(drawing.elements.contains(
          QuadraticBezier(
            label: 'C_1', 
            startPoint: Coordinate(0, 0), 
            endPoint: Coordinate(200, 0), 
            controlPoint: Coordinate(100, 100))
          ), true);
      });
    }); // end curves.success

    group('errors', () {
      test('invalid label', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve z_1 1/2 from origin to P_1'
        ]);
        expect(drawing.hasError, true);
        expect(drawing.errorsSummary, '$curveLabelError on line 2 at position 6');
      });

      test('missing formula', () {
        final Drawing drawing = Drawing.parse([
          'point P_1 20cm east of origin',
          'curve C_1 from origin to P_1'
        ]);
        expect(drawing.hasError, true);
        // TODO: find a way to improve this
        expect(drawing.errorsSummary, '$expectedFractionError after the curve label (Not a valid formula) on line 2');
      });
    });
  });
}