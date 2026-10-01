@extends('layouts.admin')
@section('title', 'Ringkasan')
@section('content')
<div class="page-head"><div><p class="eyebrow">OVERVIEW VENUE</p><h1>Selamat datang, {{ auth()->user()->name }}</h1><p>Berikut kondisi operasional {{ $settings->name }} hari ini.</p></div><a class="btn" href="{{ route('admin.bookings') }}">Lihat pemesanan <span>→</span></a></div>
<section class="stats">
    <article class="stat"><div class="stat-top"><span>Total pemesanan</span><span class="stat-icon">▤</span></div><div class="stat-value">{{ number_format($bookingCount) }}</div><div class="stat-note">{{ $todayCount }} dibuat hari ini</div></article>
    <article class="stat"><div class="stat-top"><span>Perlu ditinjau</span><span class="stat-icon">◷</span></div><div class="stat-value">{{ number_format($pendingCount) }}</div><div class="stat-note">Menunggu konfirmasi atau pembayaran</div></article>
    <article class="stat"><div class="stat-top"><span>Pendapatan tercatat</span><span class="stat-icon">↗</span></div><div class="stat-value" style="font-size:21px">Rp {{ number_format($revenue, 0, ',', '.') }}</div><div class="stat-note">Booking terkonfirmasi dan selesai</div></article>
    <article class="stat"><div class="stat-top"><span>Pelanggan terdaftar</span><span class="stat-icon">♙</span></div><div class="stat-value">{{ number_format($customerCount) }}</div><div class="stat-note">{{ $courtCount }} lapangan aktif</div></article>
</section>
<section class="stats occupancy-summary" id="occupancy-panel" data-endpoint="{{ route('admin.dashboard.occupancy') }}">
    <article class="stat">
        <div class="stat-top"><span>Lapangan tersedia</span><span class="stat-icon">✓</span></div>
        <div class="stat-value" id="occupancy-current-available">{{ $occupancy['current']['available'] ?? '—' }}</div>
        <div class="stat-note">lapangan lagi</div>
    </article>
    <article class="stat">
        <div class="stat-top"><span>Dipakai saat ini</span><span class="stat-icon">◷</span></div>
        <div class="stat-value" id="occupancy-current-occupied">{{ $occupancy['current']['occupied'] ?? '—' }}</div>
        <div class="stat-note">booking aktif, termasuk menunggu bayar dan lunas</div>
    </article>
    <article class="stat">
        <div class="stat-top"><span>Total lapangan aktif</span><span class="stat-icon">⚽</span></div>
        <div class="stat-value" id="occupancy-active-courts">{{ $occupancy['courtCount'] }}</div>
        <div class="stat-note" id="occupancy-current-period">{{ $occupancy['current']['label'] ?? 'Di luar jam operasional' }}</div>
    </article>
</section>
<details class="panel occupancy-details">
    <summary>
        <strong>Rincian per jam</strong>
        <span class="occupancy-refresh-note"><span class="live-dot"></span> Diperbarui <span id="occupancy-updated-at">{{ \Illuminate\Support\Carbon::parse($occupancy['updatedAt'])->format('H:i:s') }}</span></span>
    </summary>
    <div class="table-wrap occupancy-table-wrap">
        <table>
            <thead><tr><th>Jam</th><th>Terisi</th><th>Kosong</th><th>Kondisi</th></tr></thead>
            <tbody id="occupancy-table-body">
                @forelse($occupancy['hours'] as $hour)
                    @php($statusClass = $hour['status'] === 'Penuh' ? 'full' : ($hour['status'] === 'Kosong' ? 'open' : ($hour['status'] === 'Sebagian terisi' ? 'partial' : 'inactive')))
                    <tr class="{{ $hour['isCurrent'] ? 'current-hour' : '' }}">
                        <td class="primary-text">{{ $hour['label'] }} @if($hour['isCurrent'])<span class="current-tag">SAAT INI</span>@endif</td>
                        <td><strong>{{ $hour['occupied'] }} lapangan</strong><span class="secondary-text">{{ $hour['occupiedCourts'] ? implode(', ', $hour['occupiedCourts']) : '—' }}</span></td>
                        <td><strong>{{ $hour['available'] }} lapangan</strong><span class="secondary-text">{{ $hour['availableCourts'] ? implode(', ', $hour['availableCourts']) : '—' }}</span></td>
                        <td><span class="occupancy-badge {{ $statusClass }}">{{ $hour['status'] }}</span></td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="occupancy-empty">Tidak ada jam operasional hari ini.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</details>
<p class="occupancy-error" id="occupancy-error" role="status" hidden>Data belum berhasil diperbarui. Mencoba lagi otomatis.</p>
<section class="panel"><div class="panel-head"><div><h2>Pemesanan terbaru</h2><p class="panel-sub">Aktivitas booking pelanggan yang baru masuk</p></div><a class="btn secondary small" href="{{ route('admin.bookings') }}">Semua data</a></div>
    <div class="table-wrap"><table><thead><tr><th>Kode</th><th>Pelanggan</th><th>Lapangan</th><th>Jadwal</th><th>Total</th><th>Status</th></tr></thead><tbody>
    @forelse($recentBookings as $booking)
        @php($statusClass = match($booking->status) {'Menunggu pembayaran' => 'pending', 'Dikonfirmasi', 'Lunas via Midtrans' => 'confirmed', 'Selesai' => 'done', 'Dibatalkan' => 'cancelled', default => ''})
        <tr><td class="primary-text">{{ $booking->code }}</td><td>{{ $booking->customer_name }}<span class="secondary-text">{{ $booking->customer_email ?: 'Email tidak tersedia' }}</span></td><td>{{ $booking->field_name }}</td><td>{{ $booking->booking_date }}<span class="secondary-text">{{ $booking->booking_time }}</span></td><td class="primary-text">Rp {{ number_format($booking->amount, 0, ',', '.') }}</td><td><span class="badge {{ $statusClass }}">{{ $booking->status }}</span></td></tr>
    @empty<tr><td colspan="6" style="text-align:center;color:var(--muted);padding:34px">Belum ada data pemesanan.</td></tr>@endforelse
    </tbody></table></div>
</section>
<section class="panel"><div class="panel-head"><div><h2>Profil venue</h2><p class="panel-sub">Informasi yang tampil di aplikasi pelanggan</p></div><a class="btn secondary small" href="{{ route('admin.settings') }}">Atur venue</a></div><div class="stats" style="margin:0;grid-template-columns:repeat(3,minmax(0,1fr))"><div><span class="secondary-text">NAMA VENUE</span><strong>{{ $settings->name }}</strong></div><div><span class="secondary-text">JAM OPERASIONAL</span><strong>{{ substr($settings->open_time, 0, 5) }} - {{ substr($settings->close_time, 0, 5) }}</strong></div><div><span class="secondary-text">HARGA PER JAM</span><strong>Rp {{ number_format($settings->hourly_price, 0, ',', '.') }}</strong></div></div></section>
<script>
(() => {
    const panel = document.getElementById('occupancy-panel');
    if (!panel) return;

    const tableBody = document.getElementById('occupancy-table-body');
    const errorMessage = document.getElementById('occupancy-error');
    const occupiedNow = document.getElementById('occupancy-current-occupied');
    const availableNow = document.getElementById('occupancy-current-available');
    const currentPeriod = document.getElementById('occupancy-current-period');
    const updatedAt = document.getElementById('occupancy-updated-at');
    const makeCell = (count, names) => {
        const cell = document.createElement('td');
        const total = document.createElement('strong');
        const detail = document.createElement('span');
        total.textContent = `${count} lapangan`;
        detail.className = 'secondary-text';
        detail.textContent = names.length ? names.join(', ') : '—';
        cell.append(total, detail);
        return cell;
    };

    const render = (data) => {
        const current = data.current;
        occupiedNow.textContent = current ? current.occupied : '—';
        availableNow.textContent = current ? current.available : '—';
        currentPeriod.textContent = current ? current.label : 'Di luar jam operasional';
        updatedAt.textContent = new Intl.DateTimeFormat('id-ID', {
            hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
            timeZone: 'Asia/Jakarta',
        }).format(new Date(data.updatedAt));

        tableBody.replaceChildren();
        if (!data.hours.length) {
            const row = document.createElement('tr');
            const cell = document.createElement('td');
            cell.colSpan = 4;
            cell.className = 'occupancy-empty';
            cell.textContent = 'Tidak ada jam operasional hari ini.';
            row.append(cell);
            tableBody.append(row);
            return;
        }

        data.hours.forEach((hour) => {
            const row = document.createElement('tr');
            if (hour.isCurrent) row.classList.add('current-hour');
            const timeCell = document.createElement('td');
            const time = document.createElement('span');
            time.className = 'primary-text';
            time.textContent = hour.label;
            timeCell.append(time);
            if (hour.isCurrent) {
                const tag = document.createElement('span');
                tag.className = 'current-tag';
                tag.textContent = 'SAAT INI';
                timeCell.append(tag);
            }

            const statusCell = document.createElement('td');
            const badge = document.createElement('span');
            const statusClass = hour.status === 'Penuh' ? 'full'
                : hour.status === 'Kosong' ? 'open'
                : hour.status === 'Sebagian terisi' ? 'partial' : 'inactive';
            badge.className = `occupancy-badge ${statusClass}`;
            badge.textContent = hour.status;
            statusCell.append(badge);
            row.append(
                timeCell,
                makeCell(hour.occupied, hour.occupiedCourts),
                makeCell(hour.available, hour.availableCourts),
                statusCell,
            );
            tableBody.append(row);
        });
    };

    const refresh = async () => {
        try {
            const response = await fetch(panel.dataset.endpoint, {
                headers: { Accept: 'application/json' },
                cache: 'no-store',
                credentials: 'same-origin',
            });
            if (!response.ok) throw new Error('Gagal memuat okupansi.');
            const payload = await response.json();
            render(payload.data);
            errorMessage.hidden = true;
        } catch (_) {
            errorMessage.hidden = false;
        }
    };

    refresh();
    window.setInterval(refresh, 30000);
})();
</script>
@endsection