import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/telemetry_data.dart';
import '../utils/lora_parser.dart';
import '../../modules/dashboard/components/console_panel.dart';

class SerialPortService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;

  final StreamController<TelemetryData> _streamController = StreamController<TelemetryData>.broadcast();
  final StreamController<ConsoleLog> _rawConsoleController = StreamController<ConsoleLog>.broadcast();

  // Buffer to accumulate data from serial port chunks
  final StringBuffer _rxBuffer = StringBuffer();

  Stream<TelemetryData> get telemetryStream => _streamController.stream;
  Stream<ConsoleLog> get rawConsoleStream => _rawConsoleController.stream;

  bool get isOpen => _port != null && _port!.isOpen;

  /// Mendapatkan daftar port serial yang tersedia di sistem
  static List<String> getAvailablePorts() {
    try {
      final ports = List<String>.from(SerialPort.availablePorts);
      // Sort COM ports numerically (COM3, COM4, COM5, COM10)
      ports.sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'\D'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'\D'), '')) ?? 0;
        return numA.compareTo(numB);
      });
      return ports;
    } catch (e) {
      debugPrint('Gagal mengambil daftar availablePorts: $e');
      return [];
    }
  }

  /// Memulai koneksi ke port serial dan mendengarkan data masuk
  bool connect(String portAddress, int baudRate) {
    disconnect();

    try {
      debugPrint('Menghubungkan ke Port Serial: $portAddress dengan Baud Rate: $baudRate');
      
      final available = getAvailablePorts();
      if (!available.contains(portAddress)) {
        debugPrint('Port serial $portAddress tidak terdeteksi di sistem.');
        return false;
      }

      final port = SerialPort(portAddress);

      bool opened = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        if (port.openReadWrite()) {
          opened = true;
          break;
        }
        if (attempt < 3) {
          sleep(const Duration(milliseconds: 150));
        }
      }

      if (!opened) {
        final err = SerialPort.lastError;
        debugPrint('Gagal membuka port serial $portAddress setelah 3x percobaan: $err');
        try {
          if (port.isOpen) {
            port.close();
          }
        } catch (_) {}
        return false;
      }

      // Konfigurasi port serial setelah dibuka
      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1;
      config.setFlowControl(SerialPortFlowControl.none);
      port.config = config;
      config.dispose(); // Bebaskan native config memory

      _port = port;
      _reader = SerialPortReader(port);

      _subscription = _reader!.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          debugPrint('Error pada stream serial port: $error');
          disconnect();
        },
        onDone: () {
          debugPrint('Stream serial port ditutup.');
          disconnect();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error saat menghubungkan serial: $e');
      disconnect();
      return false;
    }
  }

  /// Memutuskan koneksi port serial dan membersihkan resource secara aman (mencegah C FFI double-free & CRT assertion failure)
  void disconnect() {
    try {
      // 1. Batalkan subscription stream listener Dart
      _subscription?.cancel();
      _subscription = null;

      // 2. Tutup SerialPortReader terlebih dahulu agar background reader thread C di libserialport berhenti
      if (_reader != null) {
        try {
          _reader!.close();
        } catch (e) {
          debugPrint('Error closing SerialPortReader: $e');
        }
        _reader = null;
      }

      // 3. Tutup handle native SerialPort secara aman tanpa memanggil dispose() yang memicu CRT Heap Assertion Failure (double-free)
      if (_port != null) {
        try {
          if (_port!.isOpen) {
            _port!.close();
          }
        } catch (e) {
          debugPrint('Error closing SerialPort: $e');
        }
        _port = null;
      }

      _rxBuffer.clear();
      debugPrint('Koneksi Serial diputus secara aman.');
    } catch (e) {
      debugPrint('Error saat memutuskan koneksi serial: $e');
    }
  }

  /// Menangani data masuk dan merakit baris data biner / JSON
  void _handleIncomingData(Uint8List rawBytes) {
    try {
      final part = utf8.decode(rawBytes, allowMalformed: true);
      _rxBuffer.write(part);

      String bufferContent = _rxBuffer.toString();
      while (bufferContent.contains('\n')) {
        final index = bufferContent.indexOf('\n');
        final line = bufferContent.substring(0, index).trim();
        bufferContent = bufferContent.substring(index + 1);

        _rxBuffer.clear();
        _rxBuffer.write(bufferContent);

        if (line.isNotEmpty) {
          _processLine(line);
        }
      }
    } catch (e) {
      debugPrint('Gagal mendekode data masuk serial: $e');
    }
  }

  /// Memproses baris data mentah yang telah dirakit lengkap
  void _processLine(String line) {
    final bytes = Uint8List.fromList(utf8.encode(line));
    try {
      final telemetry = LoraParser.parse(bytes);

      if (!_streamController.isClosed) {
        _streamController.add(telemetry);
      }

      _emitConsoleLog(
        nodeId: telemetry.serialNumber,
        rawBytes: bytes,
        isValid: true,
        details: 'PARSED OK | CAGE: ${telemetry.cageCode}',
      );
    } catch (e) {
      debugPrint('Gagal mem-parse data LoRa dari baris serial: $e');
      _emitConsoleLog(
        nodeId: 'UNKNOWN',
        rawBytes: bytes,
        isValid: false,
        details: 'PARSE ERROR: $e',
      );
    }
  }

  void _emitConsoleLog({
    required String nodeId,
    required Uint8List rawBytes,
    required bool isValid,
    required String details,
  }) {
    if (!_rawConsoleController.isClosed) {
      _rawConsoleController.add(
        ConsoleLog(
          timestamp: DateTime.now(),
          nodeId: nodeId,
          rawBytes: rawBytes,
          isValid: isValid,
          details: details,
        ),
      );
    }
  }

  void dispose() {
    disconnect();
    _streamController.close();
    _rawConsoleController.close();
  }
}
