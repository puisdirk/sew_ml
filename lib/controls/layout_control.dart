
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:sew_ml/service/page_layout_service.dart';
import 'package:sew_ml/service/pdf_service.dart';

class LayoutControl extends StatelessWidget {
  final List<String> commands;
  final int maxValidLineNumber;
  final bool _showPageBreaks;

  const LayoutControl({
    required this.commands,
    required this.maxValidLineNumber,
    bool showPageBreaks = true,
    super.key
  }) : _showPageBreaks = showPageBreaks;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    List<String> validCommands = List.from(commands);
    if (maxValidLineNumber != -1) {
      validCommands = validCommands.sublist(0, maxValidLineNumber);
    }
    Drawing drawing = Drawing.parse(validCommands, {});

    return Center(
      child: FutureBuilder<PageLayout>(
        future: PageLayoutService().getPageLayout(),
        builder: (context, snapshot) => 
          CustomPaint(
            size: Size((screenSize.width / 2) * 0.9, (screenSize.height / 2) * 0.9),
            painter: LayoutPainter(drawing: drawing, showPageBreaks: _showPageBreaks, pageLayout: snapshot.data),
          )
      ),
    );
  }
}

class LayoutPainter extends CustomPainter {

  final Drawing drawing;
  final bool showPageBreaks;
  final PageLayout? pageLayout;

  LayoutPainter({
    required this.drawing,
    required this.showPageBreaks,
    required this.pageLayout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset midpoint = Offset(size.width / 2.0, size.height / 2.0);

    Paint borderPaint = Paint()
    ..color = Colors.grey.shade400
    ..style = PaintingStyle.stroke;

    Paint partPaint = Paint()
    ..color = Colors.green.shade700
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

/*    Paint redPaint = Paint()
    ..color = Colors.red.shade700
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;
*/

    Paint pageGuidesPaint = Paint()
    ..color = Colors.red.shade400
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromCenter(center: midpoint, width: size.width, height: size.height), borderPaint);

    Map<String, Path> paths = drawing.getLayoutPaths(midpoint: midpoint);

    Path completePattern = Path();
    for (Path partPath in paths.values) {
      completePattern.addPath(partPath, Offset.zero);
    }

    // Now we scale the whole thing
    // Get the dimensions
    Rect completeBounds = completePattern.getBounds();
    completeBounds = completeBounds.inflate((completeBounds.longestSide * 20) / 100);
    double scale = 1;
    if (completeBounds.width >= completeBounds.height) {
      scale = size.width / completeBounds.width;
    } else {
      scale = size.height / completeBounds.height;
    }

    canvas.scale(scale);

    // place at 0,0 plus border
    completeBounds = completePattern.getBounds();
    Matrix4 setAtZero = Matrix4.identity();
    setAtZero.translate(-completeBounds.left + PdfService.pageOverlapBorderMM, - completeBounds.top + PdfService.pageOverlapBorderMM);
    completePattern = completePattern.transform(setAtZero.storage);

    // Now we draw
    canvas.drawPath(completePattern, partPaint);

    if (showPageBreaks && pageLayout != null) {
      Offset pageSizeMM = PageLayoutService().getDimensionsForLayout(pageLayout!);

      // Draw grid
      double pageWidthMM = pageSizeMM.dx;
      double pageHeightMM = pageSizeMM.dy;
      int numHorPages = (completeBounds.width / pageWidthMM).ceil();
      int numVertPages = (completeBounds.height / pageHeightMM).ceil();

      // Account for page overlap border
      double overlappedCompleteWidth = completeBounds.width + (numHorPages * (PdfService.pageOverlapBorderMM * 2.0));
      double overlappedCompleteHeight = completeBounds.height + (numVertPages * (PdfService.pageOverlapBorderMM * 2.0));

      numHorPages = (overlappedCompleteWidth / pageWidthMM).ceil();
      numVertPages = (overlappedCompleteHeight / pageHeightMM).ceil();

      Rect r = Rect.fromLTWH(0.0, 0.0, pageWidthMM, pageHeightMM);
      int pageNumber = 1;
      final TextStyle textStyle = TextStyle(color: Colors.grey[300]);
      const double textSize = 60;

      for (int vertPage = 0; vertPage < numVertPages; vertPage++) {
        for (int horPage = 0; horPage < numHorPages; horPage++) {
          canvas.drawRect(r, pageGuidesPaint);
          
          // Draw page number
          final ParagraphBuilder paragraphBuilder = ParagraphBuilder(
            ParagraphStyle(
              fontSize: textSize,
              fontFamily: textStyle.fontFamily,
              fontStyle: textStyle.fontStyle,
              fontWeight: textStyle.fontWeight,
              textAlign: TextAlign.left,
            ),
          )
          ..pushStyle(textStyle.getTextStyle())
          ..addText(pageNumber.toString());

          final Paragraph paragraph = paragraphBuilder.build()
          ..layout(ParagraphConstraints(width: r.width));

          canvas.drawParagraph(paragraph, r.center - const Offset(textSize / 2, textSize / 2));

          pageNumber++;

          r = r.translate(pageWidthMM - PdfService.pageOverlapBorderMM, 0.0);
        }
        r = r.translate(-r.left, pageHeightMM - PdfService.pageOverlapBorderMM);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LayoutPainter oldDelegate) {
    return drawing != oldDelegate.drawing || 
      showPageBreaks != oldDelegate.showPageBreaks || 
      pageLayout != oldDelegate.pageLayout;
  }
}