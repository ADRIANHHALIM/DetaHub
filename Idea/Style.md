# 5. style.md

Dokumen panduan desain sistem visual untuk **DetaHub**. Dirancang dengan prinsip **Technical Elegance / Lab Instrument Aesthetic**—menghindari efek dekoratif berlebih (*AI slop*), mengadopsi palet warna industrial dan tingkat keterbacaan tinggi dari hardware [LAT](https://lightweight-air-tester.vercel.app/?fbclid=PAdGRzdgUcnahwZG9mAmV4dG4DYWVtAjExAHNydGMGYXBwX2lkDzU2NzA2NzM0MzM1MjQyNwABpyv7WB9GQEmMyn3HZROg6y6ND029cdcichhVYdPLLHTDYuf7lzd2dN4bmx8D_aem_CCsFqZtKnZHZ8r-0istd9A), dengan **Light Mode** sebagai tampilan bawaan (*default*) dan opsi **Dark OLED Mode** bawaan web.

```markdown
# Style & Design System — DetaHub (DetaDesign System)

## 1. Design Philosophy
- Functional Precision: Mengutamakan data sensor di atas ornamen dekoratif. Tampilan dirancang layaknya panel instrumen laboratorium modern.
- Strict Anti-AI Slop: HINDARI ilustrasi kartun generik, efek kaca blur berlebih (excessive glassmorphism), gradient ungu/pink mencolok, dan rounded corner raksasa.
- Glanceable & Clear: Setiap pembacaan angka memiliki unit yang kontras, status diskret yang tegas, dan grafik yang tidak membingungkan pengguna awam.
- Default Mode: Light Mode (Crisp Lab Paper) bersih dengan opsi Dark Mode (Monochrome Instrument) identik landing page LAT.

---

## 2. Color Palette & Semantics

### 2.1. Base Theme Colors

| Token | Light Mode (Default) | Dark Mode (LAT Web Native) | Karakter & Penggunaan |
| :--- | :--- | :--- | :--- |
| `background` | `#F8F9FA` (Clean Off-White) | `#0B0C0E` (OLED Obsidian) | Kanvas utama layar |
| `surface` | `#FFFFFF` (Pure White) | `#14171A` (Charcoal Tint) | Kontainer kartu, modal, header |
| `surface_variant` | `#EFF1F4` (Cool Light Grey) | `#1F2428` (Muted Steel) | Chip filter, border, track bar |
| `text_primary` | `#0D1117` (Deep Slate) | `#EDEDED` (Crisp Chalk) | Nilai metrik besar, judul |
| `text_secondary`| `#57606A` (Neutral Grey) | `#8B949E` (Subdued Steel) | Unit metrik, label waktu, deskripsi |
| `border` | `#D0D7DE` (Crisp Divider) | `#2A3138` (Low-contrast Dark) | Garis batas struktural kartu (1px) |
| `accent` | `#111827` (Pure Industrial) | `#FFFFFF` (Stark Minimalist) | Tombol aksi utama, active states |

### 2.2. Scientific Air Quality Palette (Sesuai Hardware ENS160 / Web LAT)
Warna ini digunakan secara konsisten pada LED perangkat fisik, badge AQI, dan highlight kurva grafik:

| Indeks | Label | Hex Code | Deskripsi Warna |
| :--- | :--- | :--- | :--- |
| **AQI 1** | Good | `#10B981` | Light Green (Segar & Tenang) |
| **AQI 2** | Moderate | `#3B82F6` | Muted Blue (Stabil & Normal) |
| **AQI 3** | Unhealthy for Sensitive | `#F59E0B` | Amber / Warm Yellow (Waspada) |
| **AQI 4** | Unhealthy | `#EF4444` | Crisp Red (Peringatan Bahaya) |
| **AQI 5** | Very Unhealthy | `#991B1B` | Deep Crimson (Kritis / Polusi Tinggi) |

---

## 3. Typography Hierarchy

Gunakan font dengan rasio keterbacaan teknis tinggi:
- Primary Sans-Serif: **Inter** atau **Plus Jakarta Sans** (Sangat jelas pada layar beresolusi tinggi).
- Monospace (Angka & Log): **JetBrains Mono** atau **Fira Code** (Untuk seluruh data numerik, timestamp, dan alamat IP).

### Skala Tipografi
- Metric Display: `44px` · SemiBold · Monospace (Contoh: `720 ppm`, `35.3 °C`).
- Section Title: `18px` · Bold · Sans-Serif · Tracking `-0.02em`.
- Card Header: `14px` · Medium · Sans-Serif.
- Subtitle / Unit: `12px` · Regular · Monospace · All Caps · Tracking `+0.05em` (Contoh: `TVOC · PPB`).
- Caption / Timestamp: `11px` · Regular · Monospace (Contoh: `2026-09-02 19:30:40`).

---

## 4. Graph & Charting Rules (Easy to Understand & High Clarity)

1. **Kurva Bersih (No Clutter):**
   - Garis kurva tipis berukuran `2.0px` tanpa bayangan tebal.
   - Gunakan area fill gradasi transparan sangat halus di bawah garis (opacity `0.08` ke `0.00`) untuk membantu persepsi volume tanpa mengaburkan grid.
2. **Dynamic Baseline & Auto-Scaling:**
   - Sumbu Y tidak boleh dipaksa mulai dari 0 jika fluktuasi data berada di rentang sempit (misal suhu 32 °C – 38 °C), agar tren perubahan terlihat nyata.
3. **Event Callout Pins (Spike Highlights):**
   - Saat terdeteksi Event Polusi (misal TVOC > 4.000 ppb), tampilkan dot penanda kecil dengan ring luar berkedip halus dan chip waktu yang dapat diketuk.
4. **Scannable Tooltip:**
   - Tooltip saat jari menekan grafik berupa garis bidik vertikal (crosshair hair-line) dengan popover monospaced yang menampilkan waktu dan nilai pasti dari semua variabel di detik tersebut secara bersamaan.
5. **Chart Color Mapping:**
   - eCO2: `#10B981` (Emerald).
   - TVOC: `#F59E0B` (Amber).
   - Temperature: `#F97316` (Warm Orange).
   - Humidity: `#06B6D4` (Cyan Water).
   - AQI: Garis bar diskret bertingkat (Step Chart) yang warnanya berubah sesuai level 1–5.
 
---

## 5. Layout & Component Geometry

- **Border Radius:** Konsisten pada skala modular kecil:
  - Kartu Metrik: `10px`
  - Chip & Badges: `4px` (Nuansa instrumen industri)
  - Modals / Sheets: `16px` (hanya sudut atas)
- **Borders & Dividers:** Selalu sertakan border tegas `1px` (`#D0D7DE` pada Light Mode, `#2A3138` pada Dark Mode) untuk menegaskan batasan kartu tanpa mengandalkan bayangan buram (drop shadows).
- **Elevation:** Minimalis. Jangan gunakan drop shadow tebal; gunakan border solid atau bayangan tipis `y=1, blur=2, opacity=0.04`.