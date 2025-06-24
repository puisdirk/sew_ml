import 'package:flutter/material.dart';
import 'package:sew_ml/service/page_layout.dart';
import 'package:sew_ml/service/settings_service.dart';

class PageLayoutService {

  PageLayoutService._privateConstructor();
  static final PageLayoutService _instance = PageLayoutService._privateConstructor();
  factory PageLayoutService() => _instance;

  Future<PageLayout> getPageLayout() async {
    String pageSizeName = await SettingsService().readSetting(SewMLSetting.printPageSize);
    String pageOrientationName = await SettingsService().readSetting(SewMLSetting.printPageOrientation);
    return PageLayout(
      pageSize: PrintPageSize.values.singleWhere((s) => s.name == pageSizeName), 
      pageOrientation: PrintPageOrientation.values.singleWhere((o) => o.name == pageOrientationName)
    );
  }

  Offset getDimensionsForLayout(PageLayout layout) {
    switch (layout.pageSize) {
      case PrintPageSize.a4:
        return layout.pageOrientation == PrintPageOrientation.portrait ? const Offset(210, 297) : const Offset(297, 210);
      case PrintPageSize.a3:
        return layout.pageOrientation == PrintPageOrientation.portrait ? const Offset(297, 420) : const Offset(420, 297);
      case PrintPageSize.a2:
        return layout.pageOrientation == PrintPageOrientation.portrait ? const Offset(420, 594) : const Offset(594, 420);
      case PrintPageSize.a1:
        return layout.pageOrientation == PrintPageOrientation.portrait ? const Offset(594, 841) : const Offset(841, 594);
      case PrintPageSize.a0:
        return layout.pageOrientation == PrintPageOrientation.portrait ? const Offset(841, 1189) : const Offset(1189, 841);
    }    
  }
}