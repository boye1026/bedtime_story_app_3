/// API 地址配置
/// 支持开发和生产两种环境
class ApiConfig {
  ApiConfig._(); // 私有构造函数，防止实例化

  // ============ 环境切换 ============
  // 将下面的 true 改为 false 切换到生产环境
  static const bool isDebug = true;

  // 开发环境地址（本地后端）
  static const String baseUrlDebug = 'http://10.0.2.2:5000';
  // 生产环境地址（请替换为你的真实服务器地址）
  static const String baseUrlRelease = 'https://your-api-domain.com';

  /// 当前使用的基础地址
  static String get baseUrl => isDebug ? baseUrlDebug : baseUrlRelease;

  // ============ 请求超时时间 ============
  static const int timeoutMs = 30000;

  // ============ 接口路径 ============
  // 故事相关
  static const String generateStory = '/api/story/generate';
  static String storyDetail(int storyId) => '/api/story/$storyId';
  static const String storyList = '/api/story/list';
  static String storyFavorite(int storyId) => '/api/story/$storyId/favorite';
  static String storyDelete(int storyId) => '/api/story/$storyId';

  // 会员相关
  static const String membershipPlans = '/api/membership/plans';
  static const String membershipActivate = '/api/membership/activate';
  static const String membershipStatus = '/api/membership/status';

  // 用户相关
  static const String userRegister = '/api/auth/register';
  static const String userLogin = '/api/auth/login';
  static const String userInfo = '/api/user/info';
  static const String userFreeCount = '/api/user/free-count';
  static const String userAdReward = '/api/user/ad-reward';

  // ============ 请求头 ============
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}
