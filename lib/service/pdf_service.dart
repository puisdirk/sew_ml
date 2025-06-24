import 'dart:io';
import 'dart:ui';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sew_ml/ast/drawing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sew_ml/service/svg_info.dart';
import 'package:sew_ml/service/svg_service.dart';

class PdfService {

  static const double pageOverlapBorderMM = 20.0;
  static const double pageOverlapBorderCM = pageOverlapBorderMM / 10.0;

  static Future<void> saveAsPdf(
    Drawing drawing, 
    {
      String layoutName = '', 
      double pageWidthMM = 210, 
      double pageHeightMM = 297, 
    }
  ) async {

    String initialFileName = layoutName;
    if (initialFileName.isEmpty) {
      initialFileName = 'layout';
    }

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: '$initialFileName.pdf',
    );

    if (outputFile == null) {
      return;
    }

    SvgInfo svgInfo = SvgService.createSVG(drawing);

    final pdf = pw.Document();

    // split over pages.
    int numHorPages = (svgInfo.width / pageWidthMM).ceil();
    int numVertPages = (svgInfo.height / pageHeightMM).ceil();

    // Take page overlap border into account
    double overlappedCompleteWidth = svgInfo.width + (numHorPages * (pageOverlapBorderMM * 2.0));
    double overlappedCompleteHeight = svgInfo.height + (numVertPages * (pageOverlapBorderMM * 2.0));
    numHorPages = (overlappedCompleteWidth / pageWidthMM).ceil();
    numVertPages = (overlappedCompleteHeight / pageHeightMM).ceil();

    Offset pageOffset = Offset.zero;

    int pageNumber = 1;

    for (int vertPage = 0; vertPage < numVertPages; vertPage++) {
      for (int horPage = 0; horPage < numHorPages; horPage++) {

        String svgRaw = '<svg width="${pageWidthMM}mm" height="${pageHeightMM}mm" viewBox="${pageOffset.dx} ${pageOffset.dy} $pageWidthMM $pageHeightMM" xmlns="http://www.w3.org/2000/svg">';
        svgRaw += '<g transform="translate($pageOverlapBorderMM, $pageOverlapBorderMM)">${svgInfo.childSvg}</g></svg>';
        
        pageOffset = pageOffset.translate(pageWidthMM - pageOverlapBorderMM, 0.0);

        const double fontSize = 60.0;

        final svgImage = pw.SvgImage(svg: svgRaw, width: pageWidthMM * PdfPageFormat.mm, height: pageHeightMM * PdfPageFormat.mm);
        final String pageNumberString = pageNumber.toString();
        pageNumber++;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              pageWidthMM * PdfPageFormat.mm, 
              pageHeightMM * PdfPageFormat.mm, 
              marginAll: 0.0 * PdfPageFormat.cm
            ),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Stack(
                  children: [
                    pw.Positioned(
                      top: 0,
                      left: 0,
                      child: svgImage
                    ),
                    pw.Positioned(
                      top: 0,
                      left: 0,
                      child: pw.CustomPaint(
                        size: PdfPoint(pageWidthMM * PdfPageFormat.mm, pageHeightMM * PdfPageFormat.mm), 
                        painter: (canvas, size) {
                          canvas.setStrokeColor(PdfColors.grey300);
                          canvas.setLineWidth(0.5);
                          canvas.setColor(PdfColors.deepOrange);
                          canvas.setLineDashPattern([3, 2]);

                          double offset = (pageOverlapBorderCM / 2) * PdfPageFormat.cm;
                          
                          // bottom
                          canvas.drawLine(
                            0.0, offset, 
                            pageWidthMM * PdfPageFormat.mm, offset);

                          // top
                          canvas.drawLine(
                            0.0, (pageHeightMM * PdfPageFormat.mm) - offset, 
                            pageWidthMM * PdfPageFormat.mm, (pageHeightMM * PdfPageFormat.mm) - offset);
                          
                          // left
                          canvas.drawLine(
                            offset, 0.0, 
                            offset, pageHeightMM * PdfPageFormat.mm);

                          // right
                          canvas.drawLine(
                            (pageWidthMM * PdfPageFormat.mm) - offset, 0.0, 
                            (pageWidthMM * PdfPageFormat.mm) - offset, pageHeightMM * PdfPageFormat.mm);

                          canvas.strokePath();
                        },
                      ),
                    ),
                    pw.Positioned(
                      top: ((pageHeightMM * PdfPageFormat.mm) / 2) - ((fontSize / 2) * PdfPageFormat.dp),
                      left: ((pageWidthMM * PdfPageFormat.mm) / 2) - ((fontSize / 2) * PdfPageFormat.dp),
                      child: pw.Center(
                        child: pw.Text(
                          pageNumberString,
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: fontSize,
                          )
                        )
                      ),
                    ),
                  ]
                ),
              );
            }
          )
        );
      }
      pageOffset = pageOffset.translate(-pageOffset.dx, pageHeightMM - pageOverlapBorderMM);
    }

    final file = File(outputFile);
    await file.writeAsBytes(await pdf.save());

  }

}