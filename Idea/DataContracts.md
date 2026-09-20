# Data Contracts & API Specification — DetaHub

## 1. Edge API Endpoints (Disediakan oleh Firmware ESP32 / Perangkat IoT)

### 1.1. Healthcheck & Manifest
- Path: `GET /api/manifest`
- Response Headers: `Content-Type: application/json`
- Response Body:
```json
{
  "product_id": "LAT_ENS160",
  "firmware_version": "1.0.0",
  "hardware_rev": "ESP32-H2-MINI",
  "mac_address": "84:FC:E6:XX:XX:XX",
  "capabilities": ["live_stream", "daily_csv_log"],
  "metrics": [
    { "key": "temp", "label": "Temperature", "unit": "°C", "type": "float" },
    { "key": "hum", "label": "Humidity", "unit": "%", "type": "float" },
    { "key": "eco2", "label": "eCO2", "unit": "ppm", "type": "integer" },
    { "key": "tvoc", "label": "TVOC", "unit": "ppb", "type": "integer" },
    { "key": "aqi", "label": "Air Quality Index", "unit": "Level", "type": "integer", "min": 1, "max": 5 }
  ]
}