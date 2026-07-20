import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/telemetry_data.dart';

/// Service responsible for streaming telemetry data from Edge Gateway to MQTT Broker.
class MqttPublisherService {
  MqttServerClient? _client;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _manualStopped = false;
  Timer? _reconnectTimer;
  int _reconnectDelaySeconds = 2;
  static const int _maxReconnectDelaySeconds = 32;

  String? _lastHost;
  int? _lastPort;
  String? _lastUsername;
  String? _lastPassword;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  final StreamController<String> _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  bool get isConnected => _isConnected;

  /// Connect to MQTT Broker with provided host, port, and authentication credentials.
  Future<bool> connectWithConfig({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _manualStopped = false;
    _lastHost = host;
    _lastPort = port;
    _lastUsername = username;
    _lastPassword = password;

    return _connectInternal();
  }

  Future<bool> _connectInternal() async {
    if (_manualStopped) return false;
    if (_isConnected) return true;
    if (_isConnecting) return false;
    if (_lastHost == null || _lastHost!.trim().isEmpty || _lastPort == null) return false;

    _isConnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _log('Memulai koneksi ke MQTT Broker: ${_lastHost!}:${_lastPort!}...');

    // Clean up any previous client instance cleanly
    if (_client != null) {
      _client!.onDisconnected = null;
      _client!.onConnected = null;
      try {
        _client!.disconnect();
      } catch (_) {}
      _client = null;
    }

    final String clientId = 'LobsenseEdge_${DateTime.now().millisecondsSinceEpoch}';
    final MqttServerClient client = MqttServerClient.withPort(_lastHost!, clientId, _lastPort!);
    _client = client;

    client.logging(on: false);
    client.setProtocolV311();
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 3000; // Native socket timeout in ms
    client.autoReconnect = false;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (_lastUsername != null && _lastUsername!.isNotEmpty) {
      connMessage.authenticateAs(_lastUsername!, _lastPassword ?? '');
    }

    client.connectionMessage = connMessage;

    try {
      // Direct await without Future.timeout wrapper to prevent orphan background sockets
      await client.connect();
    } catch (e) {
      _log('Gagal menghubungkan ke MQTT Broker: ${e.toString().split('\n').first}');
      _isConnecting = false;
      _setConnectionState(false);
      _scheduleReconnect();
      return false;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      _isConnecting = false;
      _isConnected = true;
      _reconnectDelaySeconds = 2; // Reset backoff delay on successful connection
      
      // Set callbacks AFTER successful connection
      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;

      _setConnectionState(true);
      _log('Berhasil terhubung ke MQTT Broker (${_lastHost!}:${_lastPort!}).');
      return true;
    } else {
      _log('Status koneksi MQTT: ${client.connectionStatus?.state}');
      _isConnecting = false;
      _setConnectionState(false);
      _scheduleReconnect();
      return false;
    }
  }

  void _setConnectionState(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(value);
      }
    }
  }

  void _onConnected() {
    _isConnected = true;
    _isConnecting = false;
    _reconnectDelaySeconds = 2;
    _setConnectionState(true);
    _log('Callback MQTT Terhubung aktif.');
  }

  void _onDisconnected() {
    _setConnectionState(false);
    _isConnecting = false;
    _log('Terputus dari MQTT Broker.');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualStopped) return;
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    _log('Menjadwalkan auto-reconnect MQTT dalam $_reconnectDelaySeconds detik...');
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () async {
      _reconnectTimer = null;
      if (!_manualStopped && !_isConnected && _lastHost != null) {
        // Exponential backoff calculation (2s -> 4s -> 8s -> 16s -> max 32s)
        _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(2, _maxReconnectDelaySeconds);
        try {
          await _connectInternal();
        } catch (e) {
          _log('Exception caught in reconnect timer: $e');
        }
      }
    });
  }

  /// Publish structured TelemetryData object as JSON payload to topic `lobsense/telemetry/{nodeId}`.
  Future<bool> publishTelemetry(TelemetryData data, {String? topicOverride}) async {
    final String payloadJson = jsonEncode(data.toJson());
    final String topic = topicOverride ?? 'lobsense/telemetry/${data.nodeId}';
    return publishString(payloadJson, topic: topic);
  }

  /// Publish raw string payload to specific topic.
  Future<bool> publishString(String payload, {required String topic}) async {
    if (!_isConnected || _client == null) {
      return false;
    }

    try {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      _log('MQTT Published ke [$topic]: $payload');
      return true;
    } catch (e) {
      _log('Gagal publish MQTT: $e');
      return false;
    }
  }

  /// Disconnect manually and stop reconnect timers.
  void disconnect() {
    _manualStopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (_client != null) {
      _client!.onDisconnected = null;
      _client!.onConnected = null;
      try {
        _client!.disconnect();
      } catch (_) {}
      _client = null;
    }
    _setConnectionState(false);
    _isConnecting = false;
    _log('MQTT Service dihentikan secara manual.');
  }

  void _log(String msg) {
    debugPrint('[MQTT_SERVICE] $msg');
    if (!_logController.isClosed) {
      _logController.add(msg);
    }
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _logController.close();
  }
}
