# WargaKita Admin App (Flutter)

<p align="center">
  <img src="https://flutter.dev/assets/images/shared/brand/flutter/logo/flutter-lockup.png" width="180" alt="Flutter Logo"/>
</p>

<p align="center">
  <b>WargaKita Admin</b><br/>
  Aplikasi mobile admin berbasis Flutter untuk pengelolaan sistem WargaKita.
</p>

---

## 📌 Deskripsi

**WargaKita Admin App** adalah aplikasi **mobile berbasis Flutter** yang digunakan oleh **Admin, RT, RW, dan Petugas Lingkungan** untuk mengelola layanan dan data warga secara terpusat.

Aplikasi ini terhubung langsung dengan **WargaKita Backend API (NestJS)** dan dirancang agar mudah digunakan, aman, serta efisien dalam pengelolaan lingkungan masyarakat.

---

## 🎯 Fitur Utama

- 🔐 Login & autentikasi (JWT)
- 👥 Manajemen data warga
- 📢 Kelola pengumuman lingkungan
- 📝 Verifikasi laporan keluhan warga
- 🚨 Monitoring SOS darurat
- 💰 Monitoring dana & transaksi
- 🛂 Role & hak akses (Admin / RT / RW)
- 🧪 Demo Mode untuk penilaian juri

---

## 🧠 Teknologi yang Digunakan

- **Framework**: Flutter
- **Bahasa**: Dart
- **State Management**: Provider / Riverpod / Bloc
- **HTTP Client**: Dio
- **Authentication**: JWT
- **Storage**: SharedPreferences
- **Platform**: Android (APK Release)

---

## 📂 Struktur Folder

```bash
lib/
├── core/
│   ├── constants/
│   ├── helpers/
│   └── services/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── warga/
│   ├── pengumuman/
│   ├── laporan/
│   ├── sos/
│   └── dana/
├── models/
├── providers/
├── routes/
├── screens/
├── widgets/
└── main.dart
```

---

⚙️ Environment Configuration

Gunakan file konfigurasi berbasis const atau flavor, contoh:<br>
`lib/core/constants/env.dart`
```dart
class Env {
  static const String baseUrl = "http://localhost:3000";
  static const bool demoMode = true;
}
```

⚠️ API Key dan Secret tidak disimpan di repository, hanya menggunakan endpoint publik backend.

---

### ▶️ Menjalankan Aplikasi
### 1️⃣ Install Dependencies
```bash
flutter pub get
```
### 2️⃣ Jalankan di Mode Development
```bash
flutter run
```
### 3️⃣ Build APK Release
```bash
flutter build apk --release
```

### File APK akan tersedia di:
```bash
build/app/outputs/flutter-apk/app-release.apk
```

---

### 🔗 Integrasi Backend

- Aplikasi Admin terhubung dengan:

- WargaKita Backend API

- Auth berbasis JWT

- REST API JSON

Contoh endpoint:
```bash
POST /auth/login
GET  /admin/warga
POST /admin/pengumuman
GET  /admin/laporan
```

---

### 📦 Submission Lomba

Yang dikumpulkan untuk aplikasi admin:

- Source Code (GitHub)

- APK Release

- Pitch Deck

- Dokumentasi (README)

---

### 👨‍💻 Developer

Mohammad Kencana <br>
SMK Telkom Malang <br>
Project: WargaKita – Smart Citizen Management App <br>

---

### 📄 Lisensi

Proyek ini dibuat untuk keperluan pendidikan dan lomba.
Hak cipta © 2025 WargaKita.

---
