# DetaHub

**Local-first IoT companion app for the DetaLab open-source hardware ecosystem.**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-10B981?style=flat-square)](#)

> NO CLOUD. NO LOGIN. NO SHARE. SAVE YOUR OWN DATA.

---

## Overview

DetaHub is the official companion app for the [DetaLab](https://detalab.id) family of open-source IoT hardware, starting with **LAT (Lightweight Air Tester)** — an air quality monitor built on the ESP32-H2.

All telemetry is stored locally in SQLite on your device. There is no external server, no Firebase, no Supabase, and no account of any kind. IoT nodes act as edge micro-servers over your local Wi-Fi subnet; DetaHub communicates with them directly via HTTP.

---

## Design Philosophy

| Principle | Description |
|---|---|
| 100% Data Ownership | All data lives in SQLite on-device. It never leaves your local network. |
| Local-First | Fully functional on a LAN. No internet connection required after install. |
| Edge Computing | IoT nodes expose a local HTTP API. No cloud relay, no middleman. |
| Zero Account | No sign-in, no email, no telemetry. Open the app and go. |

---

## Supported Hardware

| Device | Sensor Stack | Status |
|---|---|---|
| LAT (Lightweight Air Tester) | ENS160 + AHT21 on ESP32-H2 | Supported |
| Future DetaLab Nodes | TBD | Planned |

### Device API Contract

Each LAT node exposes three local HTTP endpoints:

```
GET /api/manifest           Device metadata, capabilities, and metric list
GET /api/live               Real-time telemetry as JSON
GET /data_{YYYY-MM-DD}.csv  Daily log file (1 row/min, ~1440 rows/day)
```

**CSV format:**
```
Timestamp,Temperature(C),Humidity(%),eCO2(ppm),TVOC(ppb),AQI
2024-01-15T08:00:00,24.5,62.3,450,120,1
```

---

## Data Hierarchy

Data is organized in a three-level hierarchy:

```
Sector
    Sub-Sector
        Device Node  (id, base_url, product_type)
            Telemetry Records  (timestamped sensor readings)
```

Cascade deletes apply at every level. Removing a Sector removes all its Sub-Sectors, Devices, and associated telemetry records.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.24+ / Dart 3.4+ |
| State Management | Riverpod (`flutter_riverpod`) |
| Local Database | Drift (reactive SQLite ORM) |
| Networking | Dio with aggressive timeouts, CSV streaming |
| Device Discovery | Multicast DNS / Zeroconf |
| Charting | fl_chart with LTTB downsampling |
| On-Device AI | TFLite / ONNX Runtime (background Isolate, no cloud leakage) |
| File Export | `csv`, `path_provider`, `share_plus` (native share sheet) |
| Typography | JetBrains Mono (numeric data) + Inter (UI text) |

---

## Project Structure

```
lib/
├── core/
│   ├── database/          Drift schema, tables, DAOs
│   │   ├── tables/        sectors, sub_sectors, devices, telemetry_records
│   │   ├── daos/          SectorDao, DeviceDao, TelemetryDao
│   │   └── app_database.dart
│   ├── network/           Dio client, device discovery service
│   ├── theme/             DetaDesign tokens, AppColors, AppTheme
│   ├── utils/             LTTB downsampler, CSV parser, export helpers
│   └── widgets/           MetricCard, AQIBadge, ConnectionPill, LineChart
├── features/
│   ├── sector/            Sector and Sub-Sector CRUD, screens, providers
│   ├── device/            Add IoT node via ID and URL, handshake test
│   ├── sync/              CSV fetch and delta deduplication engine
│   ├── telemetry/         Multi-node dashboard, time-series chart
│   ├── ai_engine/         Dynamic model downloader, Isolate runner
│   └── settings/          SQLite backup/restore, storage management
└── main.dart
```

---

## AQI Color Reference

DetaHub implements the ENS160 5-level Air Quality Index:

| Level | Label | Hex |
|---|---|---|
| AQI 1 | Excellent | `#10B981` |
| AQI 2 | Good | `#6EE7B7` |
| AQI 3 | Moderate | `#F59E0B` |
| AQI 4 | Poor | `#EF4444` |
| AQI 5 | Unhealthy | `#991B1B` |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.24.0`
- Android SDK (API 26+) or Xcode 15+ for iOS 14+
- A DetaLab device connected to the same Wi-Fi network

### Setup

```bash
# Clone the repository
git clone https://github.com/detalab/detahub.git
cd detahub

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device or emulator
flutter run
```

### Running Tests

```bash
# All unit tests
flutter test

# Static analysis
flutter analyze lib/
```

---

## Design System

DetaHub follows the **DetaDesign** language — an Industrial Instrument Minimalist aesthetic consistent with all DetaLab products:

- Flat UI with zero elevation and no drop shadows
- 1px solid borders throughout
- Maximum 4px border radius
- Crisp Light Mode by default; true OLED Dark Mode available
- JetBrains Mono for all numeric and telemetry values
- Inter for all UI and label text
- No glassmorphism, no decorative gradients, no generic illustrations

---

## Development Roadmap

| Phase | Scope | Status |
|---|---|---|
| Phase 1 | Core foundation — Drift schema, DAOs, LTTB algorithm, DetaDesign theme | Complete |
| Phase 2 | Sector/Device CRUD screens, Dio network layer, GoRouter navigation | Next |
| Phase 3 | CSV sync engine, delta deduplication, telemetry dashboard | Planned |
| Phase 4 | On-device AI engine (TFLite), dynamic model download, Isolate runner | Planned |
| Phase 5 | Backup/restore, CSV/DB export, storage management, mDNS discovery | Planned |

---

## Contributing

Contributions are welcome. Please follow standard Git workflow:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m 'feat: description'`
4. Push and open a Pull Request against `main`

---

