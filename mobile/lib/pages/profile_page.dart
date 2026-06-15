import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = '小读者';
  int _storyCount = 0;
  bool _isVip = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final stories = prefs.getStringList('saved_stories') ?? [];
    
    setState(() {
      _userName = prefs.getString('user_name') ?? '小读者';
      _storyCount = stories.length;
      _isVip = prefs.getBool('is_vip') ?? false;
    });
  }
  
  Future<void> _updateUserName() async {
    final TextEditingController controller = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', newName);
                setState(() => _userName = newName);
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearAllStories() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有故事'),
        content: const Text('确定要清空所有收藏的故事吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_stories');
              setState(() => _storyCount = 0);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空所有故事')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像和用户信息
            GestureDetector(
              onTap: _updateUserName,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isVip ? Colors.orange[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isVip ? 'VIP会员' : '普通用户',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isVip ? Colors.orange[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 统计卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.book, '故事数', ''),
                  _buildStatItem(Icons.favorite, '收藏', ''),
                  _buildStatItem(Icons.star, '积分', '120'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 菜单列表
            _buildMenuItem(
              Icons.history, 
              '我的故事', 
              () => Navigator.pushNamed(context, '/stories'),
              count: _storyCount,
            ),
            _buildMenuItem(Icons.auto_awesome, 'VIP会员', () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('成为VIP会员'),
                  content: const Text('VIP会员可享受无限生成故事、精品故事库等特权。\n\n即将开放，敬请期待！'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            }),
            _buildMenuItem(Icons.settings, '设置', () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('设置'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('关于应用'),
                      const SizedBox(height: 8),
                      Text('AI睡前故事 v1.0.0', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('为孩子创造专属睡前故事', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            }),
            _buildMenuItem(Icons.help, '帮助中心', () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('使用帮助'),
                  content: const Text(
                    '1. 在「生成故事」页面填写宝宝信息\n'
                    '2. 选择兴趣爱好和故事风格\n'
                    '3. 点击生成故事\n'
                    '4. 可以播放语音或收藏故事\n'
                    '5. 收藏的故事在「我的故事」中查看'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 20),
            
            // 清空数据按钮
            if (_storyCount > 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _clearAllStories,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('清空所有故事', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
  
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {int? count}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: count != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              )
            : const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
