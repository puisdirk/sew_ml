
import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/parser/sew_m_l_parser_definition.dart';

void main() {
  group('point', () {

    test('linter', () {
    SewMLParserDefinition parserDefinition = SewMLParserDefinition();
    Parser<List<ParserElement>> parser = parserDefinition.buildFrom(parserDefinition.start()).end();
      expect(linter(parser, excludedTypes: {}), isEmpty);
    });

    group('relative point', () {
      test('relativepoint1', () {
        final drawing = Drawing.parse(['point P_A 20cm east of origin']);
        expect(drawing.elements.length, 2);
      });

      test('relativepoint2', () {
        final drawing = Drawing.parse(['point P_A 200mm up from origin']);
        expect(drawing.elements.length, 2);
      });

      test('relativepointdeg', () {
        final drawing = Drawing.parse(['point P_A 200mm 45deg from origin']);
        expect(drawing.elements.length, 2);
      });

      test('two points', () {
        final drawing = Drawing.parse(['point P_A 200mm up from origin','point P_B 10cm left of P_A']);
        expect(drawing.elements.length, 3);
      });
    });


/*    test('exactcoords', () {
      final drawCommand = drawCommandParser().parse('point P_1 at 1.2, 2.5');
      expect(true, drawCommand is Success);
      expect(drawCommand.value.toString(), 'DrawPointCommand(label: P_1, x: 1.2, y: 2.5)');
    });*/
  });

  group('lines', () {
    test('single line', () {
      final drawing = Drawing.parse([
        'point P_A 20cm east of origin',
        'line L_A from origin to P_A'
      ]);
      expect(drawing.elements.length, 3);
    });
  });
}