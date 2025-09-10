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
      _isListening = true;
      print('Starting to listen...');
      
      await _speech.listen(
        onResult: (result) {
          if (result.hasConfidenceRating && result.confidence > 0.5) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          onDevice: false,
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: false,
        ),
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      print('Stopping speech recognition...');
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      print('Cancelling speech recognition...');
      await _speech.cancel();
      _isListening = false;
    }
  }

  Future<bool> hasMicrophone() async {
    try {
      return await _speech.hasPermission;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speech.locales();
      return locales.map((locale) => '${locale.name} (${locale.localeId})').toList();
    } catch (e) {
      print('Error getting available languages: $e');
      return ['English (en_US)'];
    }
  }
}