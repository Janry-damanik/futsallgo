<section class="panel" style="margin-top:20px">
    <div class="panel-head">
        <div>
            <h2>Fasilitas venue</h2>
            <p class="panel-sub">Fasilitas ini tampil di Beranda aplikasi pelanggan.</p>
        </div>
    </div>
    <form class="row-form" method="post" action="{{ route('admin.settings.facilities.store') }}">
        @csrf
        <input class="input" name="facility" required minlength="2" maxlength="60" placeholder="Contoh: Kamar mandi">
        <button class="btn" type="submit">Tambah fasilitas</button>
    </form>
    <div style="height:12px"></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>Nama fasilitas</th><th>Aksi</th></tr></thead>
            <tbody>
                @forelse($settings->facilities ?? [] as $index => $facility)
                    <tr>
                        <td>
                            <form class="row-form" method="post" action="{{ route('admin.settings.facilities.update', $index) }}">
                                @csrf @method('PATCH')
                                <input class="input" name="facility" value="{{ $facility }}" required minlength="2" maxlength="60">
                                <button class="btn secondary small" type="submit">Simpan</button>
                            </form>
                        </td>
                        <td>
                            <form method="post" action="{{ route('admin.settings.facilities.delete', $index) }}" onsubmit="return confirm('Hapus fasilitas ini?')">
                                @csrf @method('DELETE')
                                <button class="btn danger small" type="submit">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="2" class="secondary-text">Belum ada fasilitas yang ditambahkan.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>

<section class="panel" style="margin-top:20px">
    <div class="panel-head">
        <div>
            <h2>Deskripsi lapangan</h2>
            <p class="panel-sub">Informasi ini ditampilkan di halaman detail lapangan pelanggan.</p>
        </div>
    </div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>Lapangan</th><th>Jenis permukaan</th><th>Deskripsi</th><th></th></tr></thead>
            <tbody>
                @forelse($courts as $court)
                    <tr>
                        <td class="primary-text">{{ $court->name }}</td>
                        <td colspan="3">
                            <form class="row-form" method="post" action="{{ route('admin.settings.courts.details', $court) }}">
                                @csrf @method('PATCH')
                                <input class="input" name="surface" value="{{ $court->surface }}" maxlength="100" placeholder="Rumput sintetis">
                                <textarea class="textarea" name="description" rows="2" maxlength="1000" placeholder="Deskripsi lapangan">{{ $court->description }}</textarea>
                                <button class="btn secondary small" type="submit">Simpan detail</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="secondary-text">Belum ada lapangan aktif.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>