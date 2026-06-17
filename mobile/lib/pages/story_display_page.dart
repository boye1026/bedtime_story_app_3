import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../models/child_info.dart';

/// 故事展示页
/// 支持生成故事并展示、TTS朗读、收藏
class StoryDisplayPage extends StatefulWidget {
  final ChildInfo? childInfo;
  final String? storyTitle;
  final String? storyContent;

  const StoryDisplayPage({
    super.key,
    this.childInfo,
    this.storyTitle,
    this.storyContent,
  });

  @override
  State<StoryDisplayPage> createState() => _StoryDisplayPageState();
}

class _StoryDisplayPageState extends State<StoryDisplayPage> {
  final TTSService _ttsService = TTSService();
  bool _isLoading = false;
  String _storyTitle = '';
  String _storyContent = '';
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    if (widget.childInfo != null) {
      _generateStory();
    } else if (widget.storyContent != null && widget.storyTitle != null) {
      _storyTitle = widget.storyTitle!;
      _storyContent = widget.storyContent!;
    }
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
        setState(() => _isPlaying = false);
      }
    };
  }

  /// 将中文风格名映射为英文后端风格名
  String _styleNameToKey(String name) {
    switch (name) {
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

  Future<void> _generateStory() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final response = await api.generateStory(
        childName: widget.childInfo!.name,
        childAge: widget.childInfo!.age,
        interests: widget.childInfo!.interests,
        style: _styleNameToKey(widget.childInfo!.storyStyle),
        directions: widget.childInfo!.educationDirections,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _storyTitle = data['title'] ?? '给${widget.childInfo?.name ?? '宝贝'}的睡前故事';
          _storyContent = data['content'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _ttsService.pause();
      setState(() => _isPlaying = false);
    } else {
      await _ttsService.speak(_storyContent);
      setState(() => _isPlaying = true);
    }
  }

  void _stopPlayback() async {
    await _ttsService.stop();
    setState(() => _isPlaying = false);
  }

  Future<void> _saveStory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStories = prefs.getStringList('saved_stories') ?? [];
      savedStories.add('$_storyTitle||$_storyContent');
      await prefs.setStringList('saved_stories', savedStories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('故事已收藏')),
        );
      }
    } catch (e) {
      debugPrint('保存故事失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isLoading ? '正在生成...' : _storyTitle.isNotEmpty ? _storyTitle : '睡前故事'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI正在为${widget.childInfo?.name ?? '宝贝'}创作故事...',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _storyContent.isEmpty
              ? const Center(child: Text('没有故事内容'))
              : Column(
                  children: [
                    // TTS 控制栏
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            onPressed: _togglePlayback,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.stop_circle, size: 48, color: Colors.redAccent),
                            onPressed: _stopPlayback,
                          ),
                        ],
                      ),
                    ),
                    // 故事内容
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _storyContent,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // 底部收藏按钮
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _saveStory,
                          icon: const Icon(Icons.favorite_border, color: AppColors.primary),
                          label: const Text('收藏这个故事'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
