# Flutter 默认规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio HTTP 客户端
-keep class com.dio.** { *; }
-dontwarn com.dio.**

# SharedPreferences
-keep class androidx.** { *; }

# flutter_tts
-keep class com.tundralabs.** { *; }
-keep class io.github.davesters.** { *; }

# Google Play Core (Flutter 延迟组件)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.app.FlutterPlayStoreSplitApplication.** { *; }
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication.**
