class Story {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String? imageUrl;
  final List<String> tags;
  final DateTime createdAt;
  final String? style;
  final bool isFavorited;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    this.imageUrl,
    required this.tags,
    required this.createdAt,
    this.style,
    this.isFavorited = false,
  });

  String get formattedDate {
    return '${createdAt.year}-${createdAt.month}-${createdAt.day}';
  }

  Story copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    List<String>? tags,
    DateTime? createdAt,
    String? style,
    bool? isFavorited,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      style: style ?? this.style,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      style: json['style'] as String?,
      isFavorited: json['isFavorited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'style': style,
      'isFavorited': isFavorited,
    };
  }
}
