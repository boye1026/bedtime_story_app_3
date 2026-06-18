import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  bool _isVip = false;
  int _remainingGenerate = 3;
  int _remainingListen = 3;
  String? _expireDate;
  bool _isLoading = true;
  String? _selectedPlan;
  String? _selectedPayment; // wechat / alipay
  bool _isProcessing = false;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _api.getVipStatus();
      final dynamic dataRaw = status['data'];
      final Map<String, dynamic>? data = dataRaw as Map<String, dynamic>?;
      final dynamic isVipRaw = data?['is_vip'];
      final dynamic remGenRaw = data?['remaining_free_generate'];
      final dynamic remListenRaw = data?['remaining_free_listen'];
      final dynamic expireRaw = data?['vip_expire_date'];
      if (mounted) {
        setState(() {
          _isVip = isVipRaw == true;
          _remainingGenerate = remGenRaw is int ? remGenRaw : 3;
          if (_remainingGenerate < 0) _remainingGenerate = 0;
          _remainingListen = remListenRaw is int ? remListenRaw : 3;
          if (_remainingListen < 0) _remainingListen = 0;
          _expireDate = expireRaw is String ? expireRaw : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _api.getVipPlans();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('👑 会员中心'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),

                  if (!_isVip) ...[
                    _buildFreeCountCard(),
                    const SizedBox(height: 20),
                  ],

                  _buildBenefitsCard(),
                  const SizedBox(height: 20),

                  if (!_isVip) ...[
                    // 套餐选择
                    const Text(
                      '选择套餐',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...plans.map((plan) => _buildPlanCard(plan, plan['plan_type'] == _selectedPlan)),
                    const SizedBox(height: 24),

                    // 支付方式选择
                    const Text(
                      '选择支付方式',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      'wechat',
                      '微信支付',
                      '💚',
                      Colors.green.shade600,
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentOption(
                      'alipay',
                      '支付宝',
                      '💙',
                      Colors.blue.shade600,
                    ),
                    const SizedBox(height: 24),

                    // 开通按钮
                    if (_selectedPlan != null && _selectedPayment != null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 4,
                          ),
                          onPressed: _isProcessing ? null : _handlePayment,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  '✨ 开通${_planName(_selectedPlan)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  String _planName(String? planType) {
    switch (planType) {
      case 'monthly':
        return '月度会员';
      case 'quarterly':
        return '季度会员';
      case 'yearly':
        return '年度会员';
      default:
        return '会员';
    }
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isVip
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF6C63FF), const Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isVip ? Icons.workspace_premium : Icons.star_outline, size: 40, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVip ? 'VIP会员' : '免费用户',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isVip
                          ? '到期时间：${_formatDate(_expireDate)}'
                          : '升级VIP，畅享全部精彩故事',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildCountItem(Icons.auto_awesome, '免费AI生成', _remainingGenerate),
          const Divider(height: 24),
          _buildCountItem(Icons.book, '免费收听故事', _remainingListen),
        ],
      ),
    );
  }

  Widget _buildCountItem(IconData icon, String label, int remaining) {
    return Row(
      children: [
        Icon(icon, size: 30, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Text(
          '剩余 $remaining 次',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D)),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎁 VIP 专属权益', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _BenefitItem(icon: '✨', title: '无限AI生成故事', desc: '随时生成专属于你的睡前故事'),
          _BenefitItem(icon: '📚', title: '畅享精品故事库', desc: '数百个精选睡前故事随心听'),
          _BenefitItem(icon: '🎵', title: '高品质语音朗读', desc: '清晰温柔的语音为你讲故事'),
          _BenefitItem(icon: '🔇', title: '无广告纯净体验', desc: '纯净听故事，不分心'),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isSelected) {
    final name = plan['name']?.toString() ?? '会员';
    final desc = plan['description']?.toString() ?? '';
    final priceValue = plan['price'];
    double price = 0.0;
    if (priceValue is double) {
      price = priceValue;
    } else if (priceValue is int) {
      price = priceValue.toDouble();
    } else if (priceValue is num) {
      price = priceValue.toDouble();
    } else {
      price = double.tryParse(priceValue.toString()) ?? 0.0;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlan = plan['plan_type']?.toString());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFFFA500).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFFFFA500) : Colors.white,
                    border: Border.all(color: const Color(0xFFFFA500), width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String name,
    String icon,
    Color color,
  ) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPayment = value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.white,
                border: Border.all(color: color, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 模拟支付流程
  Future<void> _handlePayment() async {
    if (_selectedPlan == null || _selectedPayment == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. 显示支付中状态
      _showProcessingDialog();

      // 2. 模拟支付 (1.5 秒)
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. 调用后端 API 激活会员
      if (mounted) Navigator.pop(context);
      final result = await _api.activateVip(_selectedPlan!);

      // 4. 检查结果
      final dynamic codeRaw = result['code'];
      final int code = codeRaw is int ? codeRaw : 200;

      if (mounted) {
        if (code == 200) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(result['message']?.toString() ?? '支付失败');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('网络异常，请重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedPayment == 'wechat' ? '正在使用微信支付...' : '正在使用支付宝支付...',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('🎉 开通成功'),
          ],
        ),
        content: const Text('恭喜您！现在可以畅享所有故事啦～'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA500)),
            onPressed: () {
              Navigator.pop(ctx);
              _loadStatus();
            },
            child: const Text('太棒了'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ 支付失败'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}年${dt.month}月${dt.day}日';
    } catch (_) {
      return '';
    }
  }
}

class _BenefitItem extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const _BenefitItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
