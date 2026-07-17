import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GatewayStateProvider extends ChangeNotifier {
  // Connection states
  bool _isSerialConnected = true;
  bool _isMqttConnected = true;
  bool _isInternetConnected = true;

  // Active configurations with default values
  String _activePort = 'COM3';
  int _baudRate = 9600;
  
  String _activeNodeId = 'DEMO-NODE-001';
  String _rtspUrl = 'rtsp://192.168.100.50:554/stream1';

  String _mqttHost = '192.168.1.100';
  int _mqttPort = 1883;
  String _mqttUsername = 'edge_gateway';
  String _mqttPassword = 'edge_secret';

  bool _isInitialized = false;

  GatewayStateProvider() {
    _loadSettings();
  }

  // Getters
  bool get isSerialConnected => _isSerialConnected;
  bool get isMqttConnected => _isMqttConnected;
  bool get isInternetConnected => _isInternetConnected;
  
  String get activePort => _activePort;
  int get baudRate => _baudRate;
  
  String get activeNodeId => _activeNodeId;
  String get rtspUrl => _rtspUrl;

  String get mqttHost => _mqttHost;
  int get mqttPort => _mqttPort;
  String get mqttUsername => _mqttUsername;
  String get mqttPassword => _mqttPassword;

  bool get isInitialized => _isInitialized;

  // Load from Shared Preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activePort = prefs.getString('activePort') ?? 'COM3';
      _baudRate = prefs.getInt('baudRate') ?? 9600;
      _activeNodeId = prefs.getString('activeNodeId') ?? 'DEMO-NODE-001';
      _rtspUrl = prefs.getString('rtspUrl') ?? 'rtsp://192.168.100.50:554/stream1';
      _mqttHost = prefs.getString('mqttHost') ?? '192.168.1.100';
      _mqttPort = prefs.getInt('mqttPort') ?? 1883;
      _mqttUsername = prefs.getString('mqttUsername') ?? 'edge_gateway';
      _mqttPassword = prefs.getString('mqttPassword') ?? 'edge_secret';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  // State mutation actions
  void setSerialConnected(bool value) {
    if (_isSerialConnected != value) {
      _isSerialConnected = value;
      notifyListeners();
    }
  }

  void toggleSerial() {
    _isSerialConnected = !_isSerialConnected;
    notifyListeners();
  }

  void setMqttConnected(bool value) {
    if (_isMqttConnected != value) {
      _isMqttConnected = value;
      notifyListeners();
    }
  }

  void toggleMqtt() {
    _isMqttConnected = !_isMqttConnected;
    notifyListeners();
  }

  void setInternetConnected(bool value) {
    if (_isInternetConnected != value) {
      _isInternetConnected = value;
      notifyListeners();
    }
  }

  void toggleInternet() {
    _isInternetConnected = !_isInternetConnected;
    notifyListeners();
  }

  // Update Settings and persist to SharedPreferences
  Future<void> updateSettings({
    required String activePort,
    required int baudRate,
    required String activeNodeId,
    required String rtspUrl,
    required String mqttHost,
    required int mqttPort,
    required String mqttUsername,
    required String mqttPassword,
  }) async {
    _activePort = activePort;
    _baudRate = baudRate;
    _activeNodeId = activeNodeId;
    _rtspUrl = rtspUrl;
    _mqttHost = mqttHost;
    _mqttPort = mqttPort;
    _mqttUsername = mqttUsername;
    _mqttPassword = mqttPassword;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activePort', activePort);
      await prefs.setInt('baudRate', baudRate);
      await prefs.setString('activeNodeId', activeNodeId);
      await prefs.setString('rtspUrl', rtspUrl);
      await prefs.setString('mqttHost', mqttHost);
      await prefs.setInt('mqttPort', mqttPort);
      await prefs.setString('mqttUsername', mqttUsername);
      await prefs.setString('mqttPassword', mqttPassword);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }
}
