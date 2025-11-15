import 'package:flutter/material.dart';
import 'package:open_dir/open_dir.dart';
import 'package:re_editor/re_editor.dart';
import 'package:sew_ml/service/templates_service.dart';

class ManageTemplatesView extends StatefulWidget {
  const ManageTemplatesView({super.key});

  @override
  State<ManageTemplatesView> createState() => _ManageTemplatesViewState();
}

class _ManageTemplatesViewState extends State<ManageTemplatesView> {
  late CodeLineEditingController controller;
  String selectedTemplateName = '';

  @override
  void initState() {
    controller = CodeLineEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _showConfirmDeleteDialog(BuildContext context, String templateName) {
    return showAdaptiveDialog(
      context: context, 
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Are you sure?'),
          content: Text('This will permanently delete template $templateName. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              }, 
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await TemplatesService().deleteTemplate(templateName);
                setState(() {
                  selectedTemplateName = '';
                  controller.text = '';
                });
              }, 
              child: const Text('Delete')
            ),

          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                SizedBox(
                  width: screenSize.width / 3,
                  height: screenSize.height * 0.75,
                  child: 
                  (TemplatesService().templateNames.isEmpty) ?
                    const Center(child: Text('No templates found'))
                  :
                  ListView(
                    padding: const EdgeInsets.all(5),
                    children: [
                      for (String templateName in TemplatesService().templateNames)
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          mouseCursor: SystemMouseCursors.click,
                          onTap: () => setState(() {
                            selectedTemplateName = templateName;
                            if (selectedTemplateName.isNotEmpty) {
                              controller.text = TemplatesService().getTemplate(selectedTemplateName).subCommands.join('\n');
                            }
                          }),
                          tileColor: templateName == selectedTemplateName ? Colors.amber.shade100 : null,
                          title: Text(templateName),
                          trailing: IconButton(
                            onPressed: () async => await _showConfirmDeleteDialog(context, templateName), 
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ),
                    ],
                  ),
                )
              ]
            ),
            Column(
              children: [
                SizedBox(
                  width: screenSize.width / 3,
                  height: screenSize.height * 0.75,
                  child: CodeEditor(
                    readOnly: true,
                    border: Border.all(color: Colors.grey.shade200),
                    controller: controller,
                  ),
                )
              ],
            )
          ],
        ),
        const SizedBox(height: 20,),
        Row(
          children: [
            const Text('Template directory: '),
            FutureBuilder<String>(
              future: TemplatesService().currentDirectory,
              builder: (context, snapshot) => Text(snapshot.data ?? '')
            ),
            const SizedBox(width: 20,),
            /*TextButton(
              onPressed: () async {
                await TemplatesService().changeTemplateDirectory();
                setState(() {
                  selectedTemplateName = '';
                });
              }, 
              child: const Text('Change')
            )*/
            IconButton(
              onPressed: () async {
                final opendirPlugin = OpenDir();
                await opendirPlugin.openNativeDir(path: await TemplatesService().currentDirectory);
              },
              icon: const Icon(Icons.open_in_new),
            )
          ],
        )
      ],
    ); 
  }
}