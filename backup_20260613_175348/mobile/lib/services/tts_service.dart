import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  String _currentText = '';
  bool _isSpeaking = false;
  bool _isPaused = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  Function(String)? onError;

  Future<void> init() async {
    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        if (onStart != null) onStart!();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        if (onComplete != null) onComplete!();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        if (onError != null) onError!(msg);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    } catch (e) {
      debugPrint('TTS初始化错误: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await stop();
      _currentText = text;
      final result = await _flutterTts.speak(text);
      if (result == 1) {
        _isSpeaking = true;
        _isPaused = false;
      }
    } catch (e) {
      debugPrint('TTS朗读错误: $e');
      if (onError != null) onError!(e.toString());
    }
  }

  Future<void> pause() async {
    try {
      final result = await _flutterTts.pause();
      if (result == 1) {
        _isPaused = true;
        _isSpeaking = false;
      }
    } catch (e) {
      debugPrint('TTS暂停错误: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_isPaused && _currentText.isNotEmpty) {
        final result = await _flutterTts.speak(_currentText);
        if (result == 1) {
          _isSpeaking = true;
          _isPaused = false;
        }
      }
    } catch (e) {
      debugPrint('TTS恢复错误: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
    } catch (e) {
      debugPrint('TTS停止错误: $e');
    }
  }

  void dispose() {
    stop();
    // 移除 Null 赋值，直接设置回调
    _flutterTts.setStartHandler(() {});
    _flutterTts.setCompletionHandler(() {});
    _flutterTts.setErrorHandler((msg) {});
    _flutterTts.setCancelHandler(() {});
  }

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
}
