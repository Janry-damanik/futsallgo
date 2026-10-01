@extends('layouts.admin')
@section('title', $promo ? 'Edit Banner' : 'Tambah Banner')
@section('content')
<div class="page-head">
    <div>
        <p class="eyebrow">KONTEN BERANDA</p>
        <h1>{{ $promo ? 'Edit banner' : 'Tambah banner' }}</h1>
        <p>Atur tulisan dan foto banner yang tampil di aplikasi.</p>
    </div>
    <a class="btn secondary" href="{{ route('admin.promos') }}">Kembali ke daftar</a>
</div>

<section class="panel">
    <div class="panel-head"><div><h2>Konten banner</h2><p class="panel-sub">Foto opsional. JPG, PNG, atau WEBP maksimal 5 MB.</p></div></div>
    <form method="post" enctype="multipart/form-data" action="{{ $promo ? route('admin.promos.update', $promo) : route('admin.promos.store') }}">
        @csrf
        @if($promo) @method('PUT') @endif
        <div class="form-grid">
            <div class="field">
                <label for="promo-eyebrow">Tulisan kecil</label>
                <input id="promo-eyebrow" class="input" name="eyebrow" value="{{ old('eyebrow', $promo?->eyebrow ?? 'FUTSALGO / LAPANGAN') }}" required maxlength="80">
            </div>
            <div class="field">
                <label for="promo-title">Judul</label>
                <input id="promo-title" class="input" name="title" value="{{ old('title', $promo?->title) }}" required maxlength="120">
            </div>
            <div class="field full">
                <label for="promo-subtitle">Deskripsi</label>
                <textarea id="promo-subtitle" class="textarea" name="subtitle" rows="3" maxlength="180">{{ old('subtitle', $promo?->subtitle) }}</textarea>
            </div>
            <div class="field">
                <label for="promo-button">Tulisan tombol</label>
                <input id="promo-button" class="input" name="button_label" value="{{ old('button_label', $promo?->button_label ?? 'Pesan lapangan') }}" required maxlength="40">
            </div>
            <div class="field">
                <label for="promo-image">Foto banner</label>
                <input id="promo-image" class="input" type="file" name="image" accept="image/jpeg,image/png,image/webp">
            </div>
        </div>
        @if($promo?->image_path)
            <div class="promo-current-image">
                <span class="help">Foto saat ini</span>
                <img src="{{ request()->getSchemeAndHttpHost().'/storage/'.$promo->image_path }}" alt="Foto {{ $promo->title }}">
            </div>
        @endif
        <div class="form-actions">
            <button class="btn" type="submit">{{ $promo ? 'Simpan perubahan' : 'Tambah banner' }}</button>
            <a class="btn secondary" href="{{ route('admin.promos') }}">Batal</a>
        </div>
    </form>
</section>
@endsection