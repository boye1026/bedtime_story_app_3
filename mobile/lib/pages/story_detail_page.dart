import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';

/// 故事详情页 - 展示完整故事内容，支持语音朗读
class StoryDetailPage extends StatefulWidget {
  final String title;
  final String content;
  final String category;
  final String categoryIcon;

  const StoryDetailPage({
    super.key,
    required this.title,
    required this.content,
    required this.category,
    required this.categoryIcon,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  final TTSService _ttsService = TTSService();
  bool _isSpeaking = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await _ttsService.init();
      _ttsService.onStart = () {
        if (mounted) setState(() => _isSpeaking = true);
      };
      _ttsService.onComplete = () {
        if (mounted) setState(() => _isSpeaking = false);
      };
      _ttsService.onError = (msg) {
        if (mounted) setState(() => _isSpeaking = false);
        debugPrint('TTS Error: $msg');
      };
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _ttsService.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
    } else {
      // 检查是否可以收听
      final api = ApiService();
      final status = await api.getVipStatus();
      final isVip = status['data']['is_vip'] as bool? ?? false;
      final remaining = status['data']['remaining_free_listen'] as int? ?? 3;

      if (!isVip && remaining <= 0) {
        _showVipModal();
        return;
      }

      // 记录一次
      if (!isVip) {
        await api.recordListen();
      }

      try {
        setState(() => _isLoading = true);
        await _ttsService.speak(widget.content);
      } catch (e) {
        debugPrint('朗读出错: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showVipModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ 开通会员'),
        content: const Text(
          '免费故事已听完，开通会员可无限收听所有故事！\n\n还可以无限次AI生成专属故事哦～',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/membership');
            },
            child: const Text('立即开通'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // TTS 控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.categoryIcon} ${widget.category}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6C63FF)),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 44,
                    color: const Color(0xFF6C63FF),
                  ),
                  onPressed: _isLoading ? null : _toggleSpeak,
                ),
                if (_isSpeaking)
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 36, color: Color(0xFFFF7675)),
                    onPressed: () async {
                      await _ttsService.stop();
                      setState(() => _isSpeaking = false);
                    },
                  ),
              ],
            ),
          ),
          // 故事内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.content,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 2.0,
                    color: Color(0xFF2D3436),
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
