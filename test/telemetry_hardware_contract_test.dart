import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lobsense_edge_app/core/models/telemetry_data.dart';
import 'package:lobsense_edge_app/core/utils/lora_parser.dart';

void main() {
  group('Hardware Payload Contract Test', () {
    test('parses new ESP32 hardware JSON payload correctly', () {
      const rawJson = '''
      {
        "serial_number":"IOT-NODE-001",
        "timestamp":1729505040,
        "cage_code":"CAGE-A01",
        "latitude":-8.652930,
        "longitude":116.319519,
        "altitude":1.2,
        "raw_values":{
          "temperature_node":27.45,
          "ambient_temperature":30.10,
          "ph":7.82,
          "tds":420.5,
          "raw_dissolved_oxygen":6.15,
          "turbidity":4.10,
          "flow_rate":0.28,
          "solar_voltage":18.2,
          "solar_current":1.45,
          "battery_voltage":12.6,
          "battery_current":0.65,
          "pump_status":1
        }
      }
      ''';

      final Map<String, dynamic> jsonMap = json.decode(rawJson);
      final telemetry = TelemetryData.fromJson(jsonMap);

      expect(telemetry.serialNumber, 'IOT-NODE-001');
      expect(telemetry.cageCode, 'CAGE-A01');
      expect(telemetry.latitude, -8.652930);
      expect(telemetry.longitude, 116.319519);
      expect(telemetry.altitude, 1.2);
      expect(telemetry.temperature, 27.45);
      expect(telemetry.ambientTemperature, 30.10);
      expect(telemetry.ph, 7.82);
      expect(telemetry.tds, 420.5);
      expect(telemetry.dissolvedOxygen, 6.15);
      expect(telemetry.turbidity, 4.10);
      expect(telemetry.flowSpeed, 0.28);
      expect(telemetry.solarVoltage, 18.2);
      expect(telemetry.solarCurrent, 1.45);
      expect(telemetry.batteryVoltage, 12.6);
      expect(telemetry.batteryCurrent, 0.65);
      expect(telemetry.pumpStatus, 1);
      expect(telemetry.salinity, 0.0);
    });

    test('LoraParser extracts JSON from noisy serial preamble', () {
      final noisyBytes = utf8.encode('+++OK#GARBAGE_HEADER{"serial_number":"IOT-NODE-001","raw_values":{"temperature_node":28.0,"pump_status":1}}');
      final telemetry = LoraParser.parse(noisyBytes);

      expect(telemetry.serialNumber, 'IOT-NODE-001');
      expect(telemetry.temperature, 28.0);
      expect(telemetry.pumpStatus, 1);
    });
  });
}
