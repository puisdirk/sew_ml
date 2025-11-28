import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sew_ml/ast/samples/aldrich_classic_shirt.dart';
import 'package:sew_ml/ast/samples/aldrich_classic_shirt_sleeve.dart';
import 'package:sew_ml/ast/sub_commands_group.dart';
import 'package:sew_ml/service/settings_service.dart';
import 'package:simple_platform/simple_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemplatesService {

  TemplatesService._privateConstructor();
  static final TemplatesService _instance = TemplatesService._privateConstructor();
  factory TemplatesService() => _instance;
  final JsonCodec _codec = json;

  String? _templatesDirectoryPath;
  final Map<String, SubCommandsGroup> _templates = {};
  bool directoryDirty = true;

  Future<void> initTemplates() async {

    if (AppPlatform.isWeb) {
      if (_templates.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final String? jsonString = prefs.getString('templates');
        if (jsonString != null) {
          final Map<String, dynamic> jsonObject = jsonDecode(jsonString);
          if (jsonObject.containsKey('templates')) {
            List<Map<String, dynamic>> templatesObject = (jsonObject['templates'] as List).map((e) => e as Map<String, dynamic>).toList();
            for(Map<String, dynamic> templateObject in templatesObject) {
              final subcommandsGroup = SubCommandsGroup.fromJson(templateObject);
              _templates[subcommandsGroup.label] = subcommandsGroup;
            }
          }
        }

        await _createDefaultTemplates();
      }
    } else {
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
  }

  Future<void> _storeTemplates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, Object> jsonObject = {'templates': _templates.values.map((template) => template.toJson()).toList()};
    try {
      String jsonString = _codec.encode(jsonObject);
      prefs.setString('templates', jsonString);
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _createDefaultTemplates() async {
    final AldrichClassicShirt bodice = AldrichClassicShirt();
    if (!_templates.containsKey(bodice.label)) {
      _templates[bodice.label] = bodice;
      if (AppPlatform.isWeb) {
        _storeTemplates();
      } else {
        File bodiceFile = File('$_templatesDirectoryPath/${bodice.label}.smlt');
        if (!bodiceFile.existsSync()) {
          bodiceFile.writeAsStringSync(bodice.subCommands.join('\n'));
        }
      }
    }

    final AldrichClassicShirtSleeve sleeve = AldrichClassicShirtSleeve();
    if (!_templates.containsKey(sleeve.label)) {
      _templates[sleeve.label] = sleeve;
      if (AppPlatform.isWeb) {
        _storeTemplates();
      } else {
        File sleeveFile = File('$_templatesDirectoryPath/${sleeve.label}.smlt');
        if (!sleeveFile.existsSync()) {
          sleeveFile.writeAsStringSync(sleeve.subCommands.join('\n'));
        }
      }
    }
  }

  Future<void> changeTemplateDirectory({bool copyExisting = false}) async {
    if (AppPlatform.isWeb) {
      return;
    }

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
      await initTemplates();
    }
  }

  Future<void> saveAsTemplate(String templateName, String commandsText) async {
    await initTemplates();

    _templates[templateName] = SubCommandsGroup(label: templateName, subCommands: commandsText.split('\n'));

    if (AppPlatform.isWeb) {
      _storeTemplates();
    } else {
      String templateFileName = templateName;
      if (!templateFileName.endsWith('.smlt')) {
        templateFileName += '.smlt';
      }
      final file = File('$_templatesDirectoryPath${Platform.pathSeparator}$templateFileName');
      await file.writeAsString(commandsText);
    }
  }

  List<String> get templateNames => _templates.keys.toList();
  SubCommandsGroup getTemplate(String name) => _templates[name]!;
  Future<String> get currentDirectory async => _templatesDirectoryPath ?? await SettingsService().readSetting(SewMLSetting.templatesDirectory);
  
  Future<void> deleteTemplate(String templateName) async {
    await initTemplates();

    _templates.remove(templateName);

    if (AppPlatform.isWeb) {
      _storeTemplates();
    } else {
      final File file = File('$_templatesDirectoryPath${Platform.pathSeparator}$templateName.smlt');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}

