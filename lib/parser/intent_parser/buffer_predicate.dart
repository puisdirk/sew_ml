

import 'package:petitparser/core.dart';
import 'package:sew_ml/parser/intent_parser/intent.dart';

BufferStartsWith bufferStartsWith(String startString, {bool caseSensitive = false, bool completeBuffer = true}) =>
  BufferStartsWith(startString, caseSensitive: caseSensitive, completeBuffer: completeBuffer);
BufferContains bufferContains(String containsString, {bool caseSensitive = false, bool completeBuffer = true}) =>
  BufferContains(containsString, caseSensitive: caseSensitive, completeBuffer: completeBuffer);

class BufferStartsWith extends Intent {
  final String startString;
  final bool caseSensitive;
  final bool completeBuffer;
  BufferStartsWith(
    this.startString, 
    {
      this.caseSensitive = false,
      this.completeBuffer = true
    }
  );

  @override
  bool passes(Context context) {
    return caseSensitive ? 
      context.buffer.startsWith(startString, completeBuffer ? 0 : context.position) :
      context.buffer.toLowerCase().startsWith(startString.toLowerCase(), completeBuffer ? 0 : context.position);
  }
}

class BufferContains extends Intent {
  final String containsString;
  final bool caseSensitive;
  final bool completeBuffer;
  BufferContains(
    this.containsString, 
    {
      this.caseSensitive = false, 
      this.completeBuffer = true
    }
  );

  @override
  bool passes(Context context) {
    return caseSensitive ?
      context.buffer.contains(containsString, completeBuffer ? 0 : context.position) :
      context.buffer.toLowerCase().contains(containsString.toLowerCase(), completeBuffer ? 0 : context.position);
  }
}