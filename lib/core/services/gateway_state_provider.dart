import 'package:flutter/material.dart';

class GatewayStateProvider extends ChangeNotifier {
  // Connection states
  bool _isSerialConnected = true;
  bool _isMqttConnected = true;
  bool _isInternetConnected = true;

  // Active configurations
  String _activePort = 'COM3';
  String _activeNodeId = 'DEMO-NODE-001';
  String _rtspUrl = 'rtsp://192.168.100.50:554/stream1';

  // Getters
  bool get isSerialConnected => _isSerialConnected;
  bool get isMqttConnected => _isMqttConnected;
  bool get isInternetConnected => _isInternetConnected;
  String get activePort => _activePort;
  String get activeNodeId => _activeNodeId;
  String get rtspUrl => _rtspUrl;

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

  void updateSettings({
    required String activePort,
    required String activeNodeId,
    required String rtspUrl,
  }) {
    _activePort = activePort;
    _activeNodeId = activeNodeId;
    _rtspUrl = rtspUrl;
    notifyListeners();
  }
}
