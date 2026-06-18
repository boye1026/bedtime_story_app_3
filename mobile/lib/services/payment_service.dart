import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支付服务
/// 支持微信支付和支付宝支付
/// 当前为模拟支付，真实支付需要配置商户信息
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// 支付结果
  static const int PAY_SUCCESS = 1;
  static const int PAY_FAILED = 0;
  static const int PAY_CANCEL = -1;

  /// 套餐价格配置
  static const Map<String, double> planPrices = {
    'weekly': 19.9,
    'monthly': 29.0,
    'quarterly': 79.0,
    'yearly': 299.0,
  };

  /// 套餐时长配置（天数）
  static const Map<String, int> planDays = {
    'weekly': 7,
    'monthly': 30,
    'quarterly': 90,
    'yearly': 365,
  };

  /// 套餐名称
  static const Map<String, String> planNames = {
    'weekly': '周卡会员',
    'monthly': '月卡会员',
    'quarterly': '季卡会员',
    'yearly': '年度会员',
  };

  /// 发起支付
  /// [paymentMethod] 支付方式: 'wechat' 或 'alipay'
  /// [plan] 套餐类型: 'weekly', 'monthly', 'quarterly', 'yearly'
  /// 返回支付结果: PAY_SUCCESS, PAY_FAILED, PAY_CANCEL
  Future<int> pay({
    required String paymentMethod,
    required String plan,
    Function(double amount)? onPaymentStart,
    Function(int result)? onPaymentComplete,
  }) async {
    final price = planPrices[plan] ?? 29.0;
    final planName = planNames[plan] ?? '月卡会员';

    debugPrint('发起支付: $paymentMethod, 套餐: $planName, 价格: ¥$price');

    // 回调：支付开始
    if (onPaymentStart != null) {
      onPaymentStart(price);
    }

    // 模拟支付流程
    // 真实支付需要接入支付宝SDK和微信支付SDK
    // 这里模拟支付成功
    await Future.delayed(const Duration(seconds: 2));

    // 模拟支付成功（90%成功率）
    final success = true; // 模拟总是成功

    final result = success ? PAY_SUCCESS : PAY_FAILED;

    // 支付成功后激活会员
    if (result == PAY_SUCCESS) {
      await _activateMembership(plan);
    }

    // 回调：支付完成
    if (onPaymentComplete != null) {
      onPaymentComplete(result);
    }

    return result;
  }

  /// 激活会员
  Future<void> _activateMembership(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    final days = planDays[plan] ?? 30;
    final expireDate = DateTime.now().add(Duration(days: days));

    await prefs.setBool('vip_is_vip', true);
    await prefs.setString('vip_expire', expireDate.toIso8601String());
    await prefs.setString('vip_plan', plan);
    await prefs.setString('vip_purchase_time', DateTime.now().toIso8601String());

    debugPrint('会员激活成功: 套餐=$plan, 有效期至=${expireDate.toIso8601String()}');
  }

  /// 检查会员状态
  Future<bool> isVip() async {
    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('vip_is_vip') ?? false;

    if (!isVip) return false;

    final expireStr = prefs.getString('vip_expire');
    if (expireStr == null) return false;

    final expireDate = DateTime.tryParse(expireStr);
    if (expireDate == null) return false;

    // 检查是否过期
    if (expireDate.isBefore(DateTime.now())) {
      // 清除过期状态
      await prefs.remove('vip_is_vip');
      await prefs.remove('vip_expire');
      return false;
    }

    return true;
  }

  /// 获取会员信息
  Future<Map<String, dynamic>> getVipInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final isVip = await this.isVip();

    if (!isVip) {
      return {
        'is_vip': false,
        'plan': null,
        'expire_date': null,
        'days_remaining': 0,
      };
    }

    final plan = prefs.getString('vip_plan') ?? 'monthly';
    final expireStr = prefs.getString('vip_expire') ?? '';
    final expireDate = DateTime.tryParse(expireStr) ?? DateTime.now();
    final daysRemaining = expireDate.difference(DateTime.now()).inDays;

    return {
      'is_vip': true,
      'plan': plan,
      'plan_name': planNames[plan] ?? '月卡会员',
      'expire_date': expireStr,
      'days_remaining': daysRemaining,
    };
  }

  /// 微信支付（模拟）
  /// 真实接入需要配置:
  /// 1. 在微信开放平台注册应用
  /// 2. 获取AppID
  /// 3. 配置商户号和API密钥
  /// 4. 使用 fluwx 或 wechat_kit 插件
  Future<int> wechatPay({
    required String plan,
    Function(double amount)? onPaymentStart,
    Function(int result)? onPaymentComplete,
  }) async {
    return pay(
      paymentMethod: 'wechat',
      plan: plan,
      onPaymentStart: onPaymentStart,
      onPaymentComplete: onPaymentComplete,
    );
  }

  /// 支付宝支付（模拟）
  /// 真实接入需要配置:
  /// 1. 在支付宝开放平台注册应用
  /// 2. 获取AppID
  /// 3. 配置商户私钥和支付宝公钥
  /// 4. 使用 tobias 或 alipay_kit 插件
  Future<int> alipay({
    required String plan,
    Function(double amount)? onPaymentStart,
    Function(int result)? onPaymentComplete,
  }) async {
    return pay(
      paymentMethod: 'alipay',
      plan: plan,
      onPaymentStart: onPaymentStart,
      onPaymentComplete: onPaymentComplete,
    );
  }

  /// 获取支付方式名称
  String getPaymentMethodName(String method) {
    switch (method) {
      case 'wechat':
        return '微信支付';
      case 'alipay':
        return '支付宝';
      default:
        return '未知支付方式';
    }
  }
}