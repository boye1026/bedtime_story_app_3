import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 文本转语音服务
/// 单例模式，全局共享一个实例
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _currentText = '';
  bool _isSpeaking = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  Function(String)? onError;

  /// 初始化TTS引擎
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 设置中文语言
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setVolume(1.0);

      // iOS 特殊设置
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );

      // 设置回调
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
        debugPrint('TTS错误: $msg');
        if (onError != null) {
          try { onError!(msg.toString()); } catch (_) {}
        }
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('TTS初始化完成');
    } catch (e) {
      debugPrint('TTS初始化异常: $e');
    }
  }

  /// 朗读文本
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      await init();
      await stop();
      _currentText = text;

      // 将文本分段朗读（每段不超过200字，避免某些平台截断）
      final segments = _splitText(text);
      for (final segment in segments) {
        if (segment.trim().isEmpty) continue;
        await _flutterTts.awaitSpeakCompletion(true);
        final result = await _flutterTts.speak(segment);
        if (result != 1) {
          debugPrint('TTS朗读失败: segment="$segment"');
          break;
        }
      }
      _isSpeaking = false;
      if (onComplete != null) {
        try { onComplete!(); } catch (_) {}
      }
    } catch (e) {
      debugPrint('TTS朗读异常: $e');
      _isSpeaking = false;
      if (onError != null) {
        try { onError!(e.toString()); } catch (_) {}
      }
    }
  }

  /// 停止朗读
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS停止异常: $e');
    }
  }

  /// 暂停朗读
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS暂停异常: $e');
    }
  }

  /// 设置语速 0.0 - 2.0
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 2.0));
    } catch (e) {
      debugPrint('设置语速异常: $e');
    }
  }

  /// 设置音调 0.5 - 2.0
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('设置音调异常: $e');
    }
  }

  /// 是否正在朗读
  bool get isSpeaking => _isSpeaking;

  /// 清理资源
  void dispose() {
    try { stop(); } catch (_) {}
  }

  /// 将长文本拆分成合适的段落
  List<String> _splitText(String text) {
    final List<String> segments = [];
    final buffer = StringBuffer();
    int count = 0;

    for (final ch in text.characters) {
      buffer.write(ch);
      count++;
      // 在句末标点处分段，每段约150字
      if (count >= 150 && ('。！？！？'.contains(ch) || '，；：'.contains(ch))) {
        segments.add(buffer.toString());
        buffer.clear();
        count = 0;
      }
    }

    if (buffer.isNotEmpty) {
      segments.add(buffer.toString());
    }

    return segments.where((s) => s.trim().isNotEmpty).toList();
  }
}
