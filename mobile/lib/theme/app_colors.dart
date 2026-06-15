import 'package:flutter/material.dart';

/// 应用色彩常量
/// 定义了整个应用的配色方案，采用柔和童趣风格
class AppColors {
  AppColors._(); // 私有构造函数，防止实例化

  // ========== 主色调 ==========
  /// 主色 - 梦幻紫
  static const Color primary = Color(0xFF6C63FF);

  /// 辅色 - 粉色
  static const Color secondary = Color(0xFFFF6B9D);

  /// 强调色 - 暖黄
  static const Color accent = Color(0xFFFFD93D);

  // ========== 背景色 ==========
  /// 主背景色 - 暖白
  static const Color background = Color(0xFFFFF8F0);

  /// 卡片背景色 - 纯白
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// 次级背景色 - 浅紫
  static const Color secondaryBackground = Color(0xFFF0EEFF);

  // ========== 文字色 ==========
  /// 主文字色 - 深灰
  static const Color textPrimary = Color(0xFF2D3436);

  /// 次要文字色
  static const Color textSecondary = Color(0xFF636E72);

  /// 提示文字色 - 浅灰
  static const Color textHint = Color(0xFFB2BEC3);

  // ========== 功能色 ==========
  /// 成功色 - 绿色
  static const Color success = Color(0xFF00B894);

  /// 警告色 - 橙色
  static const Color warning = Color(0xFFFDCB6E);

  /// 错误色 - 红色
  static const Color error = Color(0xFFFF7675);

  /// 收藏爱心色
  static const Color favorite = Color(0xFFFF6B6B);

  // ========== 渐变色 ==========
  /// 主按钮渐变 - 紫到粉
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 背景渐变 - 深紫到浅紫
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 暖色渐变 - 黄到橙
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== 阴影 ==========
  /// 卡片阴影
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// 按钮阴影
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
