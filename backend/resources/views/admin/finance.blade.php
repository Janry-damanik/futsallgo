@extends('layouts.admin')
@section('title', 'Keuangan')
@section('content')
<div class="page-head">
    <div>
        <p class="eyebrow">LAPORAN TRANSAKSI</p>
        <h1>Keuangan & pesanan</h1>
        <p>Rangkuman pembayaran dan rincian booking pada periode terpilih.</p>
    </div>
</div>

<section class="stats">
    <article class="stat">
        <div class="stat-top"><span>Pemasukan tercatat</span><span class="stat-icon">Rp</span></div>
        <div class="stat-value" style="font-size:21px">Rp {{ number_format($revenue, 0, ',', '.') }}</div>
        <div class="stat-note">{{ $paidCount }} pesanan lunas/terkonfirmasi</div>
    </article>
    <article class="stat">
        <div class="stat-top"><span>Menunggu pembayaran</span><span class="stat-icon">◷</span></div>
        <div class="stat-value">{{ number_format($pendingCount) }}</div>
        <div class="stat-note">Rp {{ number_format($pendingAmount, 0, ',', '.') }} belum tercatat sebagai pemasukan</div>
    </article>
    <article class="stat">
        <div class="stat-top"><span>Total pesanan</span><span class="stat-icon">▤</span></div>
        <div class="stat-value">{{ number_format($orderCount) }}</div>
        <div class="stat-note">Pada periode yang dipilih</div>
    </article>
</section>

<section class="panel">
    <form class="toolbar" method="get">
        <div class="filters">
            <label class="help">Dari <input class="input" type="date" name="from" value="{{ $from }}"></label>
            <label class="help">Sampai <input class="input" type="date" name="until" value="{{ $until }}"></label>
            <select class="select" name="status">
                <option value="">Semua status</option>
                @foreach(['Menunggu pembayaran', 'Dikonfirmasi', 'Lunas via Midtrans', 'Selesai', 'Dibatalkan'] as $option)
                    <option value="{{ $option }}" @selected($status === $option)>{{ $option }}</option>
                @endforeach
            </select>
            <input class="input" name="q" value="{{ $query }}" placeholder="Kode, pelanggan, lapangan, order ID">
            <button class="btn secondary" type="submit">Terapkan</button>
        </div>
        <span class="help">{{ $orders->total() }} pesanan</span>
    </form>

    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Waktu masuk</th>
                    <th>Kode / order pembayaran</th>
                    <th>Pelanggan</th>
                    <th>Lapangan & jadwal</th>
                    <th>Durasi</th>
                    <th>Nominal</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                @forelse($orders as $booking)
                    @php($statusClass = match($booking->status) {'Menunggu pembayaran' => 'pending', 'Dikonfirmasi', 'Lunas via Midtrans' => 'confirmed', 'Selesai' => 'done', 'Dibatalkan' => 'cancelled', default => ''})
                    <tr>
                        <td>{{ $booking->created_at?->format('d/m/Y H:i') ?? '—' }}</td>
                        <td class="primary-text">{{ $booking->code }}<span class="secondary-text">{{ $booking->payment_order_id ?: 'ID pembayaran tidak tersedia' }}</span></td>
                        <td>{{ $booking->customer_name }}<span class="secondary-text">{{ $booking->customer_email ?: 'Email tidak tersedia' }}</span></td>
                        <td>{{ $booking->field_name }}<span class="secondary-text">{{ $booking->booking_date }} · {{ $booking->booking_time }}</span></td>
                        <td>{{ $booking->duration_hours }} jam</td>
                        <td class="primary-text">Rp {{ number_format($booking->amount, 0, ',', '.') }}</td>
                        <td><span class="badge {{ $statusClass }}">{{ $booking->status }}</span></td>
                    </tr>
                @empty
                    <tr><td colspan="7" style="text-align:center;color:var(--muted);padding:34px">Tidak ada pesanan pada filter ini.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div class="pagination">{{ $orders->links() }}</div>
</section>
@endsection