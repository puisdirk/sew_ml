import 'package:flutter_test/flutter_test.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/parser/error_messages.dart';

void main() {
  group('measurement', () {

    test('empty measurement', () {
      Drawing drawing = Drawing.parse(['measurement']);
      expect(drawing.hasError, true);
      expect('$measurementLabelError on line 1 at position 11', drawing.errorsSummary);
    });

    test('invalid name', () {
      Drawing drawing = Drawing.parse(['measurement inv']);
      expect(drawing.hasError, true);
      expect('$measurementLabelError on line 1 at position 12', drawing.errorsSummary);
    });

    test('missing definition', () {
      Drawing drawing = Drawing.parse(['measurement M_test']);
      expect(drawing.hasError, true);
      expect('$noMeasurementDefinitionError on line 1', drawing.errorsSummary);
    });
  });

    group('point', () {

      group('success', () {
        test('point relativeToPoint', (){
          Drawing drawing = Drawing.parse(['point P_1 20cm north of origin']);
          expect(drawing.hasError, false);
          expect(drawing.elements.length, 2);
        });
      });

      group('failures', (){
        test('empty point', () {
          Drawing drawing = Drawing.parse(['point']);
          expect(drawing.hasError, true);
          expect('$pointLabelError on line 1 at position 5', drawing.errorsSummary);
        });

        test('invalid name', () {
          Drawing drawing = Drawing.parse(['point inv']);
          expect(drawing.hasError, true);
          expect('$pointLabelError on line 1 at position 6', drawing.errorsSummary);
        });

        test('missing definition', () {
          Drawing drawing = Drawing.parse(['point P_test']);
          expect(drawing.hasError, true);
          expect('$noPointDefinitionError on line 1 at position 12', drawing.errorsSummary);
        });

        test('missing direction', () {
          Drawing drawing = Drawing.parse(['point P_test 20cm']);
          expect(drawing.hasError, true);
          expect('$noPointDefinitionError on line 1 at position 13', drawing.errorsSummary);
        });

        test('point missing label', (){
          Drawing drawing = Drawing.parse(['point 20cm north of origin']);
          expect(drawing.hasError, true);
          expect('$pointLabelError on line 1 at position 6', drawing.errorsSummary);
        });

        test('point invalid direction', (){
          Drawing drawing = Drawing.parse(['point P_1 20cm orth of origin']);
          expect(drawing.hasError, true);
          // TODO: unless I find a better way to handle errors, this will just return noPointDefinitionError
        });

        test('no such point', () {
          Drawing drawing = Drawing.parse(['point P_1 20cm north of P_2']);
          expect(drawing.hasError, true);
          expect('$noSuchPoint P_2 on line 1', drawing.errorsSummary);
        });

        test('double label', (){
          Drawing drawing = Drawing.parse([
            'point P_1 20cm north of origin',
            'point P_1 30cm north of origin'
          ]);
          expect(drawing.hasError, true);
          expect('P_1 $alreadyExists on line 2', drawing.errorsSummary);
        });
      });

  });

}