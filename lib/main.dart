import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MindCareApp());
}

class MindCareApp extends StatelessWidget {
  const MindCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCare',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.intro,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
