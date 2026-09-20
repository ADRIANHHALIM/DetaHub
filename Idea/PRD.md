# Product Requirements Document (PRD) — DetaHub

## 1. Product Overview
DetaHub adalah platform mobile client (Flutter) untuk orkestrasi, monitoring, dan analisis data multi-perangkat IoT berbasis Local-First. Tanpa ketergantungan server cloud, tanpa sistem registrasi/login, dan menjamin 100% kepemilikan data mandiri di tangan pengguna. Ekosistem ini dirancang untuk membaca hardware DetaLab seperti LAT (Lightweight Air Tester) maupun modul hardware masa depan, mengelompokkannya secara hierarkis (Sector → Sub-Sector → Devices), serta mengeksekusi inferensi Machine Learning secara lokal di smartphone.

## 2. Core Principles
- Local-First & Zero-Cloud: Tidak ada server auth, database cloud, atau pelacakan telemetri eksternal.
- Pure Data Sovereignty: Data mentah tersimpan dalam memori flash mikrokontroler (SPIFFS/LittleFS) dan database lokal smartphone (SQLite/Drift).
- Direct-to-Consumer Distribution: Didistribusikan langsung sebagai standalone APK atau aplikasi publik Google Play Store dengan ukuran dasar ultra-ringan (<25 MB).
- Dynamic Hardware & AI Provisioning: Mengadopsi berbagai jenis perangkat keras baru via manifest API lokal, dan mengunduh model ML terkuantisasi (.tflite/.onnx) secara modular sesuai jenis produk yang ditambahkan.

## 3. User Personas & Use Cases
- Fasilitas Kampus / Lab Riset (e.g., Universitas Trisakti): Pengelola memantau belasan ruangan kelas dan laboratorium riset via Wi-Fi kampus tanpa memicu biaya sewa infrastruktur server bulanan.
- Tech Enthusiast / Maker: Pengguna produk open-source LAT yang menginginkan kendali atas kualitas udara huniannya, mengunduh file CSV harian untuk dianalisis di desktop.
- Health-Conscious Individual: Penghuni kamar/kantor yang membutuhkan glanceable alert saat kadar eCO2 atau TVOC mencapai ambang bahaya.

## 4. Hierarchy Model
- Sector: Level tertinggi entitas fisik/geografis (Contoh: "Universitas Trisakti", "Hunian Jakarta Barat").
- Sub-Sector: Ruangan, zona, atau laboratorium spesifik dalam satu Sektor (Contoh: "Lab IoT", "Ruang Rapat Gedung H", "Kamar Tidur").
- Device Node: Titik ukur fisik dengan ID unik (Contoh: LAT-Petojo-01) yang terhubung ke IP/mDNS lokal.

## 5. Scope of Release (V1.0)
- Registrasi dinamis Sektor, Sub-Sektor, dan Device Node via IP/Host lokal.
- Sinkronisasi telemetri harian via polling HTTP dan bulk sync CSV (file data_YYYY-MM-DD.csv).
- Dashboard visualisasi time-series interaktif (eCO2, TVOC, Suhu, Kelembapan, AQI diskret).
- Sistem deteksi kejadian polusi (Pollution Spike Detection).
- Dynamic On-Demand Model Downloader untuk bobot inferensi TFLite/ONNX.
- Ekspor data CSV mandiri ke filesystem smartphone via Native Share Sheet.