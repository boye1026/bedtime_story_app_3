import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS服务
/// 当前使用 flutter_tts 调用系统TTS引擎
/// 注意：flutter_tts 调用的是系统级TTS，无法直接使用"芒果姐姐"等真实人声音频
/// 真实"芒果姐姐"声音需集成云端TTS API：
///   - 百度智能云TTS（支持明星声音如"度小萌"、"度博文"等）
///   - 讯飞开放平台TTS（支持"小燕"、"小婧"等女声）
///   - 阿里云语音合成TTS
///   - 腾讯云智聆语音TTS
/// 推荐使用：讯飞开放平台 https://www.xfyun.cn/services/online_tts ，
///   其"小婧"女声与芒果姐姐风格相近（温柔、亲切、适合儿童故事）
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  VoidCallback? onCancel;
  Function(String)? onError;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ], IosTextToSpeechAudioMode.voicePrompt);

      // 芒果姐姐风格 - 温柔、亲切、像姐姐讲故事的声音
      // 语速 0.38：较慢，像讲故事时温柔地讲述
      // 音调 1.30：较高，模拟年轻女性温柔声音
      // 音量 1.0：清晰
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.38);
      await _flutterTts.setPitch(1.30);
      await _flutterTts.setVolume(1.0);

      // 尝试选择中文女性声音（小米/小爱/晓晓/婷婷/小燕等）
      try {
        final voices = await _flutterTts.getVoices;
        debugPrint('Available voices: $voices');
        if (voices != null && voices is List) {
          // 优先尝试这些温柔女性声音名称
          final preferredNames = [
            'xiaoxiao', 'xiaoyi', 'xiaoyou', 'xiaomeng', 'xiaomo',
            'tingting', 'jingjing', 'lili', 'yating', 'hsiaoyu',
            'meijia', 'sophie', 'hui', 'mei', 'sara', 'catherine',
            'female', 'girl', 'woman', 'xiaomi', 'xiaoi', 'xiaoai',
            'mango', 'mangguo', 'jiemei', 'sister'
          ];
          for (final name in preferredNames) {
            for (final voice in voices) {
              final voiceStr = voice.toString().toLowerCase();
              if (voiceStr.contains(name) && (voiceStr.contains('zh') || voiceStr.contains('cn'))) {
                await _flutterTts.setVoice(voice);
                debugPrint('Selected voice: $voice');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Setting voice failed: $e');
      }

      // 尝试选择支持中文女性声音的引擎
      try {
        final engines = await _flutterTts.getEngines;
        debugPrint('Available TTS engines: $engines');
        if (engines != null && engines is List) {
          // 优先使用国内TTS引擎
          final preferredEngines = ['iflytek', 'baidu', 'xiaomi', 'tencent', 'alibaba'];
          for (final prefEngine in preferredEngines) {
            for (final engine in engines) {
              if (engine.toString().toLowerCase().contains(prefEngine)) {
                await _flutterTts.setEngine(engine.toString());
                debugPrint('Selected engine: $engine');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Setting engine failed: $e');
      }

      // 等待说话完成
      await _flutterTts.awaitSpeakCompletion(true);

      // 设置事件处理器
      _flutterTts.setStartHandler(() {
        debugPrint('TTS Start');
        _isSpeaking = true;
        if (onStart != null) {
          try { onStart!(); } catch (_) {}
        }
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS Complete');
        _isSpeaking = false;
        if (onComplete != null) {
          try { onComplete!(); } catch (_) {}
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        if (onError != null) {
          try { onError!(msg.toString()); } catch (_) {}
        }
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('TTS Cancel');
        _isSpeaking = false;
        if (onCancel != null) {
          try { onCancel!(); } catch (_) {}
        }
      });

      // 检查可用的语言和声音
      final languages = await _flutterTts.getLanguages;
      debugPrint('Available languages: $languages');

      _isInitialized = true;
      debugPrint('TTS 初始化完成 - 芒果姐姐风格（温柔女性声音）');
    } catch (e) {
      debugPrint('TTS 初始化异常: $e');
    }
  }

  Future<bool> speak(String text) async {
    if (text.isEmpty) return false;

    try {
      await init();

      // 停止之前的朗读
      await _flutterTts.stop();

      _isSpeaking = true;

      // 尝试设置中文语言，如果失败则使用默认
      final languages = await _flutterTts.getLanguages as List?;
      if (languages != null && languages.contains('zh-CN')) {
        await _flutterTts.setLanguage('zh-CN');
      } else if (languages != null && languages.contains('zh')) {
        await _flutterTts.setLanguage('zh');
      }

      final result = await _flutterTts.speak(text);
      debugPrint('TTS speak result: $result');

      if (result == 1 || result == true) {
        return true;
      } else {
        _isSpeaking = false;
        // 尝试使用默认语言
        try {
          // 获取可用语言并选择第一个
          final languages = await _flutterTts.getLanguages as List?;
          if (languages != null && languages.isNotEmpty) {
            await _flutterTts.setLanguage(languages.first.toString());
          }
        } catch (_) {}
        final retryResult = await _flutterTts.speak(text);
        return retryResult == 1 || retryResult == true;
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TTS pause error: $e');
      // 如果平台不支持 pause, 则停止
      await stop();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.1, 2.0);
      await _flutterTts.setSpeechRate(clampedRate);
    } catch (e) {
      debugPrint('TTS setSpeechRate error: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(clampedPitch);
    } catch (e) {
      debugPrint('TTS setPitch error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS setVolume error: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    try { stop(); } catch (_) {}
  }
}
