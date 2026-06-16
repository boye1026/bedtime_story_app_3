import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/star_animation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 30),
                    _buildMainButtons(context),
                    const SizedBox(height: 30),
                    _buildRecommendedStories(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🌙 睡前故事',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.pushNamed(context, '/stories');
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        const StarAnimation(),
        const SizedBox(height: 20),
        const Text(
          '晚安，小宝贝',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '让我为你讲一个温暖的睡前故事吧',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMainButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.auto_awesome,
            title: '生成故事',
            subtitle: 'AI智能定制',
            color: AppColors.primary,
            onTap: () {
              Navigator.pushNamed(context, '/setup');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.book,
            title: '故事库',
            subtitle: '精选好故事',
            color: AppColors.secondary,
            onTap: () {
              Navigator.pushNamed(context, '/stories');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedStories(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {
        'title': '勇敢的小兔子',
        'description': '教会孩子勇敢面对困难',
        'icon': Icons.auto_stories,
      },
      {
        'title': '星星的魔法',
        'description': '温馨的睡前童话',
        'icon': Icons.star,
      },
      {
        'title': '小熊猫的冒险',
        'description': '充满探索精神的旅程',
        'icon': Icons.forest,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📖 推荐故事',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...stories.map((story) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStoryCard(
                context,
                title: story['title'] as String,
                description: story['description'] as String,
                icon: story['icon'] as IconData,
              ),
            )),
      ],
    );
  }

  Widget _buildStoryCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon}) {
    return GestureDetector(
      onTap: () {
        // 点击推荐故事跳转到信息填写页，预填该故事主题
        Navigator.pushNamed(context, '/setup');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.play_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/setup');
              break;
            case 2:
              Navigator.pushNamed(context, '/stories');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '生成'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '故事'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
