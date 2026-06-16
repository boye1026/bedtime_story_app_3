import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/info_setup_page.dart';
import 'pages/story_display_page.dart';
import 'pages/story_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/membership_page.dart';
import 'models/child_info.dart';

void main() {
  runApp(const BedtimeStoryApp());
}

class BedtimeStoryApp extends StatelessWidget {
  const BedtimeStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI睡前故事',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        fontFamily: 'Default',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: AppColors.cardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/setup': (context) => const InfoSetupPage(),
        '/stories': (context) => const StoryListPage(),
        '/profile': (context) => const ProfilePage(),
        '/membership': (context) => const MembershipPage(),
      },
      onGenerateRoute: (settings) {
        // 处理 story-display 路由，传递 ChildInfo 参数
        if (settings.name == '/story-display') {
          final args = settings.arguments;
          if (args is ChildInfo) {
            return MaterialPageRoute(
              builder: (context) => StoryDisplayPage(childInfo: args),
            );
          } else if (args is Map) {
            // 也支持传递 Map 形式的参数
            final title = args['title'] as String? ?? '故事';
            final content = args['content'] as String? ?? '';
            return MaterialPageRoute(
              builder: (context) => StoryDisplayPage(
                storyTitle: title,
                storyContent: content,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
