# FutsalGo Admin and API

Laravel 12 backend for the FutsalGo admin website and Flutter app. Admin and app data share MySQL database `db-futsal`.

## Local setup

Requirements: PHP 8.2+, Composer, and MySQL (XAMPP is supported).

1. Start MySQL from the XAMPP control panel.
2. Create the database once:

```sql
CREATE DATABASE `db-futsal` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

3. Copy `.env.example` to `.env`, set the MySQL credentials, and replace `ADMIN_PASSWORD` with a private password. Set `MIDTRANS_SERVER_KEY` when enabling real payment callbacks.
4. From this folder, run:

```powershell
composer install
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve
```

Open `http://127.0.0.1:8000/admin/login`. The seeded account uses `ADMIN_EMAIL` and `ADMIN_PASSWORD` from `.env`. Change the example password before exposing the server to a network. Mobile registration requires a six-digit email OTP; configure SMTP in `.env` for delivery. With the default local `MAIL_MAILER=log`, message contents are written to `storage/logs/laravel.log`.

Admins can upload court photos from the admin panel. Court and promo image bytes are stored in the MySQL `stored_images` table and served through Laravel's `/storage/...` route, so uploads survive application deployments without a separate storage service. Apply the `stored_images` migration in production before using image uploads.

## Flutter app

The Android emulator reaches the host machine through `10.0.2.2`. Laravel handles booking data and creates the QRIS transaction using the booking amount stored in MySQL. Configure `MIDTRANS_SERVER_KEY` in `.env`; the default `MIDTRANS_CORE_API_BASE_URL` is the Midtrans Production API. For testing, use a Sandbox key and set `MIDTRANS_CORE_API_BASE_URL=https://api.sandbox.midtrans.com/v2`.

```powershell
flutter run --dart-define=LARAVEL_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For a physical phone, replace `10.0.2.2` with the computer's LAN IP and allow port 8000 through the local firewall. For other Flutter targets, set `LARAVEL_API_BASE_URL` to the reachable Laravel URL.

## Midtrans notification

Configure the Midtrans payment notification URL as:

```text
https://YOUR_PUBLIC_HOST/api/v1/payments/midtrans/notification
```

The endpoint verifies `signature_key` using `MIDTRANS_SERVER_KEY` before changing a booking status. The Flutter client cannot mark a payment as paid. During local development, expose the Laravel server through a secure tunnel if Midtrans must reach its notification endpoint.

## Checks

```powershell
php artisan test
php artisan route:list
```<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://github.com/laravel/framework/actions"><img src="https://github.com/laravel/framework/workflows/tests/badge.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Learning Laravel

Laravel has the most extensive and thorough [documentation](https://laravel.com/docs) and video tutorial library of all modern web application frameworks, making it a breeze to get started with the framework.

You may also try the [Laravel Bootcamp](https://bootcamp.laravel.com), where you will be guided through building a modern Laravel application from scratch.

If you don't feel like reading, [Laracasts](https://laracasts.com) can help. Laracasts contains thousands of video tutorials on a range of topics including Laravel, modern PHP, unit testing, and JavaScript. Boost your skills by digging into our comprehensive video library.

## Laravel Sponsors

We would like to extend our thanks to the following sponsors for funding Laravel development. If you are interested in becoming a sponsor, please visit the [Laravel Partners program](https://partners.laravel.com).

### Premium Partners

- **[Vehikl](https://vehikl.com/)**
- **[Tighten Co.](https://tighten.co)**
- **[WebReinvent](https://webreinvent.com/)**
- **[Kirschbaum Development Group](https://kirschbaumdevelopment.com)**
- **[64 Robots](https://64robots.com)**
- **[Curotec](https://www.curotec.com/services/technologies/laravel/)**
- **[Cyber-Duck](https://cyber-duck.co.uk)**
- **[DevSquad](https://devsquad.com/hire-laravel-developers)**
- **[Jump24](https://jump24.co.uk)**
- **[Redberry](https://redberry.international/laravel/)**
- **[Active Logic](https://activelogic.com)**
- **[byte5](https://byte5.de)**
- **[OP.GG](https://op.gg)**

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
