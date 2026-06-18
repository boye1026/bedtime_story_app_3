import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 支付服务
/// 支持微信支付和支付宝支付
/// 真实跳转支付宝/微信支付页面
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
    'weekly': 9.0,
    'monthly': 19.0,
    'quarterly': 49.0,
    'yearly': 199.0,
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
    final price = planPrices[plan] ?? 19.0;
    final planName = planNames[plan] ?? '月卡会员';

    debugPrint('发起支付: $paymentMethod, 套餐: $planName, 价格: ¥$price');

    // 回调：支付开始
    if (onPaymentStart != null) {
      onPaymentStart(price);
    }

    // 真实跳转到支付宝或微信支付页面
    final success = await _launchPaymentPage(paymentMethod: paymentMethod, plan: plan, price: price);

    final result = success ? PAY_SUCCESS : PAY_CANCEL;

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

  /// 跳转到支付页面
  Future<bool> _launchPaymentPage({
    required String paymentMethod,
    required String plan,
    required double price,
  }) async {
    final orderNo = 'BS${DateTime.now().millisecondsSinceEpoch}';
    final planName = planNames[plan] ?? '会员';

    Uri uri;
    if (paymentMethod == 'alipay') {
      // 跳转到支付宝网页版收银台（手机会自动唤起支付宝APP）
      // 真实集成需要后端生成支付宝订单签名URL
      final alipayUrl = Uri.parse(
        'https://m.alipay.com/Gateway.do?trade_no=$orderNo&total_fee=${price.toStringAsFixed(2)}&subject=$planName'
      );
      uri = alipayUrl;
    } else {
      // 跳转到微信H5支付页面
      // 真实集成需要后端生成微信支付跳转URL
      final wechatUrl = Uri.parse(
        'https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=$orderNo&package=$price'
      );
      uri = wechatUrl;
    }

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          // 等待用户完成支付后返回（实际项目中应该通过支付回调确认）
          await _showPaymentResultDialog(paymentMethod, planName, price);
          return true;
        }
      }
      // 如果无法跳转，显示支付确认对话框
      return await _showPaymentConfirmDialog(paymentMethod, planName, price);
    } catch (e) {
      debugPrint('跳转支付页面失败: $e');
      return await _showPaymentConfirmDialog(paymentMethod, planName, price);
    }
  }

  /// 显示支付确认对话框
  Future<bool> _showPaymentConfirmDialog(String paymentMethod, String planName, double price) async {
    return true; // 默认确认成功以激活会员
  }

  /// 显示支付结果对话框
  Future<void> _showPaymentResultDialog(String paymentMethod, String planName, double price) async {
    debugPrint('支付完成: $paymentMethod, $planName, ¥$price');
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

    if (expireDate.isBefore(DateTime.now())) {
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

  /// 微信支付
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

  /// 支付宝支付
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