import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/maths_helper.dart';
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/part.dart';
import 'package:sew_ml/ast/part_layout_placement.dart';
import 'package:sew_ml/ast/parts_layout.dart';
import 'package:sew_ml/ast/point.dart';

import 'package:file_picker/file_picker.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';
import 'package:sew_ml/service/svg_info.dart';


class SvgService {

  static Future<void> saveAsSvg(Drawing drawing, [String layoutName = '']) async {

    String initialFileName = layoutName;
    if (initialFileName.isEmpty) {
      initialFileName = 'layout';
    }

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: '$initialFileName.svg',
    );

    if (outputFile == null) {
      return;
    }

    SvgInfo svgInfo = createSVG(drawing);

    final file = File(outputFile);
    file.writeAsStringSync(svgInfo.completeSvg);
  }

  static SvgInfo createSVG(Drawing drawing, {bool drawDebug = false, double border = 0.0}) {
    String childSvg = '';

    Rect completeBounds = const Rect.fromLTWH(0.0, 0.0, 210, 297);
    Rect viewPortBounds = const Rect.fromLTWH(0.0, 0.0, 210, 297);
    if (drawing.hasLayout) {
      // We need the paths as they are before being layout out
      Map<String, Path> paths = drawing.getLayoutPaths(applyFlips: false, applyRotation: false, applyRelativeConstraints: false);
      
      // We need the path boundaries as they are when layed out to do the final translation operations
      Map<String, Path> layoutOutPaths = drawing.getLayoutPaths();

      List<ParserElement> elements = List.from(drawing.elements);

      // Determine the dimensions to be used for the viewport
      completeBounds = drawing.getLayoutBounds().inflate(border);
      viewPortBounds = completeBounds.inflate(border);

      // Wrap with a translation to put the whole drawing at 0,0
      childSvg += '<g transform="translate(${-(completeBounds.left)}, ${-(completeBounds.top)})">';

      PartsLayout layout = drawing.layout;
      for (PartLayoutPlacement placement in layout.placements) {
        
        final Part part = elements.firstWhere((el) => el.label == placement.partName) as Part;
        
        // Center the part at 0.0,0.0
        Rect partBounds = paths[part.label]!.getBounds();
        part.offset(-(partBounds.left + (partBounds.width / 2)), (partBounds.top + (partBounds.height / 2)));

        // debug drawing where the part would be in the original (before layout)
        if (drawDebug) {
          childSvg += '<rect stroke="indigo" stroke-width="1" fill="none" x="${partBounds.left}" y="${partBounds.top}" width="${partBounds.width}" height="${partBounds.height}"/>';
        }

        // We use the layed out piece to translate for relative placements
        Rect layedOutPathBounds = layoutOutPaths[part.label]!.getBounds();

        // debug drawing where the parts would be after applying the layout
        if (drawDebug) {
          childSvg += '<rect stroke="pink" stroke-width="1" fill="none" stroke-dasharray="5 5" x="${layedOutPathBounds.left}" y="${layedOutPathBounds.top}" width="${layedOutPathBounds.width}" height="${layedOutPathBounds.height}"/>';
        }

        // Wrap the part with translation to its final position
        String translationMatrix = 'translate(${layedOutPathBounds.left + (layedOutPathBounds.width / 2)},${layedOutPathBounds.top + (layedOutPathBounds.height / 2)})';
        childSvg += '<g id="${part.label}" stroke-linecap="round" stroke="green" stroke-width="3" fill="none" transform="$translationMatrix">';

        // Wrap the part with flip scaling
        String flipMatrix = '';
        if (placement.flip == Flip.x) {
          flipMatrix += 'scale(1, -1)';
        }
        if (placement.flip == Flip.y) {
          flipMatrix += 'scale(-1, 1)';
        }
        if (placement.flip == Flip.xy) {
          flipMatrix += 'scale(-1, -1)';
        }
        childSvg += '<g transform="$flipMatrix">';

        // Wrap the part with a rotation
        String rotationMatrix = '';
        if (placement.orientationRad != 0.0) {
          rotationMatrix += 'rotate(${MathsHelper.radiansToDegrees(placement.orientationRad)})';
        }
        childSvg += '<g transform="$rotationMatrix">';

        // Draw the part, centered on 0.0,0.0
        childSvg += '<g id="${part.label}" stroke="green" stroke-width="3" fill="none">';
        
        for (ParserElement partElement in part.elements) {
          if (partElement is Point) {
            childSvg += '<circle cx="${partElement.coordinate.x}" cy="${-(partElement.coordinate.y)}" r="2"></circle>';
          } else if (partElement is Line) {
            childSvg += '<line x1="${partElement.startPoint.x}" y1="${-(partElement.startPoint.y)}" x2="${partElement.endPoint.x}" y2="${-(partElement.endPoint.y)}"></line>';
          } else if (partElement is QuadraticBezier) {
            childSvg += '<path d="M${partElement.startPoint.x},${-(partElement.startPoint.y)} Q${partElement.controlPoint.x},${-(partElement.controlPoint.y)} ${partElement.endPoint.x},${-(partElement.endPoint.y)}"/>';
          }
        }
        
        childSvg += '</g>'; // Close part group
        childSvg += '</g>'; // Close the rotation group
        childSvg += '</g>'; // Close the flip scaling group
        childSvg += '</g>'; // Close the final position translation group
      }
    } else {
      // No layout found
      childSvg += '<g fill="red"><text x="25" y="25" font-family="Verdana">Error: no layout defined</text>';
    }

    childSvg += '</g>'; // Close the translation group that puts the whole drawing at 0,0
    
    String svgRaw = '';
    if (drawDebug) {
      svgRaw += '<svg width="${completeBounds.width}mm" height="${completeBounds.height}mm" viewBox="-2000 -2000 4000 4000" xmlns="http://www.w3.org/2000/svg">';
      svgRaw += '<g id="axis">';
      svgRaw += '<line stroke="blue" fill="none" stroke-width="1" x1="-2000" x2="4000" y1="0" y2="0"/>';
      svgRaw += '<line stroke="red" fill="none" stroke-width="1" y1="-2000" y2="4000" x1="0" x2="0"/>';
      svgRaw += '</g>';
    } else {
      svgRaw += '<svg width="${completeBounds.width}mm" height="${completeBounds.height}mm" viewBox="0 0 ${viewPortBounds.width} ${viewPortBounds.height}" xmlns="http://www.w3.org/2000/svg">';
    }

    svgRaw += '$childSvg</svg>';

    return SvgInfo(completeSvg: svgRaw, childSvg: childSvg, width: completeBounds.width, height: completeBounds.height);
  }

}

