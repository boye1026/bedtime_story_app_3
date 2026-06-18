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
  double _speechRate = 0.5;

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
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    _ttsService.onStart = () {
      if (mounted) setState(() => _isPlaying = true);
    };
    _ttsService.onComplete = () {
      if (mounted) setState(() => _isPlaying = false);
    };
    _ttsService.onCancel = () {
      if (mounted) setState(() => _isPlaying = false);
    };
    _ttsService.onError = (msg) {
      if (mounted) setState(() => _isPlaying = false);
    };
    await _ttsService.init();
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
        // 会员限制
        if (mounted) {
          _showVipDialog();
        }
        return;
      }
      final dynamic dataRaw = response['data'];
      final Map<String, dynamic>? data = dataRaw as Map<String, dynamic>?;
      if (data != null) {
        if (mounted) {
          setState(() {
            final dynamic titleRaw = data['title'];
            final String title = titleRaw is String ? titleRaw : '故事';
            final dynamic contentRaw = data['content'];
            final String content = contentRaw is String ? contentRaw : '';
            _storyTitle = title;
            _storyContent = content;
          });
        }
      } else {
        final dynamic msgRaw = response['message'];
        final String msg = msgRaw is String ? msgRaw : '故事内容为空';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
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

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _ttsService.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (mounted) setState(() => _isPlaying = true);
      await _ttsService.speak(_storyContent);
      if (mounted) setState(() => _isPlaying = _ttsService.isSpeaking);
    }
  }

  Future<void> _stopPlayback() async {
    await _ttsService.stop();
    if (mounted) setState(() => _isPlaying = false);
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

  void _showVipDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✨ 开通会员', style: TextStyle(fontSize: 20)),
        content: const Text(
          '免费生成故事的次数已用完，开通会员即可无限生成专属睡前故事，还有数百个精选故事任你收听！',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后再说', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/membership');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('立即开通', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
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
                      child: Column(
                        children: [
                          Row(
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('语速', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Slider(
                                value: _speechRate,
                                min: 0.2,
                                max: 1.5,
                                onChanged: (v) {
                                  setState(() => _speechRate = v);
                                  _ttsService.setSpeechRate(v);
                                },
                              ),
                            ],
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
