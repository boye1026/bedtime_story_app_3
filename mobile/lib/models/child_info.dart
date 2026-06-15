class ChildInfo {
  final String name;
  final int age;
  final String gender;
  final String storyType;
  final List<String> interests;
  final String language;
  final DateTime createdAt;

  ChildInfo({
    required this.name,
    required this.age,
    required this.gender,
    required this.storyType,
    required this.interests,
    required this.language,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'storyType': storyType,
      'interests': interests,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    return ChildInfo(
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      storyType: json['storyType'] as String,
      interests: List<String>.from(json['interests'] as List),
      language: json['language'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
