@extends('layouts.admin')
@section('title', 'Ulasan')
@section('content')
<div class="page-head">
    <div>
        <p class="eyebrow">SUARA PELANGGAN</p>
        <h1>Rating & ulasan</h1>
        <p>Semua ulasan lapangan yang dikirim pelanggan melalui aplikasi.</p>
    </div>
</div>

<section class="stats">
    <article class="stat">
        <div class="stat-top"><span>Rata-rata rating</span><span class="stat-icon">★</span></div>
        <div class="stat-value">{{ number_format($averageRating, 1) }} / 5</div>
        <div class="stat-note">Gabungan seluruh lapangan</div>
    </article>
    <article class="stat">
        <div class="stat-top"><span>Total ulasan</span><span class="stat-icon">☰</span></div>
        <div class="stat-value">{{ number_format($reviewCount) }}</div>
        <div class="stat-note">Ulasan tersimpan</div>
    </article>
</section>

<section class="panel">
    <form class="toolbar" method="get">
        <div class="filters">
            <select class="select" name="court_id">
                <option value="">Semua lapangan</option>
                @foreach($courts as $court)
                    <option value="{{ $court->id }}" @selected((string) $courtId === (string) $court->id)>{{ $court->name }}</option>
                @endforeach
            </select>
            <select class="select" name="rating">
                <option value="">Semua rating</option>
                @foreach([5, 4, 3, 2, 1] as $value)
                    <option value="{{ $value }}" @selected((string) $rating === (string) $value)>{{ $value }} dari 5</option>
                @endforeach
            </select>
            <button class="btn secondary" type="submit">Filter</button>
        </div>
        <span class="help">{{ $reviews->total() }} ulasan</span>
    </form>

    <div class="table-wrap">
        <table>
            <thead><tr><th>Tanggal</th><th>Pelanggan</th><th>Lapangan</th><th>Rating</th><th>Komentar</th></tr></thead>
            <tbody>
                @forelse($reviews as $review)
                    <tr>
                        <td>{{ $review->created_at?->format('d/m/Y H:i') ?? '—' }}</td>
                        <td class="primary-text">{{ $review->user?->name ?? 'Pelanggan' }}<span class="secondary-text">{{ $review->user?->email ?? 'Akun tidak tersedia' }}</span></td>
                        <td>{{ $review->court?->name ?? 'Lapangan dihapus' }}</td>
                        <td><span class="badge confirmed">{{ $review->rating }} / 5</span></td>
                        <td style="min-width:260px;white-space:pre-wrap">{{ $review->comment }}</td>
                    </tr>
                @empty
                    <tr><td colspan="5" style="text-align:center;color:var(--muted);padding:34px">Belum ada ulasan yang sesuai.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="pagination">{{ $reviews->links() }}</div>
</section>
@endsection