import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  static VoiceRecognitionService get instance => _instance;
  VoiceRecognitionService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    try {
      print('Initializing voice recognition...');
      
      // First check if speech recognition is available on the device
      _isAvailable = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (!_isAvailable) {
        print('Speech recognition not available on this device');
        return false;
      }

      // Then request microphone permission
      final permissionStatus = await Permission.microphone.request();
      print('Microphone permission status: $permissionStatus');
      
      if (permissionStatus != PermissionStatus.granted) {
        print('Microphone permission not granted');
        return false;
      }

      print('Voice recognition initialized successfully');
      return _isAvailable;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isAvailable || _isListening) {
      print('Cannot start listening: available=$_isAvailable, listening=$_isListening');
      return;
    }

    try {
      print('Starting to listen...');
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          print('Speech result: "${result.recognizedWords}", confidence: ${result.confidence}, final: ${result.finalResult}');
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
      print('Listen command sent successfully');
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  List<String> getAvailableLocales() {
    return ['en_US', 'en_GB', 'es_ES', 'fr_FR', 'de_DE']; // Common locales
  }
}
