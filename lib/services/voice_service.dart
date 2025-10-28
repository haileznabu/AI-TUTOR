import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      }

      final available = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      if (!available) {
        debugPrint('Speech recognition not available');
        return false;
      }

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartial,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartial != null) {
          onPartial(result.recognizedWords);
        }
      },
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
