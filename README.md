# FutsalGo

Aplikasi booking Arena Hijau Futsal dengan autentikasi Firebase Email/Password.

## Mengaktifkan verifikasi email

1. Buat atau pilih project di Firebase Console.
2. Aktifkan **Authentication > Sign-in method > Email/Password**.
3. Install FlutterFire CLI jika belum tersedia:

```bash
dart pub global activate flutterfire_cli
```

4. Dari folder project jalankan:

```bash
flutterfire configure
```

5. Pilih project Firebase dan platform Android yang digunakan, lalu jalankan:

```bash
flutter pub get
flutter run
```

Flow pendaftaran akan mengirim email verifikasi. Pengguna tidak dapat masuk ke aplikasi sebelum tautan verifikasi pada email diklik.
