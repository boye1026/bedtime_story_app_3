import 'package:flutter/material.dart';
import '../data/built_in_stories.dart';

/// 故事库页面 - 展示所有分类和故事
class StoryLibraryPage extends StatefulWidget {
  const StoryLibraryPage({super.key});

  @override
  State<StoryLibraryPage> createState() => _StoryLibraryPageState();
}

class _StoryLibraryPageState extends State<StoryLibraryPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filteredStories = _selectedCategory == null
        ? builtInStories
        : builtInStories.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('📚 故事库'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildCategoryFilter(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredStories.length,
              itemBuilder: (context, index) {
                final story = filteredStories[index];
                return _buildStoryCard(story);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF6C63FF),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('全部', null, '📚'),
          ...storyCategories.map((c) => _buildCategoryChip(c.name, c.name, c.icon)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category, String icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          '$icon $label',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: const Color(0xFFFF8C42), // 未选中：橙色
        selectedColor: const Color(0xFF1E90FF), // 选中：蓝色
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1E90FF) : const Color(0xFFFF6B1A),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuiltInStory story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/story-detail',
              arguments: {
                'title': story.title,
                'content': story.content,
                'category': story.category,
                'categoryIcon': story.categoryIcon,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(story.categoryIcon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.category} · 适合${story.minAge}-${story.maxAge}岁',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.content.length > 45 ? '${story.content.substring(0, 45)}...' : story.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB2BEC3)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Color(0xFF6C63FF), size: 32),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/story-detail',
                      arguments: {
                        'title': story.title,
                        'content': story.content,
                        'category': story.category,
                        'categoryIcon': story.categoryIcon,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
