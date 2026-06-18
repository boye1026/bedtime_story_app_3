import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

      // 芒果姐姐风格 - 温柔、亲切的女性讲故事声音
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.42); // 较慢的语速，像姐姐讲故事
      await _flutterTts.setPitch(1.25); // 较高的音调，模拟年轻女性声音
      await _flutterTts.setVolume(0.95);

      // 尝试选择中文女性声音
      try {
        final voices = await _flutterTts.getVoices;
        debugPrint('Available voices: $voices');
        if (voices != null && voices is List) {
          for (final voice in voices) {
            final voiceStr = voice.toString().toLowerCase();
            if (voiceStr.contains('zh') && 
                (voiceStr.contains('female') || voiceStr.contains('xiaoxiao') || 
                 voiceStr.contains('jingjing') || voiceStr.contains('lili'))) {
              await _flutterTts.setVoice(voice);
              debugPrint('Selected voice: $voice');
              break;
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
          for (final engine in engines) {
            final engineStr = engine.toString().toLowerCase();
            if (engineStr.contains('google') || 
                engineStr.contains('xiaomi') ||
                engineStr.contains('iflytek') ||
                engineStr.contains('baidu')) {
              await _flutterTts.setEngine(engine.toString());
              debugPrint('Selected engine: $engine');
              break;
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
      debugPrint('TTS 初始化完成 - 女性温柔声音模式');
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
