import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  VoidCallback? _onSpeakComplete;

  Future<bool> initializeTts() async {
    if (_isTtsInitialized) return true;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _onSpeakComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _onSpeakComplete?.call();
      });

      _isTtsInitialized = true;
      return true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
      return false;
    }
  }

  void setOnSpeakComplete(VoidCallback callback) {
    _onSpeakComplete = callback;
  }

  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      final initialized = await initializeTts();
      if (!initialized) {
        throw Exception('TTS not available');
      }
    }

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }
}
