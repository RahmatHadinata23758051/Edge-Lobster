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
    final ambientTemp = 29.1 + (_random.nextDouble() * 2.0 - 1.0); // 28.1 - 30.1 C
    final ph = 7.42 + (_random.nextDouble() * 0.4 - 0.2); // 7.22 - 7.62
    final tds = 420.5 + (_random.nextDouble() * 20.0 - 10.0); // 410.5 - 430.5 ppm
    final salinity = 32.1 + (_random.nextDouble() * 2.0 - 1.0); // 31.1 - 33.1 ppt
    final doVal = 6.8 + (_random.nextDouble() * 1.0 - 0.5); // 6.3 - 7.3 mg/L
    final turbidity = 12.4 + (_random.nextDouble() * 4.0 - 2.0); // 10.4 - 14.4 NTU
    final flow = 0.35 + (_random.nextDouble() * 0.1 - 0.05); // 0.30 - 0.40 m/s
    
    // Solar Panel & Battery Power status
    final isDay = DateTime.now().hour >= 6 && DateTime.now().hour <= 18;
    final solarV = isDay ? 18.5 + (_random.nextDouble() * 2.0 - 1.0) : 0.0;
    final solarA = isDay ? 1.25 + (_random.nextDouble() * 0.4 - 0.2) : 0.0;
    final batteryV = 12.6 + (_random.nextDouble() * 0.4 - 0.2); // 12.4V - 12.8V
    final batteryA = 0.8 + (_random.nextDouble() * 0.2 - 0.1); // 0.7A - 0.9A

    // Koordinat GPS Lombok Barat (Sekotong)
    final lat = -8.6529 + (_random.nextDouble() * 0.002 - 0.001);
    final lon = 116.3195 + (_random.nextDouble() * 0.002 - 0.001);

    return TelemetryData(
      serialNumber: serialNumber,
      cageCode: 'CAGE-A01',
      temperature: double.parse(temp.toStringAsFixed(2)),
      ambientTemperature: double.parse(ambientTemp.toStringAsFixed(2)),
      ph: double.parse(ph.toStringAsFixed(2)),
      salinity: double.parse(salinity.toStringAsFixed(2)),
      tds: double.parse(tds.toStringAsFixed(2)),
      dissolvedOxygen: double.parse(doVal.toStringAsFixed(2)),
      turbidity: double.parse(turbidity.toStringAsFixed(2)),
      flowSpeed: double.parse(flow.toStringAsFixed(2)),
      solarVoltage: double.parse(solarV.toStringAsFixed(2)),
      solarCurrent: double.parse(solarA.toStringAsFixed(2)),
      batteryVoltage: double.parse(batteryV.toStringAsFixed(2)),
      batteryCurrent: double.parse(batteryA.toStringAsFixed(2)),
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
