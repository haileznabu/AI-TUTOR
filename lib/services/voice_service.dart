import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  VoidCallback? _onSpeakComplete;

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

      _flutterTts.setCompletionHandler(() {
        _onSpeakComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _onSpeakComplete?.call();
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  bool get isListening => _speechToText.isListening;

  void setOnSpeakComplete(VoidCallback callback) {
    _onSpeakComplete = callback;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartial,
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartial != null) {
            onPartial(result.recognizedWords);
          }
        },
        listenMode: ListenMode.confirmation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        onSoundLevelChange: (level) {
          debugPrint('Sound level: $level');
        },
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
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
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
