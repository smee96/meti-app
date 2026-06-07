import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/email_verification_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/main_screen.dart';
import '../features/intro/screens/intro_screen.dart';
import '../features/points/screens/point_screen.dart';
import '../features/invite/screens/invite_join_screen.dart';
import '../features/upgrade/screens/upgrade_screen.dart';
import '../features/guardians/screens/guardians_screen.dart';
import '../features/schedules/screens/lesson_schedules_screen.dart';
import '../features/schedules/screens/schedule_detail_screen.dart';
import '../features/schedules/models/schedule_model.dart';
import '../features/cards/screens/public_card_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String intro = '/intro';
  static const String main = '/main';

  // Cards
  static const String cardList = '/cards';
  static const String cardCreate = '/cards/create';
  static const String cardDetail = '/cards/detail';
  static const String cardEdit = '/cards/edit';
  static const String qrShow = '/qr/show';
  static const String qrScan = '/qr/scan';
  static const String contacts = '/contacts';

  // Groups
  static const String groupList = '/groups';
  static const String groupDetail = '/groups/detail';
  static const String groupCreate = '/groups/create';

  // Events
  static const String eventList = '/events';
  static const String eventDetail = '/events/detail';

  // Chat
  static const String chatList = '/chat';
  static const String chatRoom = '/chat/room';

  // My
  static const String myProfile = '/my/profile';
  static const String myReward = '/my/reward';
  static const String myPoints = '/my/points';

  // Invite deep-link
  static const String inviteJoin = '/invite';

  // Guardians
  static const String guardians = '/guardians';

  // Schedules
  static const String lessonSchedules = '/schedules';
  static const String scheduleDetail = '/schedules/detail';

  // Upgrade
  static const String upgrade = '/upgrade';

  // Public card viewer (QR 스캔 결과 / 딥링크)
  static const String publicCard = '/cards/public';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _slide(const SplashScreen(), settings);
      case login:
        return _fade(const LoginScreen(), settings);
      case register:
        return _slide(const RegisterScreen(), settings);
      case emailVerification:
        return _slide(const EmailVerificationScreen(), settings);
      case forgotPassword:
        return _slide(const ForgotPasswordScreen(), settings);
      case intro:
        return _slide(const IntroScreen(), settings);
      case main:
        return _fade(const MainScreen(), settings);
      case myPoints:
        return _slide(const PointScreen(), settings);
      case inviteJoin:
        // arguments: {'token': String}
        final args = settings.arguments as Map<String, dynamic>?;
        final token = args?['token'] as String? ?? '';
        return _slide(InviteJoinScreen(token: token), settings);
      case guardians:
        return _slide(const GuardiansScreen(), settings);
      case lessonSchedules:
        // arguments: {'group_id': int, 'group_name': String}
        final lsArgs = settings.arguments as Map<String, dynamic>?;
        final groupId = lsArgs?['group_id'] as int? ?? 0;
        final groupName = lsArgs?['group_name'] as String? ?? '레슨 일정';
        return _slide(
            LessonSchedulesScreen(groupId: groupId, groupName: groupName),
            settings);
      case scheduleDetail:
        // arguments: {'schedule': LessonSchedule}
        final sdArgs = settings.arguments as Map<String, dynamic>?;
        final schedule = sdArgs?['schedule'] as LessonSchedule?;
        if (schedule == null) {
          return _fade(
            const Scaffold(
                body: Center(child: Text('일정 정보가 없습니다.'))),
            settings,
          );
        }
        return _slide(ScheduleDetailScreen(schedule: schedule), settings);
      case publicCard:
        // arguments: {'card_id': int}
        final pcArgs = settings.arguments as Map<String, dynamic>?;
        final cardId = pcArgs?['card_id'] as int? ?? 0;
        return _slide(PublicCardScreen(cardId: cardId), settings);
      case upgrade:
        // arguments: {'fromContext': String?}
        final upgradeArgs = settings.arguments as Map<String, dynamic>?;
        final fromCtx = upgradeArgs?['fromContext'] as String?;
        return _slide(UpgradeScreen(fromContext: fromCtx), settings);
      default:
        return _fade(
          Scaffold(
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static PageRoute _slide(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  static PageRoute _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
