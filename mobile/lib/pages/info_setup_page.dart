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
  // ========== 表单状态 ==========

  /// 孩子姓名控制器
  final TextEditingController _nameController = TextEditingController();

  /// 选中的年龄
  int? _selectedAge;

  /// 选中的兴趣爱好
  final List<String> _selectedInterests = [];

  /// 选中的启蒙方向
  final List<String> _selectedDirections = [];

  /// 选中的故事风格
  String _selectedStyle = '童话风';

  /// 表单Key，用于验证
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ========== 数据选项 ==========

  /// 年龄选项 (1-12岁)
  final List<int> _ageOptions = List.generate(12, (index) => index + 1);

  /// 兴趣爱好选项
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

  /// 启蒙方向选项
  final List<Map<String, String>> _directionOptions = const [
    {'label': '勇敢', 'icon': '🦁'},
    {'label': '礼貌', 'icon': '🤝'},
    {'label': '自律', 'icon': '📋'},
    {'label': '友善', 'icon': '💛'},
  ];

  /// 故事风格选项
  final List<Map<String, String>> _styleOptions = const [
    {'name': '童话风', 'icon': '🏰', 'desc': '充满魔法与奇幻的经典童话'},
    {'name': '冒险风', 'icon': '🗺️', 'desc': '刺激有趣的探险旅程'},
    {'name': '温馨风', 'icon': '🌙', 'desc': '温暖治愈的日常小故事'},
    {'name': '启蒙风', 'icon': '📚', 'desc': '寓教于乐的成长故事'},
  ];

  /// 是否正在提交
  final bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 提交表单，生成故事
  void _submitForm() {
    // 验证表单
    if (!_formKey.currentState!.validate()) return;

    // 验证年龄
    if (_selectedAge == null) {
      _showSnackBar('请选择孩子的年龄');
      return;
    }

    // 构建孩子信息
    final childInfo = ChildInfo(
      name: _nameController.text.trim(),
      age: _selectedAge!,
      interests: List.from(_selectedInterests),
      educationDirections: List.from(_selectedDirections),
      storyStyle: _selectedStyle,
    );

    // 导航到故事展示页
    Navigator.pushNamed(
      context,
      '/story-display',
      arguments: childInfo,
    );
  }

  /// 显示提示信息
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== 孩子姓名 ==========
              _buildSectionTitle('宝贝的名字'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '请输入孩子的姓名',
                  prefixIcon: Icon(Icons.person_outline),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入孩子的姓名';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),

              // ========== 年龄选择 ==========
              _buildSectionTitle('宝贝的年龄'),
              const SizedBox(height: 8),
              _buildAgeSelector(),
              const SizedBox(height: 24),

              // ========== 兴趣爱好 ==========
              _buildSectionTitle('兴趣爱好（可多选）'),
              const SizedBox(height: 8),
              _buildInterestChips(),
              const SizedBox(height: 24),

              // ========== 启蒙方向 ==========
              _buildSectionTitle('启蒙方向（可多选）'),
              const SizedBox(height: 8),
              _buildDirectionChips(),
              const SizedBox(height: 24),

              // ========== 故事风格 ==========
              _buildSectionTitle('故事风格'),
              const SizedBox(height: 8),
              _buildStyleOptions(),
              const SizedBox(height: 36),

              // ========== 生成按钮 ==========
              _buildGenerateButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分区标题
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

  /// 构建年龄选择器
  Widget _buildAgeSelector() {
    return Container(
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
              child: Text(
                '$age岁',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAge = value;
            });
          },
        ),
      ),
    );
  }

  /// 构建兴趣爱好多选Chip
  Widget _buildInterestChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _interestOptions.map((option) {
        final label = option['label']!;
        final icon = option['icon']!;
        final isSelected = _selectedInterests.contains(label);

        return FilterChip(
          label: Text('$icon $label'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(label);
              } else {
                _selectedInterests.remove(label);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
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
    );
  }

  /// 构建启蒙方向多选Chip
  Widget _buildDirectionChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _directionOptions.map((option) {
        final label = option['label']!;
        final icon = option['icon']!;
        final isSelected = _selectedDirections.contains(label);

        return FilterChip(
          label: Text('$icon $label'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDirections.add(label);
              } else {
                _selectedDirections.remove(label);
              }
            });
          },
          selectedColor: AppColors.secondary.withValues(alpha: 0.15),
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
    );
  }

  /// 构建故事风格选择
  Widget _buildStyleOptions() {
    return Column(
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
                setState(() {
                  _selectedStyle = option['name']!;
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  /// 构建生成按钮
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
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
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📖', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text(
                        '生成专属故事',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
