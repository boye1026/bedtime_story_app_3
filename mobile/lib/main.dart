import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/info_setup_page.dart';
import 'pages/story_generate_page.dart';
import 'pages/story_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/membership_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI睡前故事',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/setup': (context) => const InfoSetupPage(),
        '/generate': (context) => const StoryGeneratePage(),
        '/stories': (context) => const StoryListPage(),
        '/profile': (context) => const ProfilePage(),
        '/membership': (context) => const MembershipPage(),
      },
    );
  }
}
