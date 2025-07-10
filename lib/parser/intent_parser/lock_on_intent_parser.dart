
import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';
import 'package:sew_ml/parser/intent_parser/intent_parser.dart';

LockOnIntentParser lockIntent(
  List<IntentParser> children, {String? message, Parser? fallThrough}) => 
    LockOnIntentParser(children, message: message, fallThrough: fallThrough);

class LockOnIntentParser<R> extends ListParser<R, List<R>> {

  final String? message;
  final Parser? fallThrough;

  LockOnIntentParser(super.children, {this.message, this.fallThrough}) :
    assert(children.every((p) => p is IntentParser));

  @override
  LockOnIntentParser<R> copy() => LockOnIntentParser<R>(children);

  @override
  Result<List<R>> parseOn(Context context) {

    final elements = <R>[];
    for (Parser child in children) {
      IntentParser intentParser = child as IntentParser;
      if (intentParser.passes(context)) {
        final result = intentParser.parseOn(context);
        if (result is Failure) {
          return Failure(result.buffer, result.position, intentParser.message?? result.message);
        }
        elements.add(result.value);
        return Success(context.buffer, result.position, elements);
      }
    }

    if (fallThrough != null) {
      final result = fallThrough!.parseOn(context);
      if (result is Failure) {
        return Failure(result.buffer, result.position, message ?? result.message);
      }
      elements.add(result.value);
      return Success(context.buffer, result.position, elements);
    }

    return Failure(context.buffer, context.position, message ?? 'No valid intent found');
  }

}