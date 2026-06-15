import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> generateStory({
    required String childName,
    required int childAge,
    required List<String> interests,
    required String style,
  }) async {
    try {
      final token = await _getToken();
      final response = await _dio.post('/stories/generate',
        data: {
          'child_name': childName,
          'child_age': childAge,
          'interests': interests,
          'story_style': style,
        },
        options: Options(headers: token != null ? {'Authorization': 'Bearer $token'} : {}),
      );
      return response.data;
    } catch (e) {
      throw Exception('生成故事失败: $e');
    }
  }

  Future<Map<String, dynamic>> getVIPStatus() async {
    try {
      final token = await _getToken();
      final response = await _dio.get('/user/vip/status',
        options: Options(headers: token != null ? {'Authorization': 'Bearer $token'} : {}),
      );
      return response.data;
    } catch (e) {
      return {'is_vip': false, 'remaining_free_count': 5};
    }
  }

  Future<List<dynamic>> getVIPPlans() async {
    try {
      final response = await _dio.get('/membership/plans');
      return response.data;
    } catch (e) {
      return [
        {'plan_type': 'monthly', 'name': '月度会员', 'price': 29.9, 'description': '30天VIP权益'},
        {'plan_type': 'quarterly', 'name': '季度会员', 'price': 79.9, 'description': '90天VIP权益，节省20%'},
        {'plan_type': 'yearly', 'name': '年度会员', 'price': 299.9, 'description': '365天VIP权益，节省50%'},
      ];
    }
  }

  Future<Map<String, dynamic>> activateVIP(String planType) async {
    try {
      final token = await _getToken();
      final response = await _dio.post('/membership/activate',
        data: {'plan_type': planType},
        options: Options(headers: token != null ? {'Authorization': 'Bearer $token'} : {}),
      );
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
