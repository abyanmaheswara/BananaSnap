# 🍌 BanaSnap (Premium Edition)

Aplikasi mobile Flutter pintar bersistem Gamifikasi untuk mendeteksi tingkat kelayakan pisang memanfaatkan AI _on-device_ (TFLite) & _Cloud Leaderboard_ (Firebase).

---

## ✨ Fitur-Fitur Premium

| Fitur Utama                  | Deskripsi                                                                                                 |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------- |
| **🤖 AI On-Device (LiteRT)** | Inferensi canggih TFLite tanpa internet. Cepat, aman, otomatis bundle C++ DLL.                            |
| **🎨 Premium UI / UX**       | Desain segar & elegan! Memadukan Amber, Emerald Green, & Slate untuk Light/Dark mode.                     |
| **🏆 Global Leaderboard**    | Terintegrasi dengan Firebase Firestore. Analisa pisang & kejar `Top 3` dunia!                             |
| **🎮 Gamification System**   | Dapatkan +10 🪙 poin tiap scan sukses. Makin banyak pisang sehat yang dianalisa, makin tinggi level Anda! |
| **💡 AI Scanner Animation**  | Garis _Neon Scanner_ futuristik ketika AI sedang menganalisa gambar pisang.                               |
| **✨ Top 3 Shimmer Effect**  | Efek kilauan emas/perak/perunggu berkilap mewah khusus untuk peringkat 1, 2, dan 3 Leaderboard.           |
| **📱 Haptic Feedback**       | Sensasi getar halus ala _native_ pada interaksi tab, hasil analisa, dan tombol utama.                     |
| **💾 Save & Share**          | Simpan langsung _Result Card_ AI Anda ke Galeri HP dengan satu sentuhan.                                  |

---

## 📁 Struktur Proyek (Ringkas)

```
banana-app/
├── lib/
│   ├── main.dart                        # Entry point + Theme Palette
│   ├── screens/
│   │   ├── splash_screen.dart           # Splash screen dengan Lottie / Animated Logo
│   │   ├── home_screen.dart             # Halaman Utama (AI Scanner UI)
│   │   ├── history_screen.dart          # Riwayat SQLite Lokal
│   │   ├── leaderboard_screen.dart      # Global Leaderboard (Firebase)
│   │   └── onboarding_screen.dart       # Panduan Pemula
│   └── services/
│       ├── banana_classifier.dart       # Service LiteRT (TFLite) Inferensi Model
│       ├── firebase_service.dart        # Firebase Firestore & Auth Service
│       └── history_database.dart        # Database SQLite
├── assets/model/
│   ├── banana_model.tflite              # Custom Model MobileNetV2
│   └── labels.txt
└── training/
    └── train_model.py                   # Script Python ML Training
```

---

## 🚀 Instalasi & Menjalankan Aplikasi

**1. Persiapan Flutter & Firebase:**

- Pastikan Flutter SDK telah diinstal & jalankan `flutter doctor`.
- Letakkan file konfigurasi `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) dari Firebase Console ke _root_ masing-masing platform.

**2. Unduh Dependensi:**

```bash
flutter clean && flutter pub get
```

**3. Jalankan Aplikasi:**

```bash
flutter run
```

---

## 🧠 Arsitektur Model AI (Under the Hood)

1. **Input:** Foto Pisang di-_resize_ ke `224x224 px` dan di-_normalize_ (0.0 - 1.0).
2. **Backbone:** Mengganti layer klasifikasi `MobileNetV2` (Pre-trained ImageNet).
3. **Head:** `GlobalAveragePooling2D` -> `Dense(256)` -> `Dropout(0.4)` -> `Dense(64)` -> `Dropout(0.2)`.
4. **Output:** `Dense(1)` dengan aktivasi _Sigmoid_ (Keluaran di bawah 0.5 = Segar, di atas = Busuk).

---

## 📦 Dependencies Utama (pubspec.yaml)

- `flutter_litert` (Inferensi TFLite)
- `firebase_core` & `cloud_firestore` (Database Leaderboard Cloud)
- `image_picker` (Akses Kamera/Galeri)
- `sqflite` (Database Riwayat Lokal)
- `shared_preferences` (Menyimpan Status Onboarding)
- `shimmer` (Efek Berkilau Premium)
- `screenshot` & `image_gallery_saver_plus` (Capture dan Simpan Kartu Hasil AI)

---

_Dibuat untuk memudahkan analisis buah, dikemas dengan cita rasa kelas atas! 🍌🚀_
