import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mind_mare_fe/services/auth_service.dart';
import 'package:mind_mare_fe/view_models/RegisterViewModel.dart';
import 'package:mind_mare_fe/view_models/sign_in_viewmodel.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SignInViewModel(AuthService()),
          ),
          ChangeNotifierProvider(
            create: (_) => RegisterViewModel(),
          ),
        ],
        child: const MindCareApp(),
      )
  );
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
