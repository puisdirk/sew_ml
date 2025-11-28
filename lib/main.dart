import 'package:flutter/material.dart';
import 'package:sew_ml/controls/drawing_view.dart';
import 'package:sew_ml/service/templates_service.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    TemplatesService().initTemplates();

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: DrawingView(),
        ),
      ),
    );
  }
}
