
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/part_layout_placement.dart';
import 'package:sew_ml/ast/relative_placement.dart';

class PartsLayout extends ParserElement {

  static const defaultLayoutLabel = 'SEW_ML_LAYOUT_LABEL';

  final List<PartLayoutPlacement> _placements;
  final List<RelativePlacement> _relativePlacements;

  PartsLayout() : _placements = [], _relativePlacements = [], super(label: defaultLayoutLabel);

  @override
  void offset(double x, double y) {
    // nothing to do
  }

  bool addPart(PartLayoutPlacement placement) {
    if (_placements.contains(placement)) {
      return false;
    }

    _placements.add(placement);
    return true;
  }

  bool addConstraint(RelativePlacement placement) {
    if (_relativePlacements.contains(placement)) {
      return false;
    }
    _relativePlacements.add(placement);
    return true;
  }

  List<PartLayoutPlacement> get placements => _placements;
  List<RelativePlacement> get relativePlacements => _relativePlacements;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is PartsLayout &&
      runtimeType == other.runtimeType &&
      label == other.label &&
      _placements == other._placements;

  @override
  int get hashCode => super.hashCode ^ _placements.hashCode;

}