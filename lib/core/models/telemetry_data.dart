class TelemetryData {
  final String serialNumber;
  final String cageCode;
  final double temperature; // Maps to water_temperature
  final double ambientTemperature; // Maps to ambient_temperature
  final double ph;
  final double salinity;
  final double tds;
  final double dissolvedOxygen;
  final double turbidity;
  final double flowSpeed; // Maps to flow_rate
  final double solarVoltage;
  final double solarCurrent;
  final double batteryVoltage;
  final double batteryCurrent;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  String get nodeId => serialNumber;

  TelemetryData({
    required this.serialNumber,
    required this.cageCode,
    required this.temperature,
    required this.ambientTemperature,
    required this.ph,
    required this.salinity,
    required this.tds,
    required this.dissolvedOxygen,
    required this.turbidity,
    required this.flowSpeed,
    required this.solarVoltage,
    required this.solarCurrent,
    required this.batteryVoltage,
    required this.batteryCurrent,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Factory constructor untuk memetakan dari JSON serial / MQTT
  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['timestamp'];
    if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime * 1000);
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return TelemetryData(
      serialNumber: json['serial_number'] ?? '',
      cageCode: json['cage_code'] ?? '',
      temperature: (json['water_temperature'] as num?)?.toDouble() ?? 
                   (json['temperature'] as num?)?.toDouble() ?? 0.0,
      ambientTemperature: (json['ambient_temperature'] as num?)?.toDouble() ?? 0.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      salinity: (json['salinity'] as num?)?.toDouble() ?? 0.0,
      tds: (json['tds'] as num?)?.toDouble() ?? 0.0,
      dissolvedOxygen: (json['dissolved_oxygen'] as num?)?.toDouble() ?? 0.0,
      turbidity: (json['turbidity'] as num?)?.toDouble() ?? 0.0,
      flowSpeed: (json['flow_rate'] as num?)?.toDouble() ?? 
                 (json['flow_speed'] as num?)?.toDouble() ?? 0.0,
      solarVoltage: (json['solar_voltage'] as num?)?.toDouble() ?? 0.0,
      solarCurrent: (json['solar_current'] as num?)?.toDouble() ?? 0.0,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 0.0,
      batteryCurrent: (json['battery_current'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: parsedTime,
    );
  }

  // Konversi objek ke map JSON untuk dipublikasikan via MQTT
  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'cage_code': cageCode,
      'water_temperature': temperature,
      'ambient_temperature': ambientTemperature,
      'ph': ph,
      'salinity': salinity,
      'tds': tds,
      'dissolved_oxygen': dissolvedOxygen,
      'turbidity': turbidity,
      'flow_rate': flowSpeed,
      'solar_voltage': solarVoltage,
      'solar_current': solarCurrent,
      'battery_voltage': batteryVoltage,
      'battery_current': batteryCurrent,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Konversi objek ke map Database untuk SQLite Buffer
  Map<String, dynamic> toMap() {
    return {
      'serial_number': serialNumber,
      'cage_code': cageCode,
      'temperature': temperature,
      'ambient_temperature': ambientTemperature,
      'ph': ph,
      'salinity': salinity,
      'tds': tds,
      'dissolved_oxygen': dissolvedOxygen,
      'turbidity': turbidity,
      'flow_speed': flowSpeed,
      'solar_voltage': solarVoltage,
      'solar_current': solarCurrent,
      'battery_voltage': batteryVoltage,
      'battery_current': batteryCurrent,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
