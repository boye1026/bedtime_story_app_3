import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isSendingCode = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  Future<void> _sendVerificationCode() async {
    final phone = _phoneController.text.trim();

    if (!_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入正确的手机号'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      // 调用后端API发送验证码
      final result = await _apiService.sendSmsCode(phone);

      if (result['code'] == 200) {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
            _codeSent = true;
            _countdown = 60;
          });

          // 启动倒计时
          _startCountdown();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('验证码已发送，有效期5分钟'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (result['code'] == 429) {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '验证码已发送，请稍后再试'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '发送失败'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
        // 网络错误时，使用本地模拟验证码
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('网络异常，使用测试验证码: 123456'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _codeSent = true;
          _countdown = 60;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (!_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入正确的手机号'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入6位验证码'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // 调用后端API验证验证码
      final result = await _apiService.verifySmsCode(phone, code);

      if (result['code'] == 200) {
        final userData = result['data'];
        final prefs = await SharedPreferences.getInstance();

        // 保存登录状态
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_phone', phone);
        await prefs.setString('user_id', userData['id']?.toString() ?? 'user_${phone.substring(phone.length - 4)}');
        await prefs.setString('user_nickname', userData['nickname'] ?? '小读者');

        if (mounted) {
          setState(() {
            _isVerifying = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录成功！'),
              backgroundColor: Colors.green,
            ),
          );

          // 回调通知登录成功
          widget.onLoginSuccess?.call();

          // 返回上一页
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '验证失败'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        // 网络错误时，允许使用测试验证码123456本地登录
        if (code == '123456') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_phone', phone);
          await prefs.setString('user_id', 'user_${phone.substring(phone.length - 4)}');
          await prefs.setString('user_nickname', '小读者');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录成功！（离线模式）'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onLoginSuccess?.call();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('网络异常，请使用测试验证码: 123456'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('手机号登录'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '欢迎使用AI睡前故事',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '登录后可购买会员，无限生成故事',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // 手机号输入
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    hintText: '请输入手机号',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) {
                    if (_codeSent && _phoneController.text.trim() != _phoneController.text.trim()) {
                      setState(() {
                        _codeSent = false;
                        _countdown = 0;
                        _timer?.cancel();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 验证码输入
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: _codeSent,
                  decoration: InputDecoration(
                    hintText: _codeSent ? '请输入验证码' : '请先获取验证码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: _codeSent ? Colors.white : Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 获取验证码按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSendingCode || _countdown > 0
                      ? null
                      : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _countdown > 0
                        ? Colors.grey[300]
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSendingCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _countdown > 0 ? '${_countdown}秒后重试' : '获取验证码',
                          style: TextStyle(
                            fontSize: 16,
                            color: _countdown > 0 ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 登录按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying || !_codeSent ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _codeSent ? AppColors.primary : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            color: _codeSent ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 提示
              Text(
                '未注册用户将自动创建账号\n登录即表示同意《用户协议》和《隐私政策》\n测试验证码: 123456',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
