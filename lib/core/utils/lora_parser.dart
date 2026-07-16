import 'dart:typed_data';
import '../models/telemetry_data.dart';

class LoraParser {
  /// Memetakan biner payload LoRa sebesar 55 byte ke objek TelemetryData.
  /// Parameter [payload] adalah raw bytes dari serial port receiver.
  /// Parameter [serialNumber] adalah serial number IoT Node terkait.
  static TelemetryData parse(Uint8List payload, String serialNumber) {
    if (payload.length < 55) {
      throw ArgumentError('Payload LoRa tidak valid. Panjang harus 55 byte.');
    }

    // Membaca biner multi-byte (float32, int32, dll.) menggunakan ByteData
    final byteData = ByteData.sublistView(payload);

    // Kerangka Pemetaan Sementara (Akan disesuaikan besok dengan spesifikasi tim hardware)
    // Asumsi: data sensor dikirim dalam format Float Little Endian (masing-masing 4 bytes)
    final temp = byteData.getFloat32(0, Endian.little);
    final ph = byteData.getFloat32(4, Endian.little);
    final salinity = byteData.getFloat32(8, Endian.little);
    final dissolvedOxygen = byteData.getFloat32(12, Endian.little);
    final turbidity = byteData.getFloat32(16, Endian.little);
    final flowSpeed = byteData.getFloat32(20, Endian.little);

    final solarVoltage = byteData.getFloat32(24, Endian.little);
    final solarCurrent = byteData.getFloat32(28, Endian.little);
    final batteryVoltage = byteData.getFloat32(32, Endian.little);

    final latitude = byteData.getFloat32(36, Endian.little);
    final longitude = byteData.getFloat32(40, Endian.little);

    return TelemetryData(
      serialNumber: serialNumber,
      temperature: _sanitize(temp),
      ph: _sanitize(ph),
      salinity: _sanitize(salinity),
      dissolvedOxygen: _sanitize(dissolvedOxygen),
      turbidity: _sanitize(turbidity),
      flowSpeed: _sanitize(flowSpeed),
      solarVoltage: _sanitize(solarVoltage),
      solarCurrent: _sanitize(solarCurrent),
      batteryVoltage: _sanitize(batteryVoltage),
      latitude: double.parse(latitude.toStringAsFixed(6)),
      longitude: double.parse(longitude.toStringAsFixed(6)),
      timestamp: DateTime.now(),
    );
  }

  static double _sanitize(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return double.parse(value.toStringAsFixed(2));
  }
}
