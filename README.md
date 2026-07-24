# 🖥️ Edge Lobsense / Lobster Sensing System - Edge Gateway Desktop App

Aplikasi **Edge Lobsense** (Edge Gateway Desktop App) merupakan aplikasi desktop berbasis **Flutter (Windows Native)** yang bertindak sebagai hub komunikasi lokal, penerima sinyal frekuensi radio LoRa, penyimpan buffer data telemetri offline, dan pemroses keputusan tepi (*edge processing*) di lokasi tambak lobster.

---

## 🎯 Peran & Kegunaan Edge Gateway dalam Sistem

Dalam ekosistem **Lobster Sensing System**, Edge Gateway memegang peranan krusial sebagai jembatan antara perangkat keras fisik di tengah laut dengan server cloud backend:

1. **Penerima Telemetri LoRa (Radio Frequency Receiver)**: Membaca aliran byte mentah (*raw bytes*) dari modul receiver LoRa yang terhubung via port serial RS-485 / USB TTL.
2. **Penyimpanan Buffer Data Offline (Offline Resilience)**: Apabila koneksi internet di lokasi tambak terputus, Edge Gateway akan menyimpan seluruh data telemetri dan log secara lokal pada database SQLite terenkripsi.
3. **Penyinkronan Otomatis (Auto-Sync to Cloud)**: Ketika koneksi internet pulih, aplikasi secara otomatis menyinkronkan seluruh buffer data lokal ke Cloud Backend API tanpa ada data yang hilang (*zero data loss*).
4. **Monitoring Kesehatan Perangkat Keras (Hardware Health Check)**: Memantau penggunaan CPU, memori RAM, suhu sistem, tegangan suplai daya solar panel, serta status koneksi setiap IoT Node.

---

## 🛠️ Fitur-Fitur Utama Aplikasi Edge

- **System Branding Header**: Menampilkan identitas resmi sistem **`Edge Lobsense / Lobster Sensing System`** lengkap dengan logo icon resmi bersudut halus.
- **Local Telemetry Live Stream**: Memvisualisasikan data sensor pH, DO, TDS, Suhu Air, dan Turbiditas secara real-time langsung dari stasion tepi.
- **LoRa Packet Parser (`LoRaParser`)**: Mengurai paket data biner LoRa, melakukan verifikasi checksum CRC, dan memvalidasi kode registrasi node.
- **Serial Port Auto-Detector (`libserialport`)**: Mendeteksi dan mengonfigurasi baud rate port COM/TTY receiver LoRa secara otomatis.
- **Offline SQLite Buffering (`sqflite`)**: Manajemen antrean data telemetri lokal yang aman dan transparan.
- **Direct MQTT Local Broker Broadcast**: Memancarkan data telemetri ke jaringan LAN lokal tambak untuk konsumsi aplikasi web & mobile sekitar.

---

## 🏗️ Teknologi & Library Utama

- **Framework**: Flutter 3.24+ (Dart 3.5+, Windows Desktop Target)
- **Serial Communication**: `flutter_libserialport` / `libserialport` (Binding C-Library RS-232/RS-485/USB-Serial)
- **Local Persistence**: `sqflite` / `sqflite_common_ffi` (Database SQLite lokal)
- **Network & Protocol**: `mqtt_client` (MQTT Client), `http` (REST API Client)
- **Media & Camera**: `media_kit` (Playback stream kamera CCTV lokal)

---

## ⚙️ Panduan Instalasi & Compiling (Windows Desktop)

### Prasyarat:
- Flutter SDK `>= 3.24.0`
- Visual Studio 2022 (dengan beban kerja *Desktop Development with C++*)
- Git & CMake

### Langkah-Langkah Build & Run:

```bash
# 1. Masuk ke direktori EdgeApp
cd EdgeApp

# 2. Ambil seluruh paket dependensi Flutter
flutter pub get

# 3. Jalankan aplikasi dalam mode pengembangan (Windows Native)
flutter run -d windows

# 4. Melakukan kompilasi build produksi (Release Executable)
flutter build windows --release
```

Hasil file executable produksi (`.exe`) dengan logo resmi Lobsense akan tersedia di direktori `EdgeApp/build/windows/x64/runner/Release/`.
