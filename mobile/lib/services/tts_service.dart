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
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setVolume(1.0);

      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _flutterTts.awaitSpeakCompletion(true);
        }
      } catch (_) {}

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
        if (onCancel != null) {
          try { onCancel!(); } catch (_) {}
        }
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
      // 先停止之前的朗读
      try { await _flutterTts.stop(); } catch (_) {}

      _isSpeaking = true;
      final dynamic result = await _flutterTts.speak(text);
      final success = result == 1 || result == true;
      if (!success) {
        _isSpeaking = false;
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (_) {
      // 如果平台不支持 pause, 则停止
      await stop();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 2.0));
    } catch (_) {}
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    try { stop(); } catch (_) {}
  }
}
