import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:sew_ml/ast/samples/aldrich_classic_bodice.dart';
import 'package:sew_ml/ast/sub_commands_group.dart';
import 'package:sew_ml/service/settings_service.dart';

class TemplatesService {

  TemplatesService._privateConstructor();
  static final TemplatesService _instance = TemplatesService._privateConstructor();
  factory TemplatesService() => _instance;

  String? _templatesDirectoryPath;
  final Map<String, SubCommandsGroup> _templates = {};
  bool directoryDirty = true;

  Future<void> _initTemplatesDirectoryPath() async {
    _templatesDirectoryPath = _templatesDirectoryPath ?? await SettingsService().readSetting(SewMLSetting.templatesDirectory);

    Directory templatesDirectory = Directory(_templatesDirectoryPath!);
    if (!templatesDirectory.existsSync()) {
      await templatesDirectory.create();

      await _createDefaultTemplates();

      directoryDirty = true;
    }

    if (directoryDirty) {
      _templates.clear();
      List<FileSystemEntity> fileEnts = templatesDirectory.listSync();
      for (FileSystemEntity fileEnt in fileEnts) {
        FileStat stat = fileEnt.statSync();
        String filename = fileEnt.path.split(Platform.pathSeparator).last;
        if (stat.type == FileSystemEntityType.file && filename.endsWith('.smlt')) {
          File file = File(fileEnt.path);
          String templateName = filename.substring(0, filename.length - '.smlt'.length);
          List<String> subCommands = file.readAsLinesSync();
          _templates[templateName] = SubCommandsGroup(label: templateName, subCommands: subCommands);
        }
      }
      directoryDirty = false;
    }
  }

  Future<void> _createDefaultTemplates() async {
    final AldrichClassicBodice bodice = AldrichClassicBodice();
    File bodiceFile = File('$_templatesDirectoryPath/${bodice.label}.smlt');
    if (!bodiceFile.existsSync()) {
      bodiceFile.writeAsStringSync(bodice.subCommands.join('\n'));
    }
  }

  Future<void> changeTemplateDirectory({bool copyExisting = false}) async {
    String? newPath = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose a new Template directory', initialDirectory: _templatesDirectoryPath);
    if (newPath != null) {
      Directory newDirectory = Directory(newPath);
      if (!newDirectory.existsSync()) {
        newDirectory.createSync(recursive: true);
      }
      if (copyExisting && _templates.isNotEmpty) {
        for (String templateName in _templates.keys) {
          final currentFile = File('$_templatesDirectoryPath${Platform.pathSeparator}$templateName.smlt');
          if (currentFile.existsSync()) {
            currentFile.copySync('$newPath${Platform.pathSeparator}$templateName.smlt}');
          }
        }        
      }
      await SettingsService().writeSetting(SewMLSetting.templatesDirectory, newPath);
      _templatesDirectoryPath = newPath;
      directoryDirty = true;
      await _initTemplatesDirectoryPath();
    }
  }

  Future<void> saveAsTemplate(String templateName, String commandsText) async {
    await _initTemplatesDirectoryPath();

    String templateFileName = templateName;
    if (!templateFileName.endsWith('.smlt')) {
      templateFileName += '.smlt';
    }
    final file = File('$_templatesDirectoryPath${Platform.pathSeparator}$templateFileName');
    await file.writeAsString(commandsText);
    _templates[templateName] = SubCommandsGroup(label: templateName, subCommands: commandsText.split('\n'));
  }

  List<String> get templateNames => _templates.keys.toList();
  SubCommandsGroup getTemplate(String name) => _templates[name]!;
  Future<String> get currentDirectory async => _templatesDirectoryPath ?? await SettingsService().readSetting(SewMLSetting.templatesDirectory);
  
  Future<void> deleteTemplate(String templateName) async {
    await _initTemplatesDirectoryPath();

    final File file = File('$_templatesDirectoryPath${Platform.pathSeparator}$templateName.smlt');

    _templates.remove(templateName);

    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

