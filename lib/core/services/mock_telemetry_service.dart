import 'dart:async';
import 'dart:math';
import '../models/telemetry_data.dart';

class MockTelemetryService {
  final _random = Random();
  Timer? _timer;
  final _streamController = StreamController<TelemetryData>.broadcast();

  // Serial number default untuk data tiruan
  String _activeSerial = 'DEMO-NODE-001';

  Stream<TelemetryData> get telemetryStream => _streamController.stream;

  void startGenerating(String serialNumber) {
    _activeSerial = serialNumber;
    _timer?.cancel();
    
    // Generate data langsung saat dimulai
    _generateAndAdd();

    // Kirim data baru setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _generateAndAdd();
    });
  }

  void stopGenerating() {
    _timer?.cancel();
    _timer = null;
  }

  void _generateAndAdd() {
    if (!_streamController.isClosed) {
      _streamController.add(generateMockData(_activeSerial));
    }
  }

  TelemetryData generateMockData(String serialNumber) {
    // Fluktuasi sensor kualitas air realistis
    final temp = 27.5 + (_random.nextDouble() * 2.0 - 1.0); // 26.5 - 28.5 C
    final ph = 7.8 + (_random.nextDouble() * 0.8 - 0.4); // 7.4 - 8.2
    final salinity = 31.0 + (_random.nextDouble() * 4.0 - 2.0); // 29 - 33 ppt
    final doVal = 6.2 + (_random.nextDouble() * 2.0 - 1.0); // 5.2 - 7.2 mg/L
    final turbidity = 5.5 + (_random.nextDouble() * 6.0 - 3.0); // 2.5 - 8.5 NTU
    final flow = 0.3 + (_random.nextDouble() * 0.2 - 0.1); // 0.2 - 0.4 m/s
    
    // Solar Panel & Battery Power status
    final isDay = DateTime.now().hour >= 6 && DateTime.now().hour <= 18;
    final solarV = isDay ? 17.2 + (_random.nextDouble() * 2.0 - 1.0) : 0.0;
    final solarA = isDay ? 1.5 + (_random.nextDouble() * 0.8 - 0.4) : 0.0;
    final batteryV = 12.6 + (_random.nextDouble() * 0.6 - 0.3); // 12.3V - 12.9V

    // Koordinat GPS Lombok Barat (Sekotong)
    final lat = -8.7233 + (_random.nextDouble() * 0.002 - 0.001);
    final lon = 115.9083 + (_random.nextDouble() * 0.002 - 0.001);

    return TelemetryData(
      serialNumber: serialNumber,
      temperature: double.parse(temp.toStringAsFixed(2)),
      ph: double.parse(ph.toStringAsFixed(2)),
      salinity: double.parse(salinity.toStringAsFixed(2)),
      dissolvedOxygen: double.parse(doVal.toStringAsFixed(2)),
      turbidity: double.parse(turbidity.toStringAsFixed(2)),
      flowSpeed: double.parse(flow.toStringAsFixed(2)),
      solarVoltage: double.parse(solarV.toStringAsFixed(2)),
      solarCurrent: double.parse(solarA.toStringAsFixed(2)),
      batteryVoltage: double.parse(batteryV.toStringAsFixed(2)),
      latitude: double.parse(lat.toStringAsFixed(6)),
      longitude: double.parse(lon.toStringAsFixed(6)),
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    stopGenerating();
    _streamController.close();
  }
}
