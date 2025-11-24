
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:sew_ml/service/page_layout_service.dart';
import 'package:sew_ml/service/pdf_service.dart';
import 'package:sew_ml/service/svg_info.dart';
import 'dart:html' show AnchorElement;

import 'package:sew_ml/service/svg_service.dart';

class SaveFromWebView extends StatefulWidget {
  final Drawing drawing;
  final bool asSvg;
  
  const SaveFromWebView({
    required this.drawing,
    required this.asSvg,
    super.key
  });

  @override
  State<SaveFromWebView> createState() => _SaveFromWebViewState();
}

class _SaveFromWebViewState extends State<SaveFromWebView> {

  late TextEditingController _layoutNameController;
  final String _layoutName = 'layout';

  @override
  void initState() {
    _layoutNameController = TextEditingController(text: _layoutName);
    _layoutNameController.selection = TextSelection(baseOffset: 0, extentOffset: _layoutName.length);

    super.initState();
  }

  @override
  void dispose() {
    _layoutNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          TextField(controller: _layoutNameController, autofocus: true,),
          const SizedBox(height: 20,),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(), 
                child: const Text('Cancel')
              ),
              const SizedBox(width: 20,),
              OutlinedButton(
                onPressed: _layoutNameController.text.isEmpty ? null : () async {
                  if (widget.asSvg) {
                    final SvgInfo svgInfo = SvgService.createSVG(widget.drawing);
              
                  AnchorElement()
                      ..href = '${Uri.dataFromString(svgInfo.completeSvg, mimeType: 'image/svg+xml', encoding: utf8)}'
                      ..download = '${_layoutNameController.text}.svg'
                      ..style.display = 'none'
                      ..click();
                  } else {
                    // Pdf
                    PageLayout layout = await PageLayoutService().getPageLayout();
                    Offset pageSizeMM = PageLayoutService().getDimensionsForLayout(layout);
                    
                    Uint8List bytes = await PdfService.getPdfBytes(widget.drawing, layoutName: _layoutNameController.text, pageWidthMM: pageSizeMM.dx, pageHeightMM: pageSizeMM.dy);
              
                    AnchorElement()
                      ..href = '${Uri.dataFromBytes(bytes, mimeType: 'application/pdf')}'
                      ..download = '${_layoutNameController.text}.pdf'
                      ..style.display = 'none'
                      ..click();
                  }
              
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }, 
              child: const Text('Download')),
            ],
          ),
        ],
      ),
    );
  }
}