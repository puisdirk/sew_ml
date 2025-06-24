
class Coordinate {
  double _x = 0;
  double _y = 0;

  Coordinate(double x, double y) : _x = x, _y = y;

  void setPrecision(int fractionDigits) {
    _x = double.parse(_x.toStringAsFixed(fractionDigits));
    _y = double.parse(_y.toStringAsFixed(fractionDigits));
  }

  double get x => _x;
  double get y => _y;

  Coordinate offset(double x, double y) {
    return Coordinate(_x + x, _y + y);
  }

  @override
  int get hashCode => super.hashCode ^ _x.hashCode ^ _y.hashCode;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Coordinate &&
      runtimeType == other.runtimeType &&
      _x == other._x &&
      _y == other._y;
}