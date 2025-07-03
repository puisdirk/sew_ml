class ParserError {
  final String message;
  final int lineNumber;
  final int linePosition;

  const ParserError({
    required this.message,
    required this.lineNumber,
    required this.linePosition,
  });

  bool get hasPosition => linePosition != -1;

  @override
  String toString() {
    String pos = hasPosition ? ' at position $linePosition' : '';
    return '$message on line $lineNumber$pos';
  }
}