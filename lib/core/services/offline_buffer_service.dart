import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/telemetry_data.dart';
import 'mqtt_publisher_service.dart';

/// Service buffer data offline menggunakan SQLite (sqflite_common_ffi)
/// Menyimpan data sensor LoRa ke database lokal ketika internet/MQTT terputus,
/// dan otomatis memicu Auto-Flush (FIFO) saat koneksi MQTT terhubung kembali.
class OfflineBufferService {
  static final OfflineBufferService _instance = OfflineBufferService._internal();
  factory OfflineBufferService() => _instance;
  OfflineBufferService._internal();

  Database? _db;
  bool _isInitializing = false;
  bool _isFlushing = false;

  /// Notifier untuk update jumlah data pending di UI secara reaktif
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  bool get isInitialized => _db != null;

  /// Inisialisasi database SQLite FFI di Windows / Desktop
  Future<void> init() async {
    if (_db != null || _isInitializing) return;
    _isInitializing = true;

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docsDir.path, 'lobsense_edge_buffer.db');

      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE telemetry_buffer (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              serial_number TEXT NOT NULL,
              cage_code TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );

      debugPrint('[OFFLINE_BUFFER] Database SQLite terinisialisasi di: $dbPath');
      await refreshPendingCount();
    } catch (e) {
      debugPrint('[OFFLINE_BUFFER] Gagal menginisialisasi database SQLite: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Memperbarui jumlah record pending yang belum terkirim di SQLite
  Future<int> refreshPendingCount() async {
    if (_db == null) return 0;
    try {
      final result = await _db!.rawQuery('SELECT COUNT(*) FROM telemetry_buffer');
      final count = result.isNotEmpty ? (result.first.values.first as int? ?? 0) : 0;

      pendingCountNotifier.value = count;
      return count;
    } catch (e) {
      debugPrint('[OFFLINE_BUFFER] Error menghitung pending count: $e');
      return 0;
    }
  }

  /// Menyimpan data telemetry ke dalam database buffer lokal SQLite
  Future<int> insertTelemetry(TelemetryData data) async {
    if (_db == null) {
      await init();
    }
    if (_db == null) return -1;

    try {
      final payloadJson = jsonEncode(data.toJson());
      final id = await _db!.insert(
        'telemetry_buffer',
        {
          'serial_number': data.serialNumber,
          'cage_code': data.cageCode,
          'payload_json': payloadJson,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('[OFFLINE_BUFFER] Data offline #${data.serialNumber} tersimpan di SQLite (ID: $id)');
      await refreshPendingCount();
      return id;
    } catch (e) {
      debugPrint('[OFFLINE_BUFFER] Gagal menyimpan telemetry ke SQLite: $e');
      return -1;
    }
  }

  /// Melakukan Auto-Flush / Re-sync data tunda dari SQLite ke MQTT Broker secara FIFO (First-In, First-Out)
  Future<void> flushBuffer(MqttPublisherService mqttService) async {
    if (_db == null || _isFlushing || !mqttService.isConnected) return;
    _isFlushing = true;

    try {
      final List<Map<String, dynamic>> records = await _db!.query(
        'telemetry_buffer',
        orderBy: 'id ASC',
        limit: 20,
      );

      if (records.isEmpty) {
        await refreshPendingCount();
        _isFlushing = false;
        return;
      }

      debugPrint('[OFFLINE_BUFFER] Memulai Auto-Flush ${records.length} data pending ke MQTT Broker...');

      for (final record in records) {
        if (!mqttService.isConnected) {
          debugPrint('[OFFLINE_BUFFER] Koneksi MQTT terputus di tengah batch flush.');
          break;
        }

        final int id = record['id'] as int;
        final String payloadJson = record['payload_json'] as String;

        final ok = await mqttService.publishString(payloadJson, topic: 'lobsense/telemetry');
        if (ok) {
          await _db!.delete(
            'telemetry_buffer',
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint('[OFFLINE_BUFFER] Record #$id berhasil di-flush & dihapus dari SQLite');
        } else {
          debugPrint('[OFFLINE_BUFFER] Gagal publish Record #$id, menghentikan batch flush');
          break;
        }
      }

      final remaining = await refreshPendingCount();

      // Jika masih ada sisa data pending di SQLite dan MQTT masih terhubung, lanjutkan ke batch berikutnya
      if (remaining > 0 && mqttService.isConnected) {
        _isFlushing = false;
        Future.delayed(
          const Duration(milliseconds: 150),
          () => flushBuffer(mqttService),
        );
      }
    } catch (e) {
      debugPrint('[OFFLINE_BUFFER] Error saat melalukan flush buffer: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Membersihkan database saat aplikasi ditutup
  Future<void> dispose() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
