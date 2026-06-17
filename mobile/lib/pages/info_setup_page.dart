import 'package:flutter/material.dart';
import '../models/child_info.dart';
import '../theme/app_colors.dart';
import '../widgets/style_option.dart';

/// 信息设置页
/// 用于收集孩子信息，作为生成故事的输入
class InfoSetupPage extends StatefulWidget {
  const InfoSetupPage({super.key});

  @override
  State<InfoSetupPage> createState() => _InfoSetupPageState();
}

class _InfoSetupPageState extends State<InfoSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  int? _selectedAge;
  final List<String> _selectedInterests = [];
  final List<String> _selectedDirections = [];
  String _selectedStyle = '童话风';

  final List<int> _ageOptions = List.generate(12, (index) => index + 1);

  final List<Map<String, String>> _interestOptions = const [
    {'label': '动物', 'icon': '🐾'},
    {'label': '太空', 'icon': '🚀'},
    {'label': '海洋', 'icon': '🌊'},
    {'label': '恐龙', 'icon': '🦕'},
    {'label': '公主', 'icon': '👸'},
    {'label': '汽车', 'icon': '🚗'},
    {'label': '音乐', 'icon': '🎵'},
    {'label': '画画', 'icon': '🎨'},
  ];

  final List<Map<String, String>> _directionOptions = const [
    {'label': '勇敢', 'icon': '🦁'},
    {'label': '礼貌', 'icon': '🤝'},
    {'label': '自律', 'icon': '📋'},
    {'label': '友善', 'icon': '💛'},
  ];

  final List<Map<String, String>> _styleOptions = const [
    {'name': '童话风', 'icon': '🏰', 'desc': '充满魔法与奇幻的经典童话'},
    {'name': '冒险风', 'icon': '🗺️', 'desc': '刺激有趣的探险旅程'},
    {'name': '温馨风', 'icon': '🌙', 'desc': '温暖治愈的日常小故事'},
    {'name': '启蒙风', 'icon': '📚', 'desc': '寓教于乐的成长故事'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('请输入孩子的姓名');
      return;
    }
    if (_selectedAge == null) {
      _showSnackBar('请选择孩子的年龄');
      return;
    }

    // 构建孩子信息对象并导航到故事显示页
    final childInfo = ChildInfo(
      name: _nameController.text.trim(),
      age: _selectedAge!,
      interests: List.from(_selectedInterests),
      educationDirections: List.from(_selectedDirections),
      storyStyle: _selectedStyle,
    );

    Navigator.pushNamed(context, '/story-display', arguments: childInfo);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('定制专属故事'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('宝贝的名字'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '请输入孩子的姓名',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('宝贝的年龄'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedAge != null
                      ? AppColors.primary
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedAge,
                  hint: const Text(
                    '请选择年龄',
                    style: TextStyle(color: AppColors.textHint, fontSize: 16),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _ageOptions.map((age) {
                    return DropdownMenuItem<int>(
                      value: age,
                      child: Text('$age岁', style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAge = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('兴趣爱好（可多选）'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _interestOptions.map((option) {
                final isSelected = _selectedInterests.contains(option['label']);
                return FilterChip(
                  label: Text('${option['icon']} ${option['label']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(option['label']!);
                      } else {
                        _selectedInterests.remove(option['label']);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  backgroundColor: AppColors.cardBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFE8E8E8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('启蒙方向（可多选）'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _directionOptions.map((option) {
                final isSelected = _selectedDirections.contains(option['label']);
                return FilterChip(
                  label: Text('${option['icon']} ${option['label']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDirections.add(option['label']!);
                      } else {
                        _selectedDirections.remove(option['label']);
                      }
                    });
                  },
                  selectedColor: AppColors.secondary.withOpacity(0.15),
                  backgroundColor: AppColors.cardBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.secondary : const Color(0xFFE8E8E8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('故事风格'),
            const SizedBox(height: 8),
            Column(
              children: _styleOptions.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StyleOption(
                    name: option['name']!,
                    description: option['desc']!,
                    icon: option['icon']!,
                    isSelected: _selectedStyle == option['name'],
                    onChanged: (isSelected) {
                      if (isSelected) {
                        setState(() => _selectedStyle = option['name']!);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      '✨ 生成专属故事',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
