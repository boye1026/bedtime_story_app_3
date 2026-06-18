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
      // 设置 Android 选项
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ], IosTextToSpeechAudioMode.voicePrompt);

      // 设置中文女性声音参数
      // 语速稍慢，适合睡前故事
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45); // 稍慢的语速，更有感情
      await _flutterTts.setPitch(1.15); // 略高的音调，模拟女性温柔声音
      await _flutterTts.setVolume(0.9);

      // 尝试选择女性声音引擎
      try {
        final engines = await _flutterTts.getEngines;
        debugPrint('Available TTS engines: $engines');
        // 优先选择支持女性声音的引擎
        if (engines != null && engines is List) {
          for (final engine in engines) {
            if (engine.toString().contains('google') || 
                engine.toString().contains('xiaomi') ||
                engine.toString().contains('iflytek')) {
              await _flutterTts.setEngine(engine.toString());
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
