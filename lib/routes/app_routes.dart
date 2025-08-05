import 'package:flutter/material.dart';

import '../views/intro2_screen.dart';
import '../views/intro_screen.dart';
import '../views/register_screen.dart';
import '../views/start_screen.dart';
class AppRoutes {
  static const String intro = '/';
  static const String intro2 = '/intro2';
  static const String startscreen = '/startscreen';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String journal = '/journal';
  static const String suggestion = '/suggestion';
  static const String stats = '/stats';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
        case intro:
          return MaterialPageRoute(builder: (_) => const IntroScreen());
        case intro2:
          return MaterialPageRoute(builder: (_) => const Intro2Screen());
        case startscreen:
          return MaterialPageRoute(builder: (_) => const StartScreen());
        // case login:
        //   return MaterialPageRoute(builder: (_) => const LoginScreen());
        case register:
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
    // case home:
      //   return MaterialPageRoute(builder: (_) => const HomeScreen());
      // case journal:
      //   return MaterialPageRoute(builder: (_) => const JournalScreen());
      // case suggestion:
      //   return MaterialPageRoute(builder: (_) => const SuggestionScreen());
      // case stats:
      //   return MaterialPageRoute(builder: (_) => const StatsScreen());
      // case profile:
      //   return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Không tìm thấy trang')),
          ),
        );
    }
  }
}
