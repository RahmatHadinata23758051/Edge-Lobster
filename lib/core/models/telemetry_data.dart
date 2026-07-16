class TelemetryData {
  final String serialNumber;
  final double temperature;
  final double ph;
  final double salinity; // Salinitas / TDS
  final double dissolvedOxygen; // DO (Oksigen Terlarut)
  final double turbidity; // Kekeruhan
  final double flowSpeed; // Kecepatan Arus
  final double solarVoltage; // Tegangan Panel Surya
  final double solarCurrent; // Arus Panel Surya
  final double batteryVoltage; // Tegangan Aki/Baterai 12V
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TelemetryData({
    required this.serialNumber,
    required this.temperature,
    required this.ph,
    required this.salinity,
    required this.dissolvedOxygen,
    required this.turbidity,
    required this.flowSpeed,
    required this.solarVoltage,
    required this.solarCurrent,
    required this.batteryVoltage,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Factory constructor untuk memetakan dari JSON MQTT
  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      serialNumber: json['serial_number'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      salinity: (json['salinity'] as num?)?.toDouble() ?? 0.0,
      dissolvedOxygen: (json['dissolved_oxygen'] as num?)?.toDouble() ?? 0.0,
      turbidity: (json['turbidity'] as num?)?.toDouble() ?? 0.0,
      flowSpeed: (json['flow_speed'] as num?)?.toDouble() ?? 0.0,
      solarVoltage: (json['solar_voltage'] as num?)?.toDouble() ?? 0.0,
      solarCurrent: (json['solar_current'] as num?)?.toDouble() ?? 0.0,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  // Konversi objek ke map JSON untuk dipublikasikan via MQTT
  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'temperature': temperature,
      'ph': ph,
      'salinity': salinity,
      'dissolved_oxygen': dissolvedOxygen,
      'turbidity': turbidity,
      'flow_speed': flowSpeed,
      'solar_voltage': solarVoltage,
      'solar_current': solarCurrent,
      'battery_voltage': batteryVoltage,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Konversi objek ke map Database untuk SQLite Buffer
  Map<String, dynamic> toMap() {
    return {
      'serial_number': serialNumber,
      'temperature': temperature,
      'ph': ph,
      'salinity': salinity,
      'dissolved_oxygen': dissolvedOxygen,
      'turbidity': turbidity,
      'flow_speed': flowSpeed,
      'solar_voltage': solarVoltage,
      'solar_current': solarCurrent,
      'battery_voltage': batteryVoltage,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
