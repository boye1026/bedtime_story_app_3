/// 孩子信息模型
/// 用于在页面之间传递故事生成的参数
class ChildInfo {
  final String name;
  final int age;
  final List<String> interests;
  final List<String> educationDirections;
  final String storyStyle;

  const ChildInfo({
    required this.name,
    required this.age,
    required this.interests,
    required this.educationDirections,
    required this.storyStyle,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'interests': interests,
      'education_directions': educationDirections,
      'story_style': storyStyle,
    };
  }

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    return ChildInfo(
      name: json['name'] as String,
      age: json['age'] as int,
      interests: List<String>.from(json['interests'] as List),
      educationDirections:
          List<String>.from(json['education_directions'] as List),
      storyStyle: json['story_style'] as String,
    );
  }

  /// 将中文风格名映射为英文键名（API 使用）
  String get styleKey {
    switch (storyStyle) {
      case '童话风':
        return 'fairy_tale';
      case '冒险风':
        return 'adventure';
      case '温馨风':
        return 'warm';
      case '启蒙风':
        return 'educational';
      default:
        return 'fairy_tale';
    }
  }
}
