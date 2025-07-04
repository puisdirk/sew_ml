import 'package:flutter/material.dart';
import 'package:sew_ml/controls/drawing_view.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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
