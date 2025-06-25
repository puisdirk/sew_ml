class ParserError {
  final String message;
  final int lineNumber;
  final int linePosition;

  const ParserError({
    required this.message,
    required this.lineNumber,
    required this.linePosition,
  });

  @override
  String toString() {
    return '$message on line $lineNumber at position $linePosition';
  }
}