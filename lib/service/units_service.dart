
import 'package:sew_ml/service/inch_unit.dart';

class UnitsService {
  
  UnitsService._privateConstructor();
  static final UnitsService _instance = UnitsService._privateConstructor();
  factory UnitsService() => _instance;

  static const double _mmPerInch = 25.4;

  InchUnit toInches(double mm) {
    double decimalPart = mm / _mmPerInch;

    InchUnit res = InchUnit(wholePart: decimalPart.floor());

    int numerator = ((decimalPart - decimalPart.floor()) * 64).round();
    if (numerator == 0) {
      return res;
    }
    if (numerator == 64) {
      return InchUnit(wholePart: res.wholePart + 1);
    }

    int denominator = 64;
    while (numerator.isEven) {
      numerator = numerator ~/ 2;
      denominator = denominator ~/ 2;
    }

    return InchUnit(wholePart: res.wholePart, fractionNumerator: numerator, fractionDenominator: denominator);
  }

}