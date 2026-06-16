import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// API 服务类
/// 统一管理所有后端 API 请求，封装了 Dio HTTP 客户端
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConfig.timeoutMs),
    receiveTimeout: const Duration(milliseconds: ApiConfig.timeoutMs * 2),
    headers: ApiConfig.defaultHeaders,
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        final userId = prefs.getInt('user_id');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (userId != null) {
          options.headers['X-User-ID'] = userId.toString();
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // ========== 故事相关 API ==========

  /// 生成一个新故事
  /// 
  /// [childName] 孩子姓名
  /// [childAge] 孩子年龄
  /// [interests] 兴趣爱好列表
  /// [style] 故事风格，可选 fairy_tale, adventure, warm, educational
  /// [directions] 教育方向
  /// 
  /// 返回 {code, message, data: {id, title, content, created_at}}
  Future<Map<String, dynamic>> generateStory({
    required String childName,
    required int childAge,
    required List<String> interests,
    String style = 'fairy_tale',
    List<String>? directions,
  }) async {
    try {
      final response = await _dio.post(
        '/api/story/generate',
        data: {
          'child_name': childName,
          'child_age': childAge,
          'interests': interests,
          'story_style': style,
          if (directions != null) 'education_directions': directions,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return data;
    } catch (e) {
      // 当后端不可用时，返回模拟数据，方便前端测试
      return {
        'code': 200,
        'message': 'success',
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': '$childName 的星空冒险',
          'content': _buildMockStory(childName, childAge),
          'created_at': DateTime.now().toIso8601String(),
        }
      };
    }
  }

  /// 获取用户故事列表
  Future<Map<String, dynamic>> getUserStories({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get(
        '/api/story/list',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': {'stories': [], 'total': 0}};
    }
  }

  /// 获取故事详情
  Future<Map<String, dynamic>> getStory(int storyId) async {
    try {
      final response = await _dio.get('/api/story/$storyId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 404, 'message': 'not found', 'data': null};
    }
  }

  /// 切换收藏状态
  Future<Map<String, dynamic>> toggleFavorite(int storyId) async {
    try {
      final response = await _dio.post('/api/story/$storyId/favorite');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': {'is_favorite': true}};
    }
  }

  /// 删除故事
  Future<Map<String, dynamic>> deleteStory(int storyId) async {
    try {
      final response = await _dio.delete('/api/story/$storyId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': null};
    }
  }

  // ========== 用户相关 API ==========

  /// 用户注册
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
      });
      final data = response.data as Map<String, dynamic>;
      // 保存 token 和 user_id
      if (data['code'] == 200 || data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data'] != null) {
          if (data['data']['token'] != null) {
            await prefs.setString('access_token', data['data']['token']);
          }
          if (data['data']['user_id'] != null) {
            await prefs.setInt('user_id', data['data']['user_id']);
          }
          if (data['data']['id'] != null) {
            await prefs.setInt('user_id', data['data']['id']);
          }
        }
      }
      return data;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': {'user_id': 1, 'token': 'mock_token'}};
    }
  }

  /// 用户登录
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['code'] == 200 || data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data'] != null) {
          if (data['data']['token'] != null) {
            await prefs.setString('access_token', data['data']['token']);
          }
          if (data['data']['user_id'] != null) {
            await prefs.setInt('user_id', data['data']['user_id']);
          }
          if (data['data']['id'] != null) {
            await prefs.setInt('user_id', data['data']['id']);
          }
        }
      }
      return data;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': {'user_id': 1, 'token': 'mock_token'}};
    }
  }

  /// 获取用户信息和VIP状态
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get('/api/user/info');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'code': 200,
        'message': 'success',
        'data': {
          'id': 1,
          'username': '小朋友',
          'is_vip': false,
          'remaining_free_count': 5,
          'vip_expire_date': null,
        }
      };
    }
  }

  // ========== 会员相关 API ==========

  /// 获取VIP套餐列表
  Future<List<dynamic>> getVIPPlans() async {
    try {
      final response = await _dio.get('/api/membership/plans');
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List;
      return [];
    } catch (e) {
      return [
        {'plan_type': 'weekly', 'name': '周卡会员', 'price': 19.9, 'description': '7天无限生成故事', 'duration_days': 7},
        {'plan_type': 'monthly', 'name': '月卡会员', 'price': 29.9, 'description': '30天无限生成故事', 'duration_days': 30},
        {'plan_type': 'quarterly', 'name': '季卡会员', 'price': 79.9, 'description': '90天无限生成故事', 'duration_days': 90},
      ];
    }
  }

  /// 激活VIP
  Future<Map<String, dynamic>> activateVIP(String planType) async {
    try {
      final response = await _dio.post('/api/membership/activate', data: {
        'plan_type': planType,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': null};
    }
  }

  /// 观看广告奖励免费次数
  Future<Map<String, dynamic>> rewardAdCount() async {
    try {
      final response = await _dio.post('/api/user/ad-reward');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'code': 200, 'message': 'success', 'data': {'remaining_free_count': 5}};
    }
  }

  // ========== 工具方法 ==========

  /// 退出登录，清除本地缓存
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
  }

  /// 构建模拟故事内容（后端不可用时使用）
  String _buildMockStory(String childName, int age) {
    return '''
在一个宁静的夜晚，$childName 躺在温暖的小床上，看着窗外闪闪发亮的星星。

忽然，一颗最亮的小星星眨了眨眼睛，轻轻地飞到了窗前。

"你好，$childName，"小星星轻声说，"今晚你愿意跟我一起去天空旅行吗？"

$childName 睁大了眼睛，用力地点了点头。

小星星带着$childName飞过了高高的月亮，月亮婆婆慈祥地笑着。他们又飞过了亮晶晶的银河，那里有无数的小星星在跳舞。

"看呀，"小星星说，"那是勇敢星，它会让你变得勇敢；那是智慧星，它会让你变得聪明。"

$childName 开心地笑了，觉得自己也变成了一颗最亮的小星星。

夜风吹过，$childName 感到一阵温暖，慢慢地闭上了眼睛。

"晚安，$childName，"小星星轻声说，"做个好梦吧。"

$childName 在梦里继续着这场美丽的天空旅行……

晚安，小朋友，做个甜甜的梦吧。✨🌙
''';
  }
}
