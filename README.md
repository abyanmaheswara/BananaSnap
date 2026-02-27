# 🍌 BanaSnap

Aplikasi mobile Flutter untuk mendeteksi kelayakan pisang menggunakan AI on-device (TFLite)

---

## 📁 Struktur Proyek

```
banana-app/
├── lib/
│   ├── main.dart                        # Entry point + theme
│   ├── screens/
│   │   ├── splash_screen.dart           # Splash screen
│   │   ├── home_screen.dart             # Halaman utama deteksi
│   │   └── history_screen.dart          # Riwayat deteksi
│   ├── widgets/
│   │   ├── result_card.dart             # Kartu hasil deteksi
│   │   └── stats_widget.dart            # Widget statistik
│   └── services/
│       ├── banana_classifier.dart       # Service TFLite model
│       └── history_database.dart        # Database SQLite
├── assets/
│   └── model/
│       ├── banana_model.tflite          # ← Isi setelah training!
│       └── labels.txt                   # ← Isi setelah training!
├── training/
│   └── train_model.py                   # Script training model
└── pubspec.yaml
```

---

## 🚀 Cara Setup (Step by Step)

### Langkah 1 — Training Model AI

**1.1 Install Python dependencies**

```bash
pip install tensorflow pillow numpy scikit-learn matplotlib
```

**1.2 Download Dataset dari Kaggle**

- Buka: https://www.kaggle.com/datasets/sriramr/fruits-fresh-and-rotten-for-classification
- Download dan ekstrak
- Buat struktur folder:

```
training/dataset/
├── train/
│   ├── fresh_banana/     ← copy foto pisang segar
│   └── rotten_banana/    ← copy foto pisang busuk
└── validation/
    ├── fresh_banana/
    └── rotten_banana/
```

> 💡 Tips: Ambil sekitar 80% untuk train, 20% untuk validation

**1.3 Jalankan training**

```bash
cd training
python train_model.py
```

Training memakan waktu 10-30 menit tergantung spesifikasi laptop.

**1.4 Copy hasil ke Flutter**

```bash
cp training/banana_model.tflite  assets/model/
cp training/labels.txt           assets/model/
```

---

### Langkah 2 — Setup Flutter

**2.1 Install Flutter SDK**

- Download: https://flutter.dev/docs/get-started/install
- Verifikasi: `flutter doctor`

**2.2 Install dependencies**

```bash
flutter pub get
```

**2.3 Setup permissions Android**

Tambahkan ke `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**2.4 Setup permissions iOS**

Tambahkan ke `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Digunakan untuk memfoto pisang</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Digunakan untuk memilih foto pisang</string>
```

**2.5 Jalankan aplikasi**

```bash
# Android
flutter run

# Windows (Desktop)
flutter run -d windows

# iOS (butuh Mac + Xcode)
flutter run -d ios
```

---

## 📱 Fitur Aplikasi

| Fitur            | Keterangan                                                       |
| ---------------- | ---------------------------------------------------------------- |
| 📸 Foto langsung | Ambil foto pisang via HP (Android/iOS)                           |
| 🖼️ Dari galeri   | Pilih foto dari galeri HP atau File Explorer (Windows)           |
| 🤖 Deteksi AI    | Model MobileNetV2 on-device, offline, auto DLL Bundle via LiteRT |
| 📊 Confidence    | Tingkat kepercayaan hasil deteksi                                |
| 📜 Riwayat       | Simpan semua hasil deteksi dengan SQLite                         |
| 📈 Statistik     | Jumlah layak vs tidak layak                                      |

---

## 🧠 Cara Kerja Model

```
Foto Pisang (dari kamera/galeri)
        ↓
Resize ke 224x224 px
        ↓
Normalisasi pixel (0-255 → 0.0-1.0)
        ↓
MobileNetV2 + Custom Head (TFLite)
        ↓
Output: [score_layak, score_tidak_layak]
        ↓
Ambil nilai tertinggi → Hasil final
```

**Arsitektur Model:**

- Base: MobileNetV2 (pre-trained ImageNet)
- GlobalAveragePooling2D
- Dense(256, ReLU) + Dropout(0.4)
- Dense(64, ReLU) + Dropout(0.2)
- Dense(1, Sigmoid) → Binary output

---

## 🐛 Troubleshooting

| Masalah                     | Solusi                                                                       |
| --------------------------- | ---------------------------------------------------------------------------- |
| `Model belum dimuat`        | Pastikan file `.tflite` ada di `assets/model/`                               |
| Akurasi rendah              | Tambah data training, cek kualitas dataset                                   |
| Kamera tak muncul (Windows) | Modul `image_picker` Windows Desktop hanya support Galeri                    |
| Build error / DLL NotFound  | Jalankan `flutter clean && flutter pub get` karena LiteRT otomatis fetch DLL |

---

## Dependencies Utama

```yaml
flutter_litert: ^0.1.7 # TFLite/LiteRT inferensi model on-device (Auto-Bundle C++ DLL)
image_picker: ^1.1.2 # Akses kamera & galeri
camera: ^0.11.0 # Kamera langsung
image: ^4.1.7 # Preprocessing gambar
sqflite: ^2.3.2 # Database riwayat lokal
percent_indicator: ^4.2.3 # Bar confidence
```
