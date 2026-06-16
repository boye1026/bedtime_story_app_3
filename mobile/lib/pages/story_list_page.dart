import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class StoryListPage extends StatefulWidget {
  const StoryListPage({super.key});

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  List<Map<String, String>> _savedStories = [];
  final TTSService _ttsService = TTSService();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadStories();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _initTTS() async {
    await _ttsService.init();
    _ttsService.onComplete = () {
      if (mounted) {
        setState(() => _playingIndex = -1);
      }
    };
  }

  Future<void> _loadStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('saved_stories') ?? [];
      final parsedList = rawList.map((raw) {
        final parts = raw.split('||');
        return {
          'title': parts.isNotEmpty ? parts[0] : '未命名故事',
          'content': parts.length > 1 ? parts[1] : '',
        };
      }).toList();
      setState(() => _savedStories = parsedList);
    } catch (e) {
      debugPrint('加载故事失败: $e');
    }
  }

  Future<void> _deleteStory(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newList = List<String>.from(prefs.getStringList('saved_stories') ?? []);
      if (index < newList.length) {
        newList.removeAt(index);
        await prefs.setStringList('saved_stories', newList);
      }
      await _loadStories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('故事已删除')));
      }
    } catch (e) {
      debugPrint('删除故事失败: $e');
    }
  }

  Future<void> _togglePlay(String content, int index) async {
    if (_playingIndex == index) {
      await _ttsService.stop();
      setState(() => _playingIndex = -1);
    } else {
      await _ttsService.stop();
      await _ttsService.speak(content);
      setState(() => _playingIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的故事库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
          ),
        ],
      ),
      body: _savedStories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('还没有收藏的故事', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('去「生成故事」页面创作你的第一个故事吧',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/setup'),
                      child: const Text('去生成故事'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedStories.length,
              itemBuilder: (context, index) {
                final story = _savedStories[index];
                final title = story['title'] ?? '未命名故事';
                final content = story['content'] ?? '';
                final isPlaying = _playingIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ExpansionTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPlaying ? Icons.volume_up : Icons.auto_stories,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${content.length} 字',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _togglePlay(content, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteStory(index),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(content, style: const TextStyle(height: 1.6)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
