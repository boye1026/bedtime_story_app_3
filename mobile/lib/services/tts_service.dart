import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  Function(String)? onError;
  VoidCallback? onCancel;
  Function(String, int, int)? onProgress;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 基础设置
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setVolume(1.0);

      // 设置为 Android 文本朗读模式 (支持长文本)
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _flutterTts.awaitSpeakCompletion(true);
        }
      } catch (_) {}

      // iOS 音频设置 (忽略失败)
      try {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      } catch (_) {}

      // 事件处理器
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        if (onStart != null) {
          try { onStart!(); } catch (_) {}
        }
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        if (onComplete != null) {
          try { onComplete!(); } catch (_) {}
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        if (onError != null) {
          try { onError!(msg.toString()); } catch (_) {}
        }
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        if (onCancel != null) {
          try { onCancel!(); } catch (_) {}
        }
      });

      // 进度/断句处理 (部分版本支持)
      try {
        _flutterTts.setProgressHandler((String text, int start, int end, String word) {
          if (onProgress != null) {
            try { onProgress!(text, start, end); } catch (_) {}
          }
        });
      } catch (_) {}

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS初始化异常: $e');
    }
  }

  /// 朗读文本 (支持长文本自动分段)
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      await init();
      // 先停止当前朗读
      try {
        await _flutterTts.stop();
      } catch (_) {}

      _isSpeaking = true;
      _isPaused = false;

      // 处理长文本：按句号/换行分段 (单段不超过 1000 字符)
      final List<String> segments = _splitText(text);
      if (segments.length == 1) {
        final dynamic result = await _flutterTts.speak(segments[0]);
        final success = result == 1 || result == true;
        if (!success) {
          _isSpeaking = false;
        }
      } else {
        // 分段朗读：依次播报
        for (int i = 0; i < segments.length; i++) {
          if (!_isSpeaking) break; // 用户已停止
          final dynamic result = await _flutterTts.speak(segments[i]);
          final success = result == 1 || result == true;
          if (!success) {
            await Future.delayed(const Duration(milliseconds: 200));
          } else {
            // 在 Android 上 awaitSpeakCompletion=true 会等待朗读完毕
            // 在 iOS 上需要等待回调，这里给一点间隔
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        _isSpeaking = false;
        if (onComplete != null) {
          try { onComplete!(); } catch (_) {}
        }
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }

  /// 将长文本切分为小段 (每段 <= 1000 字符，按语义标点断句)
  List<String> _splitText(String text) {
    if (text.length <= 1000) return [text];

    final List<String> result = [];
    final buffer = StringBuffer();
    final chars = text.split('');

    for (int i = 0; i < chars.length; i++) {
      buffer.write(chars[i]);
      // 在句号、感叹号、问号或换行处，如果当前段已超过 500 字符，则断段
      final ch = chars[i];
      final isEndPunct = ch == '。' || ch == '！' || ch == '？' || ch == '!' || ch == '?' || ch == '.' || ch == '\n';
      if (isEndPunct && buffer.length >= 500) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
      // 硬性上限：超过 1000 字符强制断段
      if (buffer.length >= 1000) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString().trim());
    }
    return result.where((s) => s.isNotEmpty).toList();
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      _isPaused = false;
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPaused = true;
    } catch (_) {
      // 某些平台不支持 pause，则退化为 stop
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
  bool get isPaused => _isPaused;

  void dispose() {
    try { stop(); } catch (_) {}
  }
}
