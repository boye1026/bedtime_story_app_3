import 'package:shared_preferences/shared_preferences.dart';

/// 会员服务
/// 管理VIP状态、免费故事生成次数、可听免费故事数
class MembershipService {
  MembershipService._internal();
  static final MembershipService _instance = MembershipService._internal();
  factory MembershipService() => _instance;

  // 存储键
  static const String _keyIsVip = 'membership_is_vip';
  static const String _keyVipExpire = 'membership_vip_expire';
  static const String _keyGenerateUsed = 'membership_generate_used';
  static const String _keyListenUsed = 'membership_listen_used';
  static const String _keyLastResetDate = 'membership_last_reset_date';

  // 免费额度
  static const int freeGenerateLimit = 3; // 免费生成次数
  static const int freeListenLimit = 3; // 免费收听故事数

  // 默认会员套餐
  static const List<Map<String, dynamic>> plans = [
    {
      'plan_type': 'weekly',
      'name': '周卡会员',
      'price': 9.9,
      'description': '7天无限生成故事，畅享所有故事库',
      'duration_days': 7,
    },
    {
      'plan_type': 'monthly',
      'name': '月卡会员',
      'price': 19.9,
      'description': '30天无限生成故事，畅享所有故事库',
      'duration_days': 30,
    },
    {
      'plan_type': 'quarterly',
      'name': '季卡会员',
      'price': 49.9,
      'description': '90天无限生成故事，畅享所有故事库',
      'duration_days': 90,
    },
    {
      'plan_type': 'yearly',
      'name': '年卡会员',
      'price': 168.0,
      'description': '365天无限生成故事，畅享所有故事库',
      'duration_days': 365,
    },
  ];

  /// 每日检查并重置计数
  Future<void> _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReset = prefs.getString(_keyLastResetDate) ?? '';

    if (lastReset != today) {
      await prefs.setString(_keyLastResetDate, today);
    }
  }

  /// 是否是VIP
  Future<bool> isVip() async {
    await _checkDailyReset();
    final prefs = await SharedPreferences.getInstance();
    final bool vip = prefs.getBool(_keyIsVip) ?? false;
    if (!vip) return false;

    // 检查是否过期
    final expireStr = prefs.getString(_keyVipExpire);
    if (expireStr == null) return true;

    final expire = DateTime.tryParse(expireStr);
    if (expire == null) return true;
    return expire.isAfter(DateTime.now());
  }

  /// 获取VIP到期日期
  Future<DateTime?> getVipExpireDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expireStr = prefs.getString(_keyVipExpire);
    if (expireStr == null) return null;
    return DateTime.tryParse(expireStr);
  }

  /// 激活VIP
  Future<void> activateVip(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expire = now.add(Duration(days: days));

    await prefs.setBool(_keyIsVip, true);
    await prefs.setString(_keyVipExpire, expire.toIso8601String());
  }

  /// 已使用的免费生成次数
  Future<int> getGenerateUsedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGenerateUsed) ?? 0;
  }

  /// 剩余免费生成次数
  Future<int> getRemainingGenerateCount() async {
    final vip = await isVip();
    if (vip) return -1; // VIP无限
    final used = await getGenerateUsedCount();
    final remaining = freeGenerateLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// 使用一次免费生成
  Future<bool> useGenerate() async {
    final vip = await isVip();
    if (vip) return true;

    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_keyGenerateUsed) ?? 0;
    if (used >= freeGenerateLimit) return false;

    await prefs.setInt(_keyGenerateUsed, used + 1);
    return true;
  }

  /// 已使用的免费收听次数
  Future<int> getListenUsedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyListenUsed) ?? 0;
  }

  /// 剩余免费收听次数
  Future<int> getRemainingListenCount() async {
    final vip = await isVip();
    if (vip) return -1;
    final used = await getListenUsedCount();
    final remaining = freeListenLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// 使用一次免费收听
  Future<bool> useListen() async {
    final vip = await isVip();
    if (vip) return true;

    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_keyListenUsed) ?? 0;
    if (used >= freeListenLimit) return false;

    await prefs.setInt(_keyListenUsed, used + 1);
    return true;
  }

  /// 获取会员套餐列表
  List<Map<String, dynamic>> getPlans() => List.unmodifiable(plans);
}
