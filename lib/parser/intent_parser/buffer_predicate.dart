

import 'package:petitparser/core.dart';
import 'package:sew_ml/parser/intent_parser/intent.dart';

BufferStartsWith bufferStartsWith(String startString, {bool caseSensitive = false, bool fromStart = true}) =>
  BufferStartsWith(startString, caseSensitive: caseSensitive, fromStart: fromStart);
BufferContains bufferContains(String containsString, {bool caseSensitive = false, bool fromStart = true}) =>
  BufferContains(containsString, caseSensitive: caseSensitive, fromStart: fromStart);

class BufferStartsWith extends Intent {
  final String startString;
  final bool caseSensitive;
  final bool fromStart;
  BufferStartsWith(
    this.startString, 
    {
      this.caseSensitive = false,
      this.fromStart = true
    }
  );

  @override
  bool passes(Context context) {
    return caseSensitive ? 
      context.buffer.startsWith(startString, fromStart ? 0 : context.position) :
      context.buffer.toLowerCase().startsWith(startString.toLowerCase(), fromStart ? 0 : context.position);
  }
}

class BufferContains extends Intent {
  final String containsString;
  final bool caseSensitive;
  final bool fromStart;
  BufferContains(
    this.containsString, 
    {
      this.caseSensitive = false, 
      this.fromStart = true
    }
  );

  @override
  bool passes(Context context) {
    return caseSensitive ?
      context.buffer.contains(containsString, fromStart ? 0 : context.position) :
      context.buffer.toLowerCase().contains(containsString.toLowerCase(), fromStart ? 0 : context.position);
  }
}