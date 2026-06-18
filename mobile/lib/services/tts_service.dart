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
  Function(String)? onError;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setVolume(1.0);

      try {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      } catch (e) {
        debugPrint('TTS iOS 音频设置跳过: $e');
      }

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        if (onStart != null) {
          try { onStart!(); } catch (_) {}
        }
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        if (onComplete != null) {
          try { onComplete!(); } catch (_) {}
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (onError != null) {
          try { onError!(msg.toString()); } catch (_) {}
        }
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS初始化异常: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      await init();
      await stop();
      _isSpeaking = true;
      final dynamic result = await _flutterTts.speak(text);
      final success = result == 1 || result == true;
      if (!success) {
        _isSpeaking = false;
      }
    } catch (e) {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      // silent
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      // silent
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 2.0));
    } catch (e) {
      // silent
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      // silent
    }
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    try { stop(); } catch (_) {}
  }
}
