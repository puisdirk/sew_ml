
import 'package:flutter_test/flutter_test.dart';
import 'package:sew_ml/service/units_service.dart';

void main() {
  test('some fractions', (){
    expect(UnitsService().toInches(31.75).toString(), '1 1/4');
    expect(UnitsService().toInches(31.77).toString(), '1 1/4');
    expect(UnitsService().toInches(6.35).toString(), '1/4');

    expect(UnitsService().toInches(257.048).toString(), '10 1/8');
    expect(UnitsService().toInches(257).toString(), '10 1/8');
  });
}