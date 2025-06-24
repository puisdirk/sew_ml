enum PrintPageSize {
  a4,
  a3,
  a2,
  a1,
  a0,
}

enum PrintPageOrientation {
  portrait,
  landscape,
}

class PageLayout {
  final PrintPageSize pageSize;
  final PrintPageOrientation pageOrientation;
  PageLayout({
    required this.pageSize,
    required this.pageOrientation,
  });
}

