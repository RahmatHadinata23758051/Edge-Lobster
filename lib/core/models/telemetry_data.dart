class TelemetryData {
  final String serialNumber;
  final String cageCode;
  final double temperature; // Maps to temperature_node / water_temperature
  final double ambientTemperature; // Maps to ambient_temperature
  final double ph;
  final double salinity; // Optional/legacy (default 0.0)
  final double tds;
  final double dissolvedOxygen; // Maps to raw_dissolved_oxygen / dissolved_oxygen
  final double turbidity;
  final double flowSpeed; // Maps to flow_rate / flow_speed
  final double solarVoltage;
  final double solarCurrent;
  final double batteryVoltage;
  final double batteryCurrent;
  final double latitude;
  final double longitude;
  final double altitude;
  final int pumpStatus; // 0: OFF, 1: ON (aktuator pompa/aerator)
  final DateTime timestamp;

  String get nodeId => serialNumber;

  TelemetryData({
    required this.serialNumber,
    required this.cageCode,
    required this.temperature,
    required this.ambientTemperature,
    required this.ph,
    this.salinity = 0.0,
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
    this.altitude = 0.0,
    this.pumpStatus = 0,
    required this.timestamp,
  });

  // Factory constructor untuk memetakan dari JSON serial (ESP32) / MQTT
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

    // Proteksi: Jika timestamp mikrokontroler (ESP32) melenceng > 10 menit dari jam aktual Gateway (PiPO), gunakan jam aktual Gateway
    final now = DateTime.now();
    if (parsedTime.isBefore(now.subtract(const Duration(minutes: 10))) ||
        parsedTime.isAfter(now.add(const Duration(minutes: 5)))) {
      parsedTime = now;
    }

    // Ekstrak nested map raw_values jika dikirim dari firmware baru ESP32
    final rawValues = json['raw_values'] is Map<String, dynamic>
        ? json['raw_values'] as Map<String, dynamic>
        : (json['raw_values'] is Map ? Map<String, dynamic>.from(json['raw_values'] as Map) : null);

    // Helper toleran untuk mengambil angka baik dari nested raw_values maupun root level
    num? extractNum(String key, [List<String>? aliases]) {
      if (rawValues != null && rawValues.containsKey(key)) {
        final val = rawValues[key];
        if (val is num) return val;
        if (val is String) return num.tryParse(val);
      }
      if (json.containsKey(key)) {
        final val = json[key];
        if (val is num) return val;
        if (val is String) return num.tryParse(val);
      }
      if (aliases != null) {
        for (final alias in aliases) {
          if (rawValues != null && rawValues.containsKey(alias)) {
            final val = rawValues[alias];
            if (val is num) return val;
            if (val is String) return num.tryParse(val);
          }
          if (json.containsKey(alias)) {
            final val = json[alias];
            if (val is num) return val;
            if (val is String) return num.tryParse(val);
          }
        }
      }
      return null;
    }

    return TelemetryData(
      serialNumber: (json['serial_number'] ?? json['serialNumber'] ?? '').toString(),
      cageCode: (json['cage_code'] ?? json['cageCode'] ?? 'CAGE-A01').toString(),
      temperature: (extractNum('temperature_node', ['water_temperature', 'temperature']))?.toDouble() ?? 0.0,
      ambientTemperature: (extractNum('ambient_temperature', ['ambientTemperature']))?.toDouble() ?? 0.0,
      ph: (extractNum('ph'))?.toDouble() ?? 0.0,
      salinity: (extractNum('salinity'))?.toDouble() ?? 0.0,
      tds: (extractNum('tds'))?.toDouble() ?? 0.0,
      dissolvedOxygen: (extractNum('raw_dissolved_oxygen', ['dissolved_oxygen', 'dissolvedOxygen']))?.toDouble() ?? 0.0,
      turbidity: (extractNum('turbidity'))?.toDouble() ?? 0.0,
      flowSpeed: (extractNum('flow_rate', ['flow_speed', 'flowRate', 'flowSpeed']))?.toDouble() ?? 0.0,
      solarVoltage: (extractNum('solar_voltage', ['solarVoltage']))?.toDouble() ?? 0.0,
      solarCurrent: (extractNum('solar_current', ['solarCurrent']))?.toDouble() ?? 0.0,
      batteryVoltage: (extractNum('battery_voltage', ['batteryVoltage']))?.toDouble() ?? 0.0,
      batteryCurrent: (extractNum('battery_current', ['batteryCurrent']))?.toDouble() ?? 0.0,
      latitude: (extractNum('latitude'))?.toDouble() ?? 0.0,
      longitude: (extractNum('longitude'))?.toDouble() ?? 0.0,
      altitude: (extractNum('altitude'))?.toDouble() ?? 0.0,
      pumpStatus: (extractNum('pump_status', ['pumpStatus']))?.toInt() ?? 0,
      timestamp: parsedTime,
    );
  }

  // Konversi objek ke map JSON untuk dipublikasikan via MQTT ke Backend
  Map<String, dynamic> toJson() {
    return {
      'serial_number': serialNumber,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'cage_code': cageCode,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'raw_values': {
        'temperature_node': temperature,
        'water_temperature': temperature,
        'ambient_temperature': ambientTemperature,
        'ph': ph,
        'salinity': salinity,
        'tds': tds,
        'raw_dissolved_oxygen': dissolvedOxygen,
        'dissolved_oxygen': dissolvedOxygen,
        'turbidity': turbidity,
        'flow_rate': flowSpeed,
        'solar_voltage': solarVoltage,
        'solar_current': solarCurrent,
        'battery_voltage': batteryVoltage,
        'battery_current': batteryCurrent,
        'pump_status': pumpStatus,
      },
      // Flat fields for backward compatibility
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
      'pump_status': pumpStatus,
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
      'altitude': altitude,
      'pump_status': pumpStatus,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
