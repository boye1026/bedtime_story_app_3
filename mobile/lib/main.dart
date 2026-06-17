import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'pages/home_page.dart';
import 'pages/info_setup_page.dart';
import 'pages/story_display_page.dart';
import 'pages/story_detail_page.dart';
import 'pages/story_library_page.dart';
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
        ),
        useMaterial3: true,
        fontFamily: 'Default',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
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
        '/story-library': (context) => const StoryLibraryPage(),
        '/profile': (context) => const ProfilePage(),
        '/membership': (context) => const MembershipPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/story-display') {
          final dynamic args = settings.arguments;
          if (args is ChildInfo) {
            return MaterialPageRoute(
              builder: (context) => StoryDisplayPage(childInfo: args),
            );
          } else if (args is Map) {
            final dynamic titleRaw = args['title'];
            final String title = titleRaw is String ? titleRaw : '故事';
            final dynamic contentRaw = args['content'];
            final String content = contentRaw is String ? contentRaw : '';
            return MaterialPageRoute(
              builder: (context) => StoryDisplayPage(
                storyTitle: title,
                storyContent: content,
              ),
            );
          }
        }
        if (settings.name == '/story-detail') {
          final dynamic argsRaw = settings.arguments;
          final Map<String, dynamic>? args = argsRaw is Map<String, dynamic> ? argsRaw : null;
          final dynamic titleRaw = args?['title'];
          final dynamic contentRaw = args?['content'];
          final dynamic categoryRaw = args?['category'];
          final dynamic categoryIconRaw = args?['categoryIcon'];
          return MaterialPageRoute(
            builder: (context) => StoryDetailPage(
              title: titleRaw is String ? titleRaw : '故事',
              content: contentRaw is String ? contentRaw : '',
              category: categoryRaw is String ? categoryRaw : '',
              categoryIcon: categoryIconRaw is String ? categoryIconRaw : '📖',
            ),
          );
        }
        return null;
      },
    );
  }
}
