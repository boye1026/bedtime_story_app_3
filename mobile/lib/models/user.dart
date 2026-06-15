/// 用户/会员模型
/// 用于管理用户信息和会员状态
class User {
  /// 用户唯一标识
  final String id;

  /// 用户昵称
  String nickname;

  /// 是否为VIP会员
  bool isVip;

  /// VIP过期日期
  DateTime? vipExpireDate;

  /// 今日剩余免费生成次数
  int freeCountToday;

  /// 上次生成故事的日期（用于判断是否需要重置免费次数）
  DateTime lastGenerateDate;

  User({
    this.id = '',
    this.nickname = '小星星',
    this.isVip = false,
    this.vipExpireDate,
    this.freeCountToday = 3,
    DateTime? lastGenerateDate,
  }) : lastGenerateDate = lastGenerateDate ?? DateTime.now();

  /// 从JSON创建对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '小星星',
      isVip: json['isVip'] as bool? ?? false,
      vipExpireDate: json['vipExpireDate'] != null
          ? DateTime.parse(json['vipExpireDate'] as String)
          : null,
      freeCountToday: json['freeCountToday'] as int? ?? 3,
      lastGenerateDate: json['lastGenerateDate'] != null
          ? DateTime.parse(json['lastGenerateDate'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'isVip': isVip,
      'vipExpireDate': vipExpireDate?.toIso8601String(),
      'freeCountToday': freeCountToday,
      'lastGenerateDate': lastGenerateDate.toIso8601String(),
    };
  }

  /// 检查VIP是否有效
  bool get isVipActive {
    if (!isVip || vipExpireDate == null) return false;
    return DateTime.now().isBefore(vipExpireDate!);
  }

  /// 检查今日是否还有免费次数
  bool get hasFreeCount {
    _checkAndResetFreeCount();
    return freeCountToday > 0;
  }

  /// 使用一次免费次数
  void useFreeCount() {
    _checkAndResetFreeCount();
    if (freeCountToday > 0) {
      freeCountToday--;
      lastGenerateDate = DateTime.now();
    }
  }

  /// 检查并重置免费次数（如果跨天了）
  void _checkAndResetFreeCount() {
    final now = DateTime.now();
    final lastDate = lastGenerateDate;
    // 如果不是同一天，重置免费次数
    if (now.year != lastDate.year ||
        now.month != lastDate.month ||
        now.day != lastDate.day) {
      freeCountToday = 3;
      lastGenerateDate = now;
    }
  }

  /// 通过观看广告获得额外次数
  void addFreeCountFromAd() {
    _checkAndResetFreeCount();
    freeCountToday++;
  }

  /// 复制并修改部分字段
  User copyWith({
    String? id,
    String? nickname,
    bool? isVip,
    DateTime? vipExpireDate,
    int? freeCountToday,
    DateTime? lastGenerateDate,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      isVip: isVip ?? this.isVip,
      vipExpireDate: vipExpireDate ?? this.vipExpireDate,
      freeCountToday: freeCountToday ?? this.freeCountToday,
      lastGenerateDate: lastGenerateDate ?? this.lastGenerateDate,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, nickname: $nickname, isVip: $isVip, '
        'freeCountToday: $freeCountToday)';
  }
}
