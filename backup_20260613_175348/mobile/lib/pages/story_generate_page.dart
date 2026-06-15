import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

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
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
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
    
    // 模拟AI生成故事
    await Future.delayed(const Duration(seconds: 2));
    
    final story = _generateMockStory();
    
    if (mounted) {
      setState(() {
        _generatedStory = story;
        _isLoading = false;
      });
    }
  }
  
  String _generateMockStory() {
    final name = _nameController.text;
    final age = _ageController.text.isEmpty ? '?' : _ageController.text;
    final styleName = _styles[_selectedStyle] ?? '童话风';
    final interestsText = _interests.isEmpty ? '' : '喜欢';
    
    final stories = {
      'fairy_tale': '''
【标题：的魔法梦境】

从前，在一个充满魔法的森林里，住着一个叫的小朋友。

今年岁，。一天晚上，发现床边出现了一颗闪闪发光的星星。

"跟我来吧，我带你去一个神奇的地方！"星星说。

跟着星星穿过彩虹桥，来到了梦幻王国。在这里，遇到了会说话的兔子、会跳舞的花朵，还帮助了迷路的小精灵找到回家的路。

最后，星星把安全送回了家。做了一个甜甜的梦，第二天醒来，觉得自己变得更加勇敢和善良了。

晚安，亲爱的，愿你有个好梦。✨
      ''',
      'adventure': '''
【标题：的星空冒险】

是一个充满好奇心的小朋友。今晚，决定去探索神秘的星空！

穿上宇航服，乘坐着梦想飞船，飞向了浩瀚的宇宙。在月球上，遇到了友好的外星人小蓝。他们一起在太空中漂浮，欣赏着美丽的地球。

学会了勇敢和合作，明白了只要敢于尝试，就没有做不到的事情。

这次冒险让变得更加自信。回到床上，带着微笑进入梦乡。🚀
      ''',
      'warm': '''
【标题：晚安，】

月亮婆婆升起来了，星星们也眨着眼睛。躺在温暖的小床上，听着妈妈的摇篮曲。

抱着心爱的小熊，感觉特别安心。窗外，夜风轻轻吹过，带来花香。

"晚安，，明天又是充满希望的一天。"

闭上眼睛，很快就进入了甜甜的梦乡。在梦里，和所有喜欢的事物在一起，开心地笑着。

晚安，愿爱陪伴你入眠。🌙
      ''',
      'educational': '''
【标题：认识小动物】

今年岁了，今天要学习认识可爱的小动物。

首先，遇到了一只勤劳的小蜜蜂，它每天采蜜，教我们要勤奋工作。

接着，看到了一群蚂蚁，它们团结合作，一起搬运食物，教我们要互相帮助。

最后，和一只聪明的海豚交了朋友，海豚教我们在困难面前要动脑筋。

通过这次学习，明白了许多道理。的小朋友一定会成为最棒的孩子！🐝
      ''',
    };
    
    return stories[_selectedStyle] ?? stories['fairy_tale']!;
  }

  Future<void> _speakStory() async {
    if (_generatedStory.isEmpty) return;
    
    if (mounted) {
      setState(() => _isPlaying = true);
    }
    await _flutterTts.speak(_generatedStory);
  }

  Future<void> _stopStory() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 宝宝信息卡片
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
            
            // 兴趣爱好
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
                          backgroundColor: Colors.grey[200],
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 故事风格
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
                          backgroundColor: Colors.grey[200],
                          selectedColor: AppTheme.primaryColor,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('✨ 生成故事', style: TextStyle(fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 生成的故事
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
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _generatedStory,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isPlaying ? null : _speakStory,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('播放'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _stopStory,
                              icon: const Icon(Icons.stop),
                              label: const Text('停止'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
