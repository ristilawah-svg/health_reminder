# 🩺 Health Reminder App

Health Reminder App adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna mengatur jadwal kesehatan, seperti pengingat minum obat, vitamin, dan aktivitas kesehatan lainnya. Aplikasi ini memiliki sistem autentikasi pengguna serta penyimpanan data menggunakan MySQL melalui REST API berbasis PHP.

---

## 📱 Fitur Utama

- 🔐 Login & Register User
- 👤 Autentikasi menggunakan MySQL
- 💊 Menambahkan jadwal obat atau vitamin
- 📋 Melihat daftar reminder
- ✏️ Mengubah data reminder
- 🗑️ Menghapus reminder
- 🔔 Notifikasi pengingat
- 📅 Menampilkan tanggal dan waktu reminder

---

## 🛠️ Teknologi yang Digunakan

### Frontend
- Flutter
- Dart
- Material Design

### Backend
- PHP
- REST API

### Database
- MySQL
- phpMyAdmin (XAMPP)

### Tools
- Visual Studio Code
- Android Studio
- XAMPP

---

## 📂 Struktur Project

```
health_reminder/
│
├── android/
├── ios/
├── lib/
│   ├── models/
│   ├── pages/
│   ├── services/
│   ├── widgets/
│   ├── utils/
│   └── main.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── pubspec.yaml
└── README.md
```

---

## 📦 Package Flutter

```yaml
http
flutter_local_notifications
intl
shared_preferences
```

---

## 💾 Database

Database menggunakan **MySQL** yang dijalankan melalui **XAMPP**.

Contoh tabel:

### users

| Field | Type |
|------|------|
| id | int |
| username | varchar |
| email | varchar |
| password | varchar |

### reminders

| Field | Type |
|------|------|
| id | int |
| user_id | int |
| title | varchar |
| description | text |
| reminder_date | date |
| reminder_time | time |

---

## 🚀 Cara Menjalankan Project

### 1. Clone Repository

```bash
git clone https://github.com/username/health_reminder.git
```

### 2. Masuk ke Folder Project

```bash
cd health_reminder
```

### 3. Install Dependency

```bash
flutter pub get
```

### 4. Jalankan XAMPP

Aktifkan:

- Apache
- MySQL

---

### 5. Import Database

Import file SQL ke phpMyAdmin.

---

### 6. Jalankan API PHP

Letakkan folder API pada

```
C:\xampp\htdocs\health_api
```

Lalu akses

```
http://localhost/health_api/
```

---

### 7. Jalankan Flutter

```bash
flutter run
```

---

## 📸 Tampilan Aplikasi

- Login
- Register
- Home
- Tambah Reminder
- Edit Reminder
- Detail Reminder

---

## 🎯 Tujuan Aplikasi

Health Reminder App bertujuan membantu pengguna mengelola jadwal kesehatan secara praktis sehingga tidak lupa mengonsumsi obat, vitamin, maupun melakukan aktivitas kesehatan sesuai waktu yang telah ditentukan.

---

## 👨‍💻 Developer

**Nama:** *(Isi Nama Anda)*

**Mata Kuliah:** Mobile Programming

**Universitas:** *(Isi Nama Universitas)*

---

## 📄 Lisensi

Project ini dibuat untuk keperluan pembelajaran dan tugas mata kuliah Mobile Programming.
