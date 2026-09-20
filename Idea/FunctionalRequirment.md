# Functional Requirements Document — DetaHub

## 1. Modul Manajemen Hierarki (Sector & Sub-Sector)
- FR-SEC-001: Aplikasi wajib menyediakan fungsi CRUD (Create, Read, Update, Delete) entitas Sektor tanpa batasan kuota.
- FR-SEC-002: Aplikasi wajib mendukung relasi one-to-many antara Sektor dan Sub-Sektor.
- FR-SEC-003: Menghapus Sektor akan memberikan konfirmasi cascade delete terhadap seluruh Sub-Sektor dan relasi perangkat di dalamnya.

## 2. Modul Registrasi Perangkat (Device Registry)
- FR-DEV-001: Pengguna dapat mendaftarkan perangkat baru ke dalam Sub-Sektor dengan memasukkan:
  - Device ID (String unik, misal MAC address atau custom slug).
  - Nama Alias Perangkat (String, misal: "Sensor Meja Kerja").
  - Base URL / Host mDNS (String, misal: "http://192.168.1.50" atau "lat-lab.local").
  - Tipe Produk (Pilihan manifest: "LAT_ENS160", "GENERIC_CSV", dll.).
- FR-DEV-002: Aplikasi wajib melakukan connectivity handshake (GET /api/live atau GET /api/info) sebelum menyimpan node ke database.
- FR-DEV-003: Aplikasi wajib mendukung pemindaian subnet lokal (mDNS / Zeroconf) untuk menemukan perangkat ESP32 yang aktif.

## 3. Modul Sinkronisasi Data (Data Sync Engine)
- FR-SYNC-001: Polling Real-time: Saat membuka dashboard perangkat, aplikasi memanggil GET /api/live setiap N detik (default: 5 detik) untuk memperbarui metrik instan.
- FR-SYNC-002: Bulk Historical Sync: Aplikasi mengambil file log harian GET /data_YYYY-MM-DD.csv dari storage SPIFFS perangkat.
- FR-SYNC-003: Deduplikasi Cerdas: Engine sinkronisasi hanya memasukkan baris CSV yang memiliki timestamp lebih baru dari data terakhir yang tersimpan di SQLite lokal.
- FR-SYNC-004: Toleransi Kegagalan: Request timeout diatur ke minimal 15 detik untuk menangani koneksi lambat pada transfer file CSV dari flash ESP32.

## 4. Modul Visualisasi & Analisis Telemetri
- FR-VIS-001: Overview Mode: Menampilkan ringkasan seluruh kartu status perangkat dalam satu Sub-Sektor secara simultan (status online, level AQI terakhir, suhu, dan eCO2).
- FR-VIS-002: Detail Mode: Menyajikan grafik interaktif time-series per metrik (Temperature, Humidity, eCO2, TVOC, AQI) dengan rentang waktu: Hari Ini, 24 Jam Terakhir, dan 5 Hari Terakhir.
- FR-VIS-003: Grafik wajib mengimplementasikan downsampling algoritma LTTB (Largest Triangle Three Buckets) saat merender >500 titik data demi menjaga performa 60 FPS.
- FR-VIS-004: Event Marker: Menandai secara otomatis titik lonjakan polusi (AQI 5 / TVOC > 4.000 ppb) langsung di timeline grafik.

## 5. Modul Dynamic Machine Learning Engine
- FR-ML-001: On-Demand Provisioning: Saat produk tipe baru ditambahkan, aplikasi memeriksa keberadaan file model (.tflite / .onnx) di local storage HP. Jika belum ada, aplikasi mengunduh bobot model dari CDN/GitHub Release statis.
- FR-ML-002: Background Isolate Execution: Inferensi model wajib dieksekusi di Dart Background Isolate terpisah agar thread UI tidak mengalami jank.
- FR-ML-003: Hardware Acceleration: Runtime ML wajib memanfaatkan akselerasi GPU/NPU lokal via NNAPI (Android).
- FR-ML-004: Zero Cloud Leakage: Seluruh input array telemetri diproses langsung di memori HP dan tidak boleh dikirim keluar jaringan lokal.

## 6. Modul Portabilitas Data & File Exporter
- FR-DAT-001: Pengguna dapat mengekspor log telemetri yang tersimpan di SQLite kembali menjadi format CSV standar kapan pun.
- FR-DAT-002: Aplikasi memicu native Android Share Sheet (buka di Excel, bagikan via WhatsApp, Google Drive lokal).
- FR-DAT-003: Fitur Backup & Restore full database lokal (.db) ke penyimpanan smartphone.