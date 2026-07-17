import 'dart:async';
import 'dart:convert';
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

  final _streamController = StreamController<TelemetryData>.broadcast();
  final _rawConsoleController = StreamController<ConsoleLog>.broadcast();

  // Buffer to accumulate data from serial port chunks
  final StringBuffer _rxBuffer = StringBuffer();

  Stream<TelemetryData> get telemetryStream => _streamController.stream;
  Stream<ConsoleLog> get rawConsoleStream => _rawConsoleController.stream;

  bool get isOpen => _port != null && _port!.isOpen;

  // Mendapatkan daftar port serial yang tersedia di sistem
  static List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  /// Memulai koneksi ke port serial dan mendengarkan data masuk
  bool connect(String portAddress, int baudRate) {
    disconnect();

    try {
      debugPrint('Menghubungkan ke Port Serial: $portAddress dengan Baud Rate: $baudRate');
      
      // Validasi apakah port terdaftar di sistem
      if (!SerialPort.availablePorts.contains(portAddress)) {
        debugPrint('Port serial $portAddress tidak terdeteksi di sistem.');
        return false;
      }

      final port = SerialPort(portAddress);

      if (!port.openReadWrite()) {
        final err = SerialPort.lastError;
        debugPrint('Gagal membuka port serial: $err');
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
      config.dispose(); // Bebaskan native memory

      _port = port;
      _reader = SerialPortReader(port);

      _subscription = _reader!.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          debugPrint('Eror pada stream serial port: $error');
          disconnect();
        },
        onDone: () {
          debugPrint('Stream serial port ditutup.');
          disconnect();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Eror saat menghubungkan serial: $e');
      disconnect();
      return false;
    }
  }

  /// Memutuskan koneksi port serial dan membersihkan resource
  void disconnect() {
    try {
      _subscription?.cancel();
      _subscription = null;

      _reader?.close();
      _reader = null;

      if (_port != null) {
        if (_port!.isOpen) {
          _port!.close();
        }
        _port!.dispose();
        _port = null;
      }
      debugPrint('Koneksi Serial diputus.');
    } catch (e) {
      debugPrint('Eror saat memutuskan koneksi serial: $e');
    }
  }

  /// Menangani data masuk dan merakit baris data biner / JSON
  void _handleIncomingData(Uint8List rawBytes) {
    try {
      // Decode bytes ke string ascii/utf8 secara aman
      final part = utf8.decode(rawBytes, allowMalformed: true);
      _rxBuffer.write(part);

      // Cari baris baru (newline delimiter) yang menandakan akhir satu frame JSON
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
      // Coba parse menggunakan LoraParser
      final telemetry = LoraParser.parse(bytes);

      // Emit ke data stream telemetri utama
      if (!_streamController.isClosed) {
        _streamController.add(telemetry);
      }

      // Emit log konsol sukses
      _emitConsoleLog(
        nodeId: telemetry.serialNumber,
        rawBytes: bytes,
        isValid: true,
        details: 'PARSED OK | CAGE: ${telemetry.cageCode}',
      );
    } catch (e) {
      debugPrint('Gagal mem-parse data LoRa dari baris serial: $e');
      // Emit log konsol gagal
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
