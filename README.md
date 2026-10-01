# FutsalGo

Aplikasi booking lapangan futsal. Laravel menyediakan REST API dan panel admin; MySQL menyimpan akun, venue, lapangan, jadwal, dan booking. Flutter menggunakan API Laravel untuk login, profil, booking, dan pengaturan.

## Menjalankan Laravel dan MySQL

1. Jalankan MySQL, lalu konfigurasi `backend/.env` dengan database `db-futsal`, `ADMIN_EMAIL`, dan `ADMIN_PASSWORD`.
2. Dari PowerShell, siapkan database dan admin:

```powershell
cd backend
composer install
php artisan migrate --seed
php artisan storage:link
php artisan serve
```

Server berjalan di `http://127.0.0.1:8000`. Panel admin tersedia di `/admin`; akun admin menggunakan `ADMIN_EMAIL` dan `ADMIN_PASSWORD` dari `.env`. Pendaftaran pelanggan meminta OTP 6 digit lewat email. Untuk pengembangan lokal dengan `MAIL_MAILER=log`, isi email/OTP dicatat di `backend/storage/logs/laravel.log`; atur `MAIL_MAILER=smtp` dan kredensial SMTP di `.env` agar email benar-benar terkirim.

Android emulator memakai `http://10.0.2.2:8000/api/v1` secara default. Flutter Web dan desktop memakai `http://127.0.0.1:8000/api/v1`. Untuk host lain, atur `LARAVEL_API_BASE_URL` melalui `--dart-define`.

Admin dapat mengunggah foto lapangan dari tab **Lapangan** di panel admin. Foto disimpan di Laravel public storage dan otomatis tampil di halaman booking.

Akun yang sebelumnya hanya terdaftar di Firebase belum otomatis ada di database Laravel; pelanggan perlu mendaftar lagi melalui aplikasi.

## Mengaktifkan pembayaran Midtrans

QRIS dibuat oleh backend Laravel setelah booking disimpan. Server Key Midtrans hanya disimpan di `backend/.env`, tidak di APK. Production digunakan secara default.

Atur konfigurasi Midtrans di `backend/.env`:

```dotenv
MIDTRANS_SERVER_KEY=Mid-server-...
MIDTRANS_CORE_API_BASE_URL=https://api.midtrans.com/v2
```

Jalankan Flutter dengan API Laravel yang dapat dijangkau emulator:

```powershell
flutter run --dart-define=LARAVEL_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Untuk pengujian Sandbox, gunakan Server Key Sandbox dan set `MIDTRANS_CORE_API_BASE_URL=https://api.sandbox.midtrans.com/v2`. Laravel harus dapat diakses publik agar Midtrans dapat mengirim notifikasi pembayaran.
