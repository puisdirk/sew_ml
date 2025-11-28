import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/ast/drawing.dart';
import 'package:sew_ml/ast/elements_and_errors.dart';
import 'package:sew_ml/controls/drawing_control.dart';
import 'package:sew_ml/controls/layout_control.dart';
import 'package:sew_ml/controls/manage_templates_view.dart';
import 'package:sew_ml/controls/print_settings_view.dart';
import 'package:sew_ml/controls/save_from_web_view.dart';
import 'package:sew_ml/controls/syntax_error_indicator.dart';
import 'package:sew_ml/controls/valid_line_indicator.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:sew_ml/service/page_layout_service.dart';
import 'package:sew_ml/service/pdf_service.dart';
import 'package:sew_ml/service/svg_service.dart';
import 'package:sew_ml/service/templates_service.dart';
import 'package:simple_platform/simple_platform.dart';

class DrawingView extends StatefulWidget {
  const DrawingView({
    super.key
  });

  @override
  State<DrawingView> createState() => _DrawingViewState();
}

class _DrawingViewState extends State<DrawingView> {
  String commandsText = '';
  List<String> commands = [];
  late CodeLineEditingController controller;
  int maxValidLineNumber = -1;
  late TextEditingController _templateNameTextController;
  late Drawing _drawing;

  // Showing errors
  OverlayEntry? errorOverlay;

  @override
  void initState() {
    controller = CodeLineEditingController.fromText(commandsText);
    _templateNameTextController = TextEditingController();
    _drawing = Drawing(ElementsAndErrors());
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    _templateNameTextController.dispose();
    super.dispose();
  }

  void _showErrorOverlay(BuildContext context, Offset errorOffset, String errorMessage) {
    OverlayState overlayState = Overlay.of(context);
    
    _hideErrorOverlay();

    errorOverlay = OverlayEntry(builder: (context) {
      return Positioned(
        top: errorOffset.dy, 
        left: errorOffset.dx, 
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.red.shade100, 
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.red.shade500)
          ),
          child: Text(errorMessage, 
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              decorationStyle: TextDecorationStyle.solid,
              decoration: TextDecoration.none,
              color: Colors.grey.shade800, 
            ),
          ),
        )
      );
    });

    overlayState.insert(errorOverlay!);
  }

  void _hideErrorOverlay() {
    if (errorOverlay != null && errorOverlay!.mounted) {
      errorOverlay?.remove();
    }
  }

  Future<void> _showPrintOptionsDialog(BuildContext context) async {
    return showAdaptiveDialog(
      context: context, 
      builder: (context) {
        return AlertDialog.adaptive(
          contentPadding: const EdgeInsets.all(10.0),
          title: const Text('Print layout'),
          content: const PrintSettingsView(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => commands = commandsText.split('\n'));
              },
              child: const Text('Close')
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTemplatesDialog(BuildContext context) async {
    TemplatesService().initTemplates();
    return showAdaptiveDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Manage Templates'),
          content: const ManageTemplatesView(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Close'),
            )
          ],
        );
      }
    );
  }

  Future<void> _showSaveAsPdfDialog(BuildContext context) async {
    return showAdaptiveDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as Pdf'),
          content: SaveFromWebView(drawing: _drawing, asSvg: false,),
        );
      }
    );
  }

  Future<void> _showSaveAsSvgDialog(BuildContext context) async {
    return showAdaptiveDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as SVG'),
          content: SaveFromWebView(drawing: _drawing, asSvg: true,),
        );
      }
    );
  }

  Future<String?> _getTemplateName(BuildContext context) async {
    return showAdaptiveDialog<String>(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as template'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Template name'),
            controller: _templateNameTextController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _templateNameTextController.clear();
              },
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_templateNameTextController.text);
                _templateNameTextController.clear();
              }, 
              child: const Text('OK')
            ),
          ],
        );
      },
    );
  }

  void _updateDrawing() {
    List<String> validCommands = List.from(commands);
    if (maxValidLineNumber != -1) {
      validCommands = validCommands.sublist(0, maxValidLineNumber);
    }
    //Drawing syntaxDrawing = Drawing.checkSyntax(validCommands);
    setState(() {
      _drawing = Drawing.parse(validCommands);
    });    
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Center(
      child: Row(
        children: [
          Column(
            children: [
              const SizedBox(height: 10,),
              Row(
                children: [
                  const SizedBox(width: 20,),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      commands = commandsText.split('\n');
                      _updateDrawing();
                    }), 
                    label: const Text('Parse'),
                    icon: const Icon(Icons.play_circle_fill_rounded)
                  ),
                  const SizedBox(width: 20,),
                  OutlinedButton(
                    onPressed: () async {
                      String? templateName = await _getTemplateName(context);
                      if (templateName != null && templateName.isNotEmpty) {
                        await TemplatesService().saveAsTemplate(templateName, commandsText);
//                        setState(() => controller.text = 'exec $templateName' );
                      }
                    }, 
                    child: const Text('Save as template')
                  ),
                  const SizedBox(width: 20,),
                  OutlinedButton(
                    onPressed: () async {
                      await _showTemplatesDialog(context);
                    },
                    child: const Text('Manage Templates')
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              SizedBox(
                width: screenSize.width / 3,
                height: screenSize.height * 0.9,
                child: CodeEditor(
                  controller: controller,
                  onChanged: (CodeLineEditingValue cev) => setState(() {
                    commandsText = controller.text;
                  }),
                  indicatorBuilder: (context, editingController, chunkController, notifier) {
                    return Row(
                      children: [
                        ValidLineIndicator(
                          controller: editingController,
                          notifier: notifier,
                          width: 20,
                          maxValidLineNumber: maxValidLineNumber,
                          onSelection: (int newMaxValidLineNumber) => setState(() {
                            maxValidLineNumber = newMaxValidLineNumber;
                            _updateDrawing();
                          })
                        ),
                        DefaultCodeLineNumber(
                          controller: editingController,
                          notifier: notifier,
                        ),
                        SyntaxErrorIndicator(
                          controller: editingController,
                          notifier: notifier,
                          width: 20,
                          drawing: _drawing,
                          onShowError: (errorPosition, errorMessage) {
                            if (errorPosition == Offset.zero || errorMessage.isEmpty) {
                              _hideErrorOverlay();
                            } else {
                              _showErrorOverlay(context, errorPosition, errorMessage);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 20,),
          Column(
            children: [
              InteractiveViewer(child: DrawingControl(drawing: _drawing)),
              InteractiveViewer(child: LayoutControl(drawing: _drawing)),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      _updateDrawing();
                      if (!AppPlatform.isWeb) {
                        await SvgService.saveAsSvg(_drawing);
                      } else if (context.mounted) {
                        await _showSaveAsSvgDialog(context);
                      }
                    },
                    child: const Text('Export to SVG'),
                  ),
                  const SizedBox(width: 20,),
                  OutlinedButton(
                    onPressed: () async {
                      PageLayout layout = await PageLayoutService().getPageLayout();
                      Offset pageSizeMM = PageLayoutService().getDimensionsForLayout(layout);
                      _updateDrawing();
                      if (!AppPlatform.isWeb) {
                        await PdfService.saveAsPdf(_drawing, pageWidthMM: pageSizeMM.dx, pageHeightMM: pageSizeMM.dy);
                      } else if (context.mounted) {
                        await _showSaveAsPdfDialog(context);
                      }
                    },
                    child: const Text('Export to PDF'),
                  ),
                  const SizedBox(width: 20,),
                  IconButton(
                    onPressed: () async {
                      await _showPrintOptionsDialog(context);
                    },
                    icon: const Icon(Icons.print_outlined)
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}