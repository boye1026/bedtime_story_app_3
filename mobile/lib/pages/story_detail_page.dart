import 'package:flutter/material.dart';
import '../services/tts_service.dart';

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

  @override
  void initState() {
    super.initState();
    _ttsService.onStart = () {
      if (mounted) setState(() => _isSpeaking = true);
    };
    _ttsService.onComplete = () {
      if (mounted) setState(() => _isSpeaking = false);
    };
    _ttsService.onCancel = () {
      if (mounted) setState(() => _isSpeaking = false);
    };
    _ttsService.onError = (_) {
      if (mounted) setState(() => _isSpeaking = false);
    };
    _ttsService.init();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      await _ttsService.speak(widget.content);
    }
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
                  onPressed: _toggleSpeak,
                ),
                if (_isSpeaking)
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 36, color: Color(0xFFFF7675)),
                    onPressed: _toggleSpeak,
                  ),
              ],
            ),
          ),
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
