import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// 认证服务
/// 管理用户登录状态和用户信息
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SharedPreferences? _prefs;
  User? _currentUser;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadCurrentUser();
  }

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 检查是否已登录
  bool get isLoggedIn => _currentUser != null;

  /// 加载当前用户
  Future<void> _loadCurrentUser() async {
    if (_prefs == null) await init();

    final isLoggedIn = _prefs!.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      _currentUser = null;
      return;
    }

    final userId = _prefs!.getString('user_id') ?? '';
    final phone = _prefs!.getString('user_phone') ?? '';
    final nickname = _prefs!.getString('user_nickname') ?? '用户';

    _currentUser = User(
      id: userId,
      nickname: nickname,
      isVip: false,
      freeCountToday: 3,
    );
  }

  /// 手机号登录
  Future<bool> loginWithPhone(String phone, String code) async {
    if (_prefs == null) await init();

    // 实际项目中应调用后端API验证
    // 此处模拟登录成功

    final userId = 'user_${phone.substring(phone.length - 4)}';

    await _prefs!.setBool('is_logged_in', true);
    await _prefs!.setString('user_id', userId);
    await _prefs!.setString('user_phone', phone);
    await _prefs!.setString('user_nickname', '用户${phone.substring(phone.length - 4)}');

    _currentUser = User(
      id: userId,
      nickname: '用户${phone.substring(phone.length - 4)}',
      isVip: false,
      freeCountToday: 3,
    );

    return true;
  }

  /// 退出登录
  Future<void> logout() async {
    if (_prefs == null) await init();

    await _prefs!.remove('is_logged_in');
    await _prefs!.remove('user_id');
    await _prefs!.remove('user_phone');
    await _prefs!.remove('user_nickname');

    _currentUser = null;
  }

  /// 更新用户VIP状态
  Future<void> updateVipStatus(bool isVip, DateTime? expireDate) async {
    if (_currentUser == null) return;

    _currentUser!.isVip = isVip;
    _currentUser!.vipExpireDate = expireDate;

    // 保存到本地
    if (_prefs == null) await init();
    await _prefs!.setBool('user_is_vip', isVip);
    if (expireDate != null) {
      await _prefs!.setString('user_vip_expire', expireDate.toIso8601String());
    }
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }
}
