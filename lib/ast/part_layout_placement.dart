
enum Flip {
  none, x, y, xy,
}

class PartLayoutPlacement {
  final String partName;
  final double orientationRad;
  final Flip flip;

  PartLayoutPlacement({
    required this.partName,
    this.orientationRad = 0,
    this.flip = Flip.none,
  });
}