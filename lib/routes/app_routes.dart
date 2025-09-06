import 'package:flutter/material.dart';
import '../views/forgot_password.dart';
import '../views/main_screen/CameraAI.dart';
import '../views/main_screen/NewDiaryPage.dart';
import '../views/main_screen/home.dart';
import '../views/intro2_screen.dart';
import '../views/intro_screen.dart';
import '../views/main_screen/ChatAI.dart';
import '../views/main_screen/EditProfileScreen.dart';
import '../views/register_screen.dart';
import '../views/register_success_screen.dart';
import '../views/reset_password_screen.dart';
import '../views/signin_screen.dart';
import '../views/start_screen.dart';

class AppRoutes {
  static const String intro = '/';
  static const String intro2 = '/intro2';
  static const String startscreen = '/startscreen';
  static const String signinscreen = '/signinscreen';
  static const String registersuccessscreen = '/registersuccessscreen';
  static const String register = '/register';
  static const String home = '/home';
  static const String forgotpassword = '/forgotpassword';
  static const String resetsuccess = '/resetsuccess';
  static const String journal = '/journal';
  static const String suggestion = '/suggestion';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String editprofile = '/editProfile';
  static const String AIchatRoom = '/aichatroom';
  static const String newDiaryPage = '/newDiaryPage';
  static const String cameraAI = '/cameraAI';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case intro:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case intro2:
        return MaterialPageRoute(builder: (_) => const Intro2Screen());
      case startscreen:
        return MaterialPageRoute(builder: (_) => const StartScreen());
      case signinscreen:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case registersuccessscreen:
        return MaterialPageRoute(builder: (_) => const RegisterSuccessScreen());
      case forgotpassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetsuccess:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (_) => MindCareHomePage());
      case editprofile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case AIchatRoom:
        return MaterialPageRoute(builder: (_) => const AichatRoom());
      case newDiaryPage:
        return MaterialPageRoute(builder: (_) => const NewDiaryPage());
      case cameraAI:
        return MaterialPageRoute(builder: (_) => const CameraAIPage());
      default:
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(child: Text('Không tìm thấy trang')),
              ),
        );
    }
  }
}
