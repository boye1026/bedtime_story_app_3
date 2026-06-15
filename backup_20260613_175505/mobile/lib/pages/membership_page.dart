import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  Map<String, dynamic>? _vipInfo;
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVIPInfo();
  }

  Future<void> _loadVIPInfo() async {
    try {
      final apiService = ApiService();
      final vipStatus = await apiService.getVIPStatus();
      final plans = await apiService.getVIPPlans();
      
      setState(() {
        _vipInfo = vipStatus;
        _plans = List<Map<String, dynamic>>.from(plans);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePurchase(String planType, double price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('购买 $planType 会员，价格 ¥$price'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认支付'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        final result = await apiService.activateVIP(planType);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('购买成功！感谢您成为VIP会员')),
          );
          await _loadVIPInfo();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('购买失败: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP会员'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildVIPStatusCard(),
                  const SizedBox(height: 20),
                  _buildDailyFreeCard(),
                  const SizedBox(height: 20),
                  _buildBenefitsCard(),
                  const SizedBox(height: 20),
                  ..._plans.map((plan) => _buildPlanCard(plan)),
                ],
              ),
            ),
    );
  }

  Widget _buildVIPStatusCard() {
    final isVip = _vipInfo?['is_vip'] ?? false;
    final expireDate = _vipInfo?['vip_expire_date'] ?? '';
    final remainingDays = _vipInfo?['remaining_days'] ?? 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isVip ? Colors.amber[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isVip ? Icons.verified : Icons.star_border,
              size: 60,
              color: isVip ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              isVip ? 'VIP会员（已激活）' : '普通会员',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isVip ? Colors.amber[800] : Colors.grey[600],
              ),
            ),
            if (isVip) ...[
              const SizedBox(height: 8),
              Text('有效期至：$expireDate'),
              Text('剩余 $remainingDays 天'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyFreeCard() {
    final remainingCount = _vipInfo?['remaining_free_count'] ?? 5;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.today, size: 40, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日免费生成次数',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$remainingCount / 5 次',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎁 VIP专属权益', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildBenefitItem('✨', '无限生成故事', 'VIP用户无限制生成故事'),
            _buildBenefitItem('📚', '精品故事库', '解锁100+经典睡前故事'),
            _buildBenefitItem('🎵', '高品质语音', '真人音色，情感朗读'),
            _buildBenefitItem('🔇', '无广告体验', '纯净听故事，不分心'),
            _buildBenefitItem('💾', '云端存储', '故事永久保存，多设备同步'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final price = plan['price'].toDouble();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(plan['description'] ?? ''),
                  Text(
                    '¥${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _handlePurchase(plan['plan_type'], price),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('购买'),
            ),
          ],
        ),
      ),
    );
  }
}
