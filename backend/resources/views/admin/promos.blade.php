@extends('layouts.admin')
@section('title', 'Banner')
@section('content')
<div class="page-head">
    <div><p class="eyebrow">KONTEN BERANDA</p><h1>Banner</h1><p>Kelola banner yang tampil di bagian atas beranda aplikasi.</p></div>
    <a class="btn" href="{{ route('admin.promos.create') }}">+ Tambah banner</a>
</div>

<section class="panel">
    <div class="panel-head"><div><h2>Daftar banner</h2><p class="panel-sub">{{ $promos->count() }} banner</p></div></div>
    @forelse($promos as $promo)
        <div class="promo-list-row">
            <strong>{{ $promo->title }}</strong>
            <div class="promo-list-actions">
                <a class="btn secondary small" href="{{ route('admin.promos.edit', $promo) }}">Edit</a>
                <form method="post" action="{{ route('admin.promos.delete', $promo) }}" onsubmit="return confirm('Hapus banner ini?')">
                    @csrf @method('DELETE')
                    <button class="btn danger small" type="submit">Hapus</button>
                </form>
            </div>
        </div>
    @empty
        <p class="help">Belum ada banner. Tambahkan banner untuk mulai mengisi beranda.</p>
    @endforelse
</section>
@endsection