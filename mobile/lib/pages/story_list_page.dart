import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'story_detail_page.dart';

class StoryListPage extends StatefulWidget {
  const StoryListPage({super.key});

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  List<String> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stories = prefs.getStringList('saved_stories') ?? [];
    });
  }

  Future<void> _deleteStory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stories.removeAt(index);
      prefs.setStringList('saved_stories', _stories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('故事列表'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _stories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.library_books_outlined,
                    size: 72,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无故事，快去首页生成一个吧',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final parts = _stories[index].split('||');
                if (parts.length < 2) return const SizedBox.shrink();
                final title = parts[0];
                final content = parts.sublist(1).join('||');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark, color: Color(0xFF6C63FF), size: 28),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      content.length > 60 ? '${content.substring(0, 60)}...' : content,
                      maxLines: 2,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFF7675)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('确定要删除这个故事吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7675),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _deleteStory(index);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryDetailPage(
                            title: title,
                            content: content,
                            category: '收藏',
                            categoryIcon: '⭐',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
