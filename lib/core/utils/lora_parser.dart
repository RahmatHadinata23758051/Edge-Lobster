import 'dart:convert';
import 'dart:typed_data';
import '../models/telemetry_data.dart';

class LoraParser {
  /// Memetakan raw byte stream dari serial port LoRa receiver ke objek TelemetryData.
  /// Mendukung payload JSON string langsung maupun yang didahului oleh karakter preamble sampah/noise.
  static TelemetryData parse(Uint8List payload) {
    try {
      // 1. Decode byte array ke string secara aman (mengizinkan malformed characters)
      final rawString = utf8.decode(payload, allowMalformed: true).trim();

      // 2. Cari karakter kurung kurawal pembuka '{'
      final jsonStart = rawString.indexOf('{');
      if (jsonStart == -1) {
        throw const FormatException('Payload serial tidak mengandung format JSON valid (kurang pembuka "{").');
      }

      // 3. Ambil substring mulai dari '{' sampai akhir string
      final jsonString = rawString.substring(jsonStart);

      // 4. Parse string tersebut ke Map JSON
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // 5. Instansiasi ke model TelemetryData
      return TelemetryData.fromJson(jsonMap);
    } catch (e) {
      throw FormatException('Gagal memproses data LoRa: $e');
    }
  }
}
