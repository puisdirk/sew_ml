
import 'package:flutter/material.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:sew_ml/service/settings_service.dart';

class PrintSettingsView extends StatefulWidget {
  
  const PrintSettingsView({
    super.key
  });

  @override
  State<PrintSettingsView> createState() => _PrintSettingsViewState();
}

class _PrintSettingsViewState extends State<PrintSettingsView> {

  String selectedPageSize = PrintPageSize.a4.name;
  String selectedPageOrientation = PrintPageOrientation.portrait.name;

  Future<void> _initState() async {
    String pageSize = await SettingsService().readSetting(SewMLSetting.printPageSize);
    String pageOrientation = await SettingsService().readSetting(SewMLSetting.printPageOrientation);
    setState(() {
      selectedPageSize = pageSize;
      selectedPageOrientation = pageOrientation;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      borderOnForeground: false,
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Page size: '),
              DropdownMenu(
                dropdownMenuEntries: [
                  for (PrintPageSize pageSize in PrintPageSize.values)
                  DropdownMenuEntry(
                    value: pageSize.name, 
                    label: pageSize.name.toUpperCase()
                  ),
                ],
                initialSelection: selectedPageSize,
                onSelected: (value) async {
                  await SettingsService().writeSetting(SewMLSetting.printPageSize, value!);
                  setState(() {
                    selectedPageSize = value;
                  });
                }
              ),
            ],
          ),
          Row(
            children: [
              const Text('Orientation: '),
              Radio<String>(
                value: PrintPageOrientation.portrait.name, 
                groupValue: selectedPageOrientation, 
                onChanged: (value) async {
                  await SettingsService().writeSetting(SewMLSetting.printPageOrientation, value!);
                  setState(() {
                    selectedPageOrientation = value;
                  });
                }
              ),
              const Icon(Icons.portrait),
              const SizedBox(width: 20,),
              Radio<String>(
                value: PrintPageOrientation.landscape.name, 
                groupValue: selectedPageOrientation, 
                onChanged: (value) async {
                  await SettingsService().writeSetting(SewMLSetting.printPageOrientation, value!);
                  setState(() {
                    selectedPageOrientation = value;
                  });
                }
              ),
              const Icon(Icons.landscape_outlined),
            ],
          )
        ],
      ),
    );
  }
}