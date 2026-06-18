import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class StoryGeneratePage extends StatefulWidget {
  const StoryGeneratePage({super.key});

  @override
  State<StoryGeneratePage> createState() => _StoryGeneratePageState();
}

class _StoryGeneratePageState extends State<StoryGeneratePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  String _generatedStory = '';
  bool _isLoading = false;
  bool _isPlaying = false;
  String _selectedStyle = 'fairy_tale';
  double _speechRate = 0.5;
  double _pitch = 1.0;

  final List<String> _interests = [];
  final List<String> _availableInterests = ['恐龙', '太空', '动物', '公主', '汽车', '魔法', '海洋', '机器人'];

  final Map<String, String> _styles = {
    'fairy_tale': '童话风',
    'adventure': '冒险风',
    'warm': '温馨风',
    'educational': '启蒙风',
  };

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadSavedInfo();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('child_name') ?? '';
        _ageController.text = prefs.getString('child_age') ?? '';
        _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
        _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
      });
    }
  }

  Future<void> _saveChildInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_name', _nameController.text);
    await prefs.setString('child_age', _ageController.text);
  }

  Future<void> _generateStory() async {
    if (_nameController.text.isEmpty) {
      _showMessage('请输入宝宝的名字');
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedStory = '';
    });

    await _saveChildInfo();

    try {
      final apiService = ApiService();
      final response = await apiService.generateStory(
        childName: _nameController.text,
        childAge: int.tryParse(_ageController.text) ?? 4,
        interests: _interests,
        style: _selectedStyle,
      );

      final dynamic codeRaw = response['code'];
      final int code = codeRaw is int ? codeRaw : 200;
      if (code == 403) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('免费次数已用完，请开通会员');
        }
        return;
      }

      final dynamic dataRaw = response['data'];
      final Map<String, dynamic>? data = dataRaw is Map ? Map<String, dynamic>.from(dataRaw) : null;

      if (mounted) {
        if (data != null) {
          final dynamic titleRaw = data['title'];
          final dynamic contentRaw = data['content'];
          final String title = titleRaw is String ? titleRaw : '';
          final String content = contentRaw is String ? contentRaw : '';
          setState(() {
            _generatedStory = title.isNotEmpty ? '$title\n\n$content' : content;
            _isLoading = false;
          });
        } else {
          final dynamic msgRaw = response['message'];
          final String msg = msgRaw is String ? msgRaw : '生成失败，请重试';
          setState(() {
            _generatedStory = msg;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('生成失败：${e.toString()}');
      }
    }
  }

  Future<void> _speakStory() async {
    if (_generatedStory.isEmpty) return;
    if (mounted) setState(() => _isPlaying = true);
    await _flutterTts.speak(_generatedStory);
  }

  Future<void> _pauseStory() async {
    await _flutterTts.pause();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _stopStory() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _saveStory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStories = prefs.getStringList('saved_stories') ?? [];
    savedStories.add(_generatedStory);
    await prefs.setStringList('saved_stories', savedStories);
    _showMessage('故事已保存到收藏');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生成故事'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👶 宝宝信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '宝宝名字',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: '年龄',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎈 兴趣爱好', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _interests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(interest);
                              } else {
                                _interests.remove(interest);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎨 故事风格', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styles.entries.map((entry) {
                        final isSelected = _selectedStyle == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStyle = entry.key;
                              });
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('✨ 生成故事', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedStory.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📖 你的故事', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _generatedStory,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // TTS控制面板
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  onPressed: _isPlaying ? _pauseStory : _speakStory,
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stop),
                                  onPressed: _stopStory,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('语速', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Slider(
                                    value: _speechRate,
                                    min: 0.3,
                                    max: 1.2,
                                    onChanged: (v) async {
                                      setState(() => _speechRate = v);
                                      await _flutterTts.setSpeechRate(v);
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setDouble('tts_rate', v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('音调', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Slider(
                                    value: _pitch,
                                    min: 0.5,
                                    max: 1.5,
                                    onChanged: (v) async {
                                      setState(() => _pitch = v);
                                      await _flutterTts.setPitch(v);
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setDouble('tts_pitch', v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveStory,
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('收藏'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
