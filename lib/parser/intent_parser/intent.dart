import 'package:petitparser/core.dart';

abstract class Intent {
  bool passes(Context context);
}
