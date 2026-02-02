
class InchUnit {
  int wholePart;
  int fractionNumerator;
  int fractionDenominator;

  InchUnit({
    required this.wholePart,
    this.fractionNumerator = 0,
    this.fractionDenominator = 64
  });

  void setWholePart(int wholePart) => wholePart = wholePart;
  void setNumerator(int numerator) => fractionNumerator = numerator;
  void setDenominator(int denominator) => fractionDenominator = denominator;
  void setFraction(int numerator, int denominator) {
    fractionNumerator = numerator;
    fractionDenominator = denominator;
  }

  @override
  String toString() {
    return wholePart == 0 ?
      fractionNumerator == 0 ? '0' : '$fractionNumerator/$fractionDenominator' :
      fractionNumerator == 0 ? '$wholePart' : '$wholePart $fractionNumerator/$fractionDenominator';
  }
}