<!doctype html>
<html lang="id">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Masuk Admin | FutsalGo</title><link rel="stylesheet" href="{{ asset('admin.css') }}"></head>
<body>
<main class="login-page">
    <section class="login-aside">
        <a class="brand" href="/"><span class="brand-mark">F</span><span><strong>FutsalGo</strong><small>CONTROL CENTER</small></span></a>
        <div><p class="eyebrow" style="color:#a7e6c2">OPERASIONAL VENUE</p><h1>Semua jadwal,<br>terkendali.</h1><p>Kelola lapangan, pantau pemesanan, dan atur aktivitas venue dari satu tempat.</p></div>
        <small style="color:#9fbcae">FutsalGo Admin · {{ date('Y') }}</small>
    </section>
    <section class="login-form-wrap"><form class="login-form" method="post" action="{{ route('admin.login') }}">
        @csrf<p class="eyebrow">AKSES ADMIN</p><h2>Selamat datang</h2><p>Masuk menggunakan akun administrator venue.</p>
        <div class="field"><label for="email">Email admin</label><input class="input" id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="username" required autofocus placeholder="admin@futsalgo.com"></div>
        <div class="field"><label for="password">Kata sandi</label><input class="input" id="password" name="password" type="password" autocomplete="current-password" required placeholder="Masukkan kata sandi"></div>
        @error('email')<div class="error-text">{{ $message }}</div>@enderror
        <label style="display:flex;align-items:center;gap:8px;color:var(--muted);font-size:12px;margin:14px 0"><input type="checkbox" name="remember" value="1"> Ingat saya</label>
        <button class="btn" type="submit">Masuk ke dashboard <span aria-hidden="true">→</span></button>
    </form></section>
</main>
</body>
</html>