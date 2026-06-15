import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class StoryDisplayPage extends StatefulWidget {
  final String storyTitle;
  final String storyContent;

  const StoryDisplayPage({
    super.key,
    required this.storyTitle,
    required this.storyContent,
  });

  @override
  State<StoryDisplayPage> createState() => _StoryDisplayPageState();
}

class _StoryDisplayPageState extends State<StoryDisplayPage> {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;
  bool _isPaused = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _ttsService.init();
    _ttsService.onComplete = () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      }
    };
    _ttsService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音播放错误: $error')),
        );
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      }
    };
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _ttsService.pause();
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
    } else if (_isPaused) {
      _ttsService.resume();
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    } else {
      _ttsService.speak(widget.storyContent);
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    }
  }

  void _stopPlayback() {
    _ttsService.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storyTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 分享功能
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : 
                    (_isPaused ? Icons.play_circle_filled : Icons.play_circle_filled),
                    size: 48,
                    color: _isPlaying || _isPaused 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                  onPressed: _togglePlayback,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.stop_circle,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  onPressed: _stopPlayback,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.storyContent,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
