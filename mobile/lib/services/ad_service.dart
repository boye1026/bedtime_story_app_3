/// 广告服务接口
/// 定义广告相关的抽象接口，内部为占位实现
/// 预留真实广告SDK（如穿山甲、优量汇等）的接入位置
class AdService {
  /// 单例实例
  static final AdService _instance = AdService._internal();

  /// 获取单例
  factory AdService() => _instance;

  /// 私有构造函数
  AdService._internal();

  /// 广告加载状态回调
  void Function(bool isLoaded)? onAdLoaded;

  /// 广告展示失败回调
  void Function(String error)? onAdFailed;

  /// 激励广告观看完成回调
  void Function(bool earnedReward)? onAdEarnedReward;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 激励广告是否已加载
  bool _isRewardedAdReady = false;

  /// 获取初始化状态
  bool get isInitialized => _isInitialized;

  /// 获取激励广告就绪状态
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// 初始化广告SDK
  /// [appId] 广告平台应用ID
  /// 在实际接入时，这里初始化真实的广告SDK
  Future<bool> init({String? appId}) async {
    // TODO: 接入真实广告SDK时，在此处初始化
    // 示例：
    // await FlutterAdSdk.init(appId: appId);
    // await _loadRewardedAd();

    _isInitialized = true;
    _isRewardedAdReady = true; // 占位：模拟广告已就绪
    onAdLoaded?.call(true);
    return true;
  }

  /// 加载激励广告
  /// 在实际接入时，这里预加载激励广告
  Future<void> loadRewardedAd() async {
    // TODO: 接入真实广告SDK时，在此处加载激励广告
    // 示例：
    // await RewardedAd.load(adUnitId: adUnitId);
    // _isRewardedAdReady = true;
    // onAdLoaded?.call(true);

    // 占位：模拟广告加载成功
    _isRewardedAdReady = true;
    onAdLoaded?.call(true);
  }

  /// 展示激励广告
  /// 返回用户是否完整观看了广告（是否获得奖励）
  Future<bool> showRewardedAd() async {
    // TODO: 接入真实广告SDK时，在此处展示激励广告
    // 示例：
    // if (!_isRewardedAdReady) {
    //   await loadRewardedAd();
    // }
    // final result = await RewardedAd.show();
    // _isRewardedAdReady = false;
    // await loadRewardedAd(); // 预加载下一个
    // return result;

    // 占位：模拟用户完整观看了广告
    _isRewardedAdReady = false;
    await Future.delayed(const Duration(seconds: 2)); // 模拟广告播放时间
    onAdEarnedReward?.call(true);
    await loadRewardedAd(); // 预加载下一个
    return true;
  }

  /// 展示插屏广告
  Future<void> showInterstitialAd() async {
    // TODO: 接入真实广告SDK时，在此处展示插屏广告
    // 示例：
    // await InterstitialAd.show();
  }

  /// 展示Banner广告
  /// 返回Banner广告的Widget（占位返回null）
  Future<dynamic> createBannerAd({String? adUnitId}) async {
    // TODO: 接入真实广告SDK时，返回Banner广告Widget
    // 示例：
    // return BannerAdWidget(adUnitId: adUnitId);
    return null;
  }

  /// 销毁广告，释放资源
  Future<void> dispose() async {
    // TODO: 接入真实广告SDK时，在此处销毁广告
    // 示例：
    // await BannerAd.dispose();
    // await RewardedAd.dispose();
    _isRewardedAdReady = false;
    _isInitialized = false;
  }
}
