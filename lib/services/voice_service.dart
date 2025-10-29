import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  FlutterTts? _flutterTts;
  bool _isTtsInitialized = false;
  VoidCallback? _onSpeakComplete;

  Future<bool> initializeTts() async {
    if (_isTtsInitialized && _flutterTts != null) return true;

    try {
      _flutterTts = FlutterTts();

      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setCompletionHandler(() {
        _onSpeakComplete?.call();
      });

      _flutterTts!.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _onSpeakComplete?.call();
      });

      _flutterTts!.setCancelHandler(() {
        _onSpeakComplete?.call();
      });

      _isTtsInitialized = true;
      return true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
      _isTtsInitialized = false;
      _flutterTts = null;
      return false;
    }
  }

  void setOnSpeakComplete(VoidCallback callback) {
    _onSpeakComplete = callback;
  }

  Future<void> speak(String text) async {
    if (!_isTtsInitialized || _flutterTts == null) {
      final initialized = await initializeTts();
      if (!initialized || _flutterTts == null) {
        throw Exception('TTS not available');
      }
    }

    try {
      await _flutterTts!.stop();
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.stop();
      } catch (e) {
        debugPrint('TTS stop error: $e');
      }
    }
  }

  void dispose() {
    if (_flutterTts != null) {
      try {
        _flutterTts!.stop();
      } catch (e) {
        debugPrint('TTS dispose error: $e');
      }
    }
  }
}
