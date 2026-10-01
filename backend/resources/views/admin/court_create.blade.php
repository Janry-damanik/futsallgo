@extends('layouts.admin')
@section('title', 'Tambah Lapangan')
@section('content')
<div class="page-head">
    <div>
        <p class="eyebrow">INVENTARIS VENUE</p>
        <h1>Tambah lapangan</h1>
        <p>Isi informasi lapangan dan unggah fotonya dalam satu langkah.</p>
    </div>
    <a class="btn secondary" href="{{ route('admin.courts') }}">Kembali ke daftar</a>
</div>

<section class="panel">
    <div class="panel-head">
        <div><h2>Informasi lapangan</h2><p class="panel-sub">Foto bersifat opsional dan dapat diperbarui dari daftar lapangan.</p></div>
    </div>
    <form method="post" enctype="multipart/form-data" action="{{ route('admin.courts.store') }}">
        @csrf
        <div class="form-grid">
            <div class="field">
                <label for="court-name">Nama lapangan</label>
                <input id="court-name" class="input" name="name" value="{{ old('name') }}" required maxlength="120" placeholder="Contoh: Lapangan 2">
            </div>
            <div class="field">
                <label for="court-category">Kategori</label>
                <input id="court-category" class="input" name="category" value="{{ old('category', 'Futsal') }}" required maxlength="80">
            </div>
            <div class="field">
                <label for="court-surface">Jenis permukaan</label>
                <input id="court-surface" class="input" name="surface" value="{{ old('surface') }}" maxlength="100" placeholder="Rumput sintetis">
            </div>
            <div class="field">
                <label for="court-price">Tarif khusus per jam</label>
                <input id="court-price" class="input" name="price_per_hour" type="number" min="0" value="{{ old('price_per_hour') }}" placeholder="Kosongkan untuk tarif venue">
            </div>
            <div class="field full">
                <label for="court-description">Deskripsi</label>
                <textarea id="court-description" class="textarea" name="description" rows="3" maxlength="1000" placeholder="Informasi fasilitas lapangan">{{ old('description') }}</textarea>
            </div>
            <div class="field full">
                <label for="court-image">Foto lapangan</label>
                <input id="court-image" class="input" type="file" name="image" accept="image/jpeg,image/png,image/webp">
                <span class="help">Format JPG, PNG, atau WEBP. Ukuran maksimal 5 MB.</span>
            </div>
            <div class="field full">
                <label><input type="checkbox" name="is_active" value="1" @checked(old('is_active', '1') === '1')> Aktif untuk booking</label>
            </div>
        </div>
        <div class="form-actions">
            <button class="btn" type="submit">Simpan lapangan</button>
            <a class="btn secondary" href="{{ route('admin.courts') }}">Batal</a>
        </div>
    </form>
</section>
@endsection