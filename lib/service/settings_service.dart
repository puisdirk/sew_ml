
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:simple_platform/simple_platform.dart';

enum SewMLSetting {
  templatesDirectory,
  printPageSize,
  printPageOrientation,
}

class SettingsService {

  SettingsService._privateConstructor();
  static final SettingsService _instance = SettingsService._privateConstructor();
  factory SettingsService() => _instance;

  String? _appDirectoryPath;
  final Map<String, String> _settings = {};

  Future<void> _initAppDirectoryPath() async {
    if (_appDirectoryPath == null && !AppPlatform.isWeb) {
      Directory dir = await getApplicationDocumentsDirectory();
      _appDirectoryPath = dir.path;
    }
  }

  String _createDefaultSettings() => 
    '''
${SewMLSetting.templatesDirectory.name}=$_appDirectoryPath${Platform.pathSeparator}templates
${SewMLSetting.printPageSize.name}=${PrintPageSize.a4.name}
${SewMLSetting.printPageOrientation.name}=${PrintPageOrientation.portrait.name}
''';

  Future<void> _initSettings() async {
    await _initAppDirectoryPath();

    if (AppPlatform.isWeb) {
      _settings[SewMLSetting.templatesDirectory.name] = '';
      _settings[SewMLSetting.printPageSize.name] = PrintPageSize.a4.name;
      _settings[SewMLSetting.printPageOrientation.name] = PrintPageOrientation.portrait.name;
    } else {
      File settingsFile = File('$_appDirectoryPath/sew_ml_settings.txt');

  /*
      if (settingsFile.existsSync()) {
        settingsFile.deleteSync();
      }
  */
      if (!settingsFile.existsSync()) {
        String defaults = _createDefaultSettings();
        settingsFile.writeAsStringSync(defaults);
      }

      List<String> settingsLines = settingsFile.readAsLinesSync();

      for (String settingsLine in settingsLines) {
        if (settingsLine.isNotEmpty) {
          List<String> settingPair = settingsLine.split('=');
          if (settingPair.length != 2) {
            throw Exception('Settings file contains line $settingsLine with invalid format');
          }
          _settings[settingPair[0]] = settingPair[1];
        }
      }
    }
  }

  Future<String> readSetting(SewMLSetting setting) async {
    await _initSettings();

    if (!_settings.containsKey(setting.name)) {
      throw Exception('Request for non-existing setting ${setting.name}');
    }
    return _settings[setting.name]!;
  }

  Future<void> writeSetting(SewMLSetting setting, String value) async {
    _settings[setting.name] = value;
    if (!AppPlatform.isWeb) {
      await _writeSettingsToFile();
    } else {
      // write to something??
    }
  }

  Future<void> _writeSettingsToFile() async {
    List<String> settingsLines = [];

    for (MapEntry<String, String> entry in _settings.entries) {
      settingsLines.add('${entry.key}=${entry.value}');
    }

    File settingsFile = File('$_appDirectoryPath/sew_ml_settings.txt');
    settingsFile.writeAsStringSync(settingsLines.join('\n'));
  }
}