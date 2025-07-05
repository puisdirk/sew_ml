
import 'package:petitparser/core.dart';
import 'package:sew_ml/parser/intent_parser/intent.dart';

IntentParser passOne(Parser delegate, Intent intent, {String? message}) =>
  IntentParser(delegate, [intent], passAll: true, message: message);
IntentParser passAll(Parser delegate, List<Intent> intents, {String? message}) =>
  IntentParser(delegate, intents, passAll: true, message: message);
IntentParser passAny(Parser delegate, List<Intent> intents, {String? message}) =>
  IntentParser(delegate, intents, passAll: false, message: message);
/*
extension IntentParserExtension<T, R> on IntentParser<T, R> {
  IntentParser<T, R> pass(Parser<T> delegate, Intent intent, {String? message}) =>
    IntentParser<T, R>(delegate, [intent], passAll: true, message: message);
  IntentParser<T, R> passAll(Parser<T> delegate, List<Intent> intents, {String? message}) =>
    IntentParser<T, R>(delegate, intents, passAll: true, message: message);
  IntentParser<T, R> passAny(Parser<T> delegate, List<Intent> intents, {String? message}) =>
    IntentParser<T, R>(delegate, intents, passAll: false, message: message);
}
*/
class IntentParser<T, R> extends Parser<R> implements Intent {
  final Parser<T> delegate;
  final List<Intent> intents;
  final String? message;
  final bool passAll;

  IntentParser(this.delegate, this.intents, {this.passAll = true, this.message})
    : assert(intents.isNotEmpty, 'Intent parser intents cannot be empty');

  @override
  Parser<R> copy() => IntentParser(delegate, intents);

  @override
  bool passes(Context context) {
    if (passAll) {
      for (Intent intent in intents) {
        if (!intent.passes(context)) {
          return false;
        }
      }
      return true;
    } else {
      for (Intent intent in intents) {
        if (intent.passes(context)) {
          return true;
        }
      }
      return false;
    }

  }

  @override
  Result<R> parseOn(Context context) {
    if (!passes(context)) {
      return Failure(context.buffer, context.position, message ?? 'Intent does not pass');
    }
    
    return delegate.parseOn(context) as Result<R>;
  }

}