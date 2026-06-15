import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';
import '../models/user.dart';

/// 本地存储服务
/// 使用SharedPreferences管理本地数据持久化
class StorageService {
  /// SharedPreferences实例
  SharedPreferences? _prefs;

  /// 存储键名常量
  static const String _keyFavorites = 'favorites_stories';
  static const String _keyUser = 'user_info';
  static const String _keyChildInfo = 'child_info';
  static const String _keyFirstLaunch = 'is_first_launch';

  /// 单例实例
  static final StorageService _instance = StorageService._internal();

  /// 获取单例
  factory StorageService() => _instance;

  /// 私有构造函数
  StorageService._internal();

  /// 初始化SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ========== 收藏故事管理 ==========

  /// 获取所有收藏的故事
  Future<List<Story>> getFavorites() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_keyFavorites);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      // 解析失败，返回空列表
      return [];
    }
  }

  /// 保存收藏的故事列表
  Future<bool> saveFavorites(List<Story> stories) async {
    try {
      final prefs = await _preferences;
      final jsonString = jsonEncode(stories.map((s) => s.toJson()).toList());
      return prefs.setString(_keyFavorites, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// 添加收藏故事
  Future<bool> addFavorite(Story story) async {
    try {
      final favorites = await getFavorites();
      // 检查是否已收藏
      if (favorites.any((s) => s.id == story.id)) return true;

      // 添加到收藏列表
      final favoritedStory = story.copyWith(isFavorited: true);
      favorites.insert(0, favoritedStory); // 新收藏的放在最前面
      return saveFavorites(favorites);
    } catch (e) {
      return false;
    }
  }

  /// 取消收藏故事
  Future<bool> removeFavorite(String storyId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((s) => s.id == storyId);
      return saveFavorites(favorites);
    } catch (e) {
      return false;
    }
  }

  /// 检查故事是否已收藏
  Future<bool> isFavorited(String storyId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((s) => s.id == storyId);
    } catch (e) {
      return false;
    }
  }

  // ========== 用户信息管理 ==========

  /// 获取用户信息
  Future<User?> getUser() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_keyUser);
      if (jsonString == null || jsonString.isEmpty) return null;

      return User.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  /// 保存用户信息
  Future<bool> saveUser(User user) async {
    try {
      final prefs = await _preferences;
      final jsonString = jsonEncode(user.toJson());
      return prefs.setString(_keyUser, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// 更新用户信息（部分字段）
  Future<bool> updateUser(Map<String, dynamic> updates) async {
    try {
      final user = await getUser();
      if (user == null) return false;

      // 更新字段
      if (updates.containsKey('nickname')) {
        user.nickname = updates['nickname'] as String;
      }
      if (updates.containsKey('isVip')) {
        user.isVip = updates['isVip'] as bool;
      }
      if (updates.containsKey('vipExpireDate')) {
        user.vipExpireDate = updates['vipExpireDate'] as DateTime?;
      }
      if (updates.containsKey('freeCountToday')) {
        user.freeCountToday = updates['freeCountToday'] as int;
      }

      return saveUser(user);
    } catch (e) {
      return false;
    }
  }

  // ========== 孩子信息管理 ==========

  /// 获取孩子信息
  Future<Map<String, dynamic>?> getChildInfo() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_keyChildInfo);
      if (jsonString == null || jsonString.isEmpty) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 保存孩子信息
  Future<bool> saveChildInfo(Map<String, dynamic> childInfo) async {
    try {
      final prefs = await _preferences;
      final jsonString = jsonEncode(childInfo);
      return prefs.setString(_keyChildInfo, jsonString);
    } catch (e) {
      return false;
    }
  }

  // ========== 应用状态管理 ==========

  /// 检查是否首次启动
  Future<bool> isFirstLaunch() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// 标记已非首次启动
  Future<bool> setNotFirstLaunch() async {
    final prefs = await _preferences;
    return prefs.setBool(_keyFirstLaunch, false);
  }

  /// 清除所有本地数据
  Future<bool> clearAll() async {
    final prefs = await _preferences;
    return prefs.clear();
  }
}
