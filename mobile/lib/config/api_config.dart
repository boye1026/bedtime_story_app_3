/// API地址配置
/// 集中管理所有后端API的地址，方便环境切换
class ApiConfig {
  ApiConfig._(); // 私有构造函数，防止实例化

  // ========== 基础配置 ==========

  /// 后端API基础地址
  /// 开发环境使用本地地址，生产环境替换为实际服务器地址
  static const String baseUrl = 'https://api.bedtimestory.example.com/v1';

  /// API请求超时时间（毫秒）
  static const int timeoutMs = 30000;

  // ========== API端点 ==========

  /// 生成故事
  static const String generateStory = '/story/generate';

  /// 检查VIP状态
  static const String checkVipStatus = '/vip/status';

  /// 激活VIP
  static const String activateVip = '/vip/activate';

  /// 获取故事详情
  static String storyDetail(String storyId) => '/story/$storyId';

  /// 获取故事列表
  static const String storyList = '/story/list';

  /// 用户登录/注册
  static const String userLogin = '/user/login';

  /// 获取用户信息
  static const String userInfo = '/user/info';

  /// 更新用户信息
  static const String userUpdate = '/user/update';

  // ========== 请求头 ==========

  /// 默认请求头
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// 带认证的请求头
  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}
