<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dashboard') | FutsalGo Admin</title>
    <link rel="stylesheet" href="{{ asset('admin.css') }}">
    <link rel="stylesheet" href="{{ asset('admin-polish.css') }}">
</head>
<body>
@php($navigation = [
    ['admin.dashboard', '⌂', 'Ringkasan'],
    ['admin.bookings', '▤', 'Pemesanan'],
    ['admin.courts', '⚽', 'Lapangan'],
    ['admin.promos', '▧', 'Banner'],
    ['admin.customers', '♙', 'Pelanggan'],
    ['admin.settings', '⚙', 'Pengaturan'],
])
<div class="shell">
    <aside class="sidebar">
        <a class="brand" href="{{ route('admin.dashboard') }}"><span class="brand-mark">F</span><span><strong>FutsalGo</strong><small>CONTROL CENTER</small></span></a>
        <div><p class="nav-label">Menu utama</p><nav class="nav-list">
            @foreach($navigation as [$route, $icon, $label])
                <a class="nav-link {{ request()->routeIs($route) ? 'active' : '' }}" href="{{ route($route) }}"><span class="nav-icon">{{ $icon }}</span>{{ $label }}</a>
            @endforeach
        </nav></div>
        <div class="sidebar-bottom"><div class="account"><span class="avatar">{{ strtoupper(substr(auth()->user()->name, 0, 1)) }}</span><span><strong>{{ auth()->user()->name }}</strong><small>Administrator</small></span></div>
            <form method="post" action="{{ route('admin.logout') }}">@csrf<button class="nav-link" style="width:100%;border:0;background:none;text-align:left;cursor:pointer">↪ &nbsp; Keluar</button></form>
        </div>
    </aside>
    <div class="main">
        <div class="mobile-head"><span class="brand-mark">F</span><strong>FutsalGo Admin</strong></div>
        <nav class="mobile-nav">@foreach($navigation as [$route, $icon, $label])<a class="nav-link {{ request()->routeIs($route) ? 'active' : '' }}" href="{{ route($route) }}">{{ $icon }} {{ $label }}</a>@endforeach</nav>
        <header class="topbar"><span class="crumb">Arena operasional <strong>/ @yield('title', 'Ringkasan')</strong></span><span class="crumb">{{ now()->translatedFormat('l, d F Y') }}</span></header>
        <main class="content">
            @if(session('success'))<div class="alert">{{ session('success') }}</div>@endif
            @if($errors->any())<div class="alert errors">{{ $errors->first() }}</div>@endif
            @yield('content')
        </main>
    </div>
</div>
</body>
</html>