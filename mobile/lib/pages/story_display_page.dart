import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../models/child_info.dart';

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
    _ttsService.onStart = () {
      if (mounted) setState(() => _isPlaying = true);
    };
    _ttsService.onComplete = () {
      if (mounted) setState(() => _isPlaying = false);
    };
    _ttsService.onCancel = () {
      if (mounted) setState(() => _isPlaying = false);
    };
    _ttsService.onError = (_) {
      if (mounted) setState(() => _isPlaying = false);
    };
    _ttsService.init();

    if (widget.childInfo != null) {
      _generateStory();
    } else if (widget.storyContent != null && widget.storyTitle != null) {
      _storyTitle = widget.storyTitle!;
      _storyContent = widget.storyContent!;
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

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
    if (mounted) setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final response = await api.generateStory(
        childName: widget.childInfo!.name,
        childAge: widget.childInfo!.age,
        interests: widget.childInfo!.interests,
        style: _styleNameToKey(widget.childInfo!.storyStyle),
        directions: widget.childInfo!.educationDirections,
      );

      final dynamic codeRaw = response['code'];
      final int code = codeRaw is int ? codeRaw : 200;
      if (code == 403) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('免费次数已用完，请开通会员')),
          );
        }
        return;
      }

      final dynamic dataRaw = response['data'];
      final Map<String, dynamic>? data = dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : null;

      if (mounted) {
        if (data != null) {
          setState(() {
            final dynamic tRaw = data['title'];
            final dynamic cRaw = data['content'];
            _storyTitle = tRaw is String ? tRaw : '故事';
            _storyContent = cRaw is String ? cRaw : '';
            _isLoading = false;
          });
        } else {
          final dynamic msgRaw = response['message'];
          final String msg = msgRaw is String ? msgRaw : '生成失败';
          setState(() {
            _storyContent = msg;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：${e.toString()}')),
        );
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _ttsService.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _ttsService.speak(_storyContent);
    }
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          : _storyContent.isEmpty
              ? const Center(child: Text('没有故事内容'))
              : Column(
                  children: [
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
                            onPressed: _togglePlayback,
                          ),
                        ],
                      ),
                    ),
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
                        child: ElevatedButton.icon(
                          onPressed: _saveStory,
                          icon: const Icon(Icons.favorite_border, color: Colors.white),
                          label: const Text('收藏这个故事', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
