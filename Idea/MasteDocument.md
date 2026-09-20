┌─────────────────────────────────────────────────────────┐
│              Local Subnet / Wi-Fi Kampus                │
│                                                         │
│  ┌───────────────────────┐     ┌──────────────────────┐ │
│  │ ESP32-H2 (LAT Node 1) │     │ ESP32 (Power Node 2) │ │
│  │ 192.168.1.51          │     │ 192.168.1.52         │ │
│  │ LittleFS / Port 80    │     │ LittleFS / Port 80   │ │
│  └───────────▲───────────┘     └───────────▲──────────┘ │
│              │ HTTP GET                    │            │
└──────────────┼─────────────────────────────┼────────────┘
               │                             │
       ┌───────┴─────────────────────────────┴──────┐
       │             DetaHub Mobile App             │
       │               (Flutter Client)             │
       │                                            │
       │  ┌──────────────┐         ┌─────────────┐  │
       │  │  Riverpod    │◄────────┤ Network/Dio │  │
       │  │ State Engine │         └─────────────┘  │
       │  └──────┬───────┘                          │
       │         │                                  │
       │  ┌──────▼───────┐         ┌─────────────┐  │
       │  │ Drift SQLite │         │ Background  │  │
       │  │ (Local DB)   │◄───────►│ ML Isolate  │  │
       │  └──────┬───────┘         └─────────────┘  │
       │         │                                  │
       │  ┌──────▼───────────────────────────────┐  │
       │  │ fl_chart + Skia GPU Visualizer       │  │
       │  └──────────────────────────────────────┘  │
       └────────────────────────────────────────────┘


       lib/
├── core/
│   ├── database/        # Drift setup, tables, DAOs
│   ├── network/         # Dio client, Zeroconf discovery
│   ├── theme/           # DetaDesign Tokens, colors, typography
│   ├── utils/           # CSV parser, LTTB downsampler, file exporter
│   └── widgets/         # Shared atomics (Cards, Badges, Pills)
├── features/
│   ├── sector/          # Sektor & Sub-Sektor UI & providers
│   ├── device/          # Add device, test handshake, settings
│   ├── sync/            # Log sync engine, schedule background job
│   ├── telemetry/       # Chart widgets, multi-node comparisons
│   ├── ai_engine/       # Model download manager, Isolate inference
│   └── settings/        # Backup DB, reset data, hardware docs
└── main.dart