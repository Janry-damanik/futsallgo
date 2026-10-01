<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BlockedSlot;
use App\Models\Booking;
use App\Models\Court;
use App\Models\CourtReview;
use App\Models\PromoBanner;
use App\Models\User;
use App\Models\VenueSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ManagementController extends Controller
{
    public function bookings(Request $request)
    {
        $bookings = Booking::query()
            ->when($request->filled('q'), fn ($query) => $query->where(function ($query) use ($request) {
                $term = '%'.$request->string('q').'%';
                $query->where('code', 'like', $term)->orWhere('customer_name', 'like', $term)->orWhere('field_name', 'like', $term);
            }))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->latest()->paginate(12)->withQueryString();

        return view('admin.bookings', compact('bookings'));
    }

    public function finance(Request $request)
    {
        $filters = $request->validate([
            'from' => ['nullable', 'date'],
            'until' => ['nullable', 'date', 'after_or_equal:from'],
            'status' => ['nullable', 'in:Menunggu pembayaran,Dikonfirmasi,Lunas via Midtrans,Selesai,Dibatalkan'],
            'q' => ['nullable', 'string', 'max:120'],
        ]);
        $from = $filters['from'] ?? now()->subDays(29)->toDateString();
        $until = $filters['until'] ?? now()->toDateString();
        $period = Booking::query()
            ->whereDate('created_at', '>=', $from)
            ->whereDate('created_at', '<=', $until);
        $paidStatuses = ['Dikonfirmasi', 'Selesai', 'Lunas via Midtrans'];
        $paid = (clone $period)->whereIn('status', $paidStatuses);
        $pending = (clone $period)->where('status', 'Menunggu pembayaran');
        $orders = (clone $period)
            ->when($request->filled('status'), fn ($query) => $query->where('status', $filters['status']))
            ->when($request->filled('q'), fn ($query) => $query->where(function ($query) use ($filters) {
                $term = '%'.$filters['q'].'%';
                $query->where('code', 'like', $term)
                    ->orWhere('customer_name', 'like', $term)
                    ->orWhere('customer_email', 'like', $term)
                    ->orWhere('field_name', 'like', $term)
                    ->orWhere('payment_order_id', 'like', $term);
            }))
            ->latest('created_at')
            ->paginate(15)
            ->withQueryString();

        return view('admin.finance', [
            'orders' => $orders,
            'from' => $from,
            'until' => $until,
            'status' => $filters['status'] ?? '',
            'query' => $filters['q'] ?? '',
            'orderCount' => (clone $period)->count(),
            'paidCount' => (clone $paid)->count(),
            'revenue' => (clone $paid)->sum('amount'),
            'pendingCount' => (clone $pending)->count(),
            'pendingAmount' => (clone $pending)->sum('amount'),
        ]);
    }

    public function reviews(Request $request)
    {
        $filters = $request->validate([
            'court_id' => ['nullable', 'integer', 'exists:courts,id'],
            'rating' => ['nullable', 'integer', 'between:1,5'],
        ]);
        $reviews = CourtReview::query()
            ->with(['court:id,name', 'user:id,name,email'])
            ->when($request->filled('court_id'), fn ($query) => $query->where('court_id', $filters['court_id']))
            ->when($request->filled('rating'), fn ($query) => $query->where('rating', $filters['rating']))
            ->latest('created_at')
            ->paginate(20)
            ->withQueryString();

        return view('admin.reviews', [
            'reviews' => $reviews,
            'courts' => Court::query()->orderBy('name')->get(['id', 'name']),
            'courtId' => $filters['court_id'] ?? '',
            'rating' => $filters['rating'] ?? '',
            'averageRating' => (float) (CourtReview::query()->avg('rating') ?? 0),
            'reviewCount' => CourtReview::query()->count(),
        ]);
    }

    public function updateBooking(Request $request, Booking $booking)
    {
        $booking->update($request->validate(['status' => ['required', 'in:Menunggu pembayaran,Dikonfirmasi,Selesai,Dibatalkan,Lunas via Midtrans']]));

        return back()->with('success', 'Status booking diperbarui.');
    }

    public function deleteBooking(Booking $booking)
    {
        $booking->delete();

        return back()->with('success', 'Data booking dihapus.');
    }

    public function courts()
    {
        return view('admin.courts', ['courts' => Court::orderBy('name')->get()]);
    }

    public function createCourt()
    {
        return view('admin.court_create');
    }

    public function storeCourt(Request $request)
    {
        $data = $this->courtData($request);
        $request->validate([
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->storePublicly('courts', 'public');
        }
        Court::create($data);

        return redirect()->route('admin.courts')->with('success', 'Lapangan ditambahkan.');
    }

    public function uploadCourtImage(Request $request, Court $court)
    {
        $data = $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $path = $data['image']->storePublicly('courts', 'public');

        if ($court->image_path) {
            Storage::disk('public')->delete($court->image_path);
        }

        $court->update(['image_path' => $path]);

        return back()->with('success', 'Foto lapangan berhasil diperbarui.');
    }

    public function updateCourt(Request $request, Court $court)
    {
        $court->update($this->courtData($request, $court));

        return back()->with('success', 'Data lapangan diperbarui.');
    }

    public function deleteCourt(Court $court)
    {
        $court->delete();

        return back()->with('success', 'Lapangan dihapus.');
    }

    public function promos()
    {
        return view('admin.promos', [
            'promos' => PromoBanner::query()->orderBy('id')->get(),
        ]);
    }

    public function createPromo()
    {
        return view('admin.promo_form', ['promo' => null]);
    }

    public function editPromo(PromoBanner $promo)
    {
        return view('admin.promo_form', compact('promo'));
    }

    public function storePromo(Request $request)
    {
        $data = $this->promoData($request);
        $request->validate([
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->storePublicly('promo-banners', 'public');
        }
        PromoBanner::query()->create($data);

        return redirect()->route('admin.promos')->with('success', 'Banner ditambahkan.');
    }

    public function updatePromo(Request $request, PromoBanner $promo)
    {
        $data = $this->promoData($request);
        $request->validate([
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        if ($request->hasFile('image')) {
            if ($promo->image_path) {
                Storage::disk('public')->delete($promo->image_path);
            }
            $data['image_path'] = $request->file('image')->storePublicly('promo-banners', 'public');
        }
        $promo->update($data);

        return redirect()->route('admin.promos')->with('success', 'Banner diperbarui.');
    }

    public function uploadPromoImage(Request $request, PromoBanner $promo)
    {
        $data = $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $path = $data['image']->storePublicly('promo-banners', 'public');

        if ($promo->image_path) {
            Storage::disk('public')->delete($promo->image_path);
        }

        $promo->update(['image_path' => $path]);

        return back()->with('success', 'Foto banner berhasil diperbarui.');
    }

    public function deletePromo(PromoBanner $promo)
    {
        if ($promo->image_path) {
            Storage::disk('public')->delete($promo->image_path);
        }
        $promo->delete();

        return back()->with('success', 'Banner dihapus.');
    }

    private function promoData(Request $request): array
    {
        return $request->validate([
            'eyebrow' => ['required', 'string', 'max:80'],
            'title' => ['required', 'string', 'max:120'],
            'subtitle' => ['nullable', 'string', 'max:180'],
            'button_label' => ['required', 'string', 'max:40'],
        ]);
    }

    private function courtData(Request $request, ?Court $court = null): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:120', 'unique:courts,name,'.($court?->id ?? 'NULL')],
            'category' => ['required', 'string', 'max:80'],
            'surface' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
            'price_per_hour' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]) + ['is_active' => $request->boolean('is_active')];
    }

    public function customers(Request $request)
    {
        $customers = User::query()
            ->when($request->filled('q'), fn ($query) => $query->where(fn ($query) => $query
                ->where('name', 'like', '%'.$request->string('q').'%')
                ->orWhere('email', 'like', '%'.$request->string('q').'%')))
            ->withCount('bookings')->orderBy('name')->paginate(15)->withQueryString();

        return view('admin.customers', compact('customers'));
    }

    public function storeCustomer(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:180', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'in:customer,admin'],
        ]);
        if ($data['role'] === 'admin') {
            $data['email_verified_at'] = now();
        }
        User::create($data);

        return back()->with('success', 'Akun pengguna dibuat.');
    }

    public function updateCustomer(Request $request, User $user)
    {
        abort_if($request->user()->is($user), 422, 'Akun yang sedang digunakan tidak dapat diubah di sini.');
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:180', 'unique:users,email,'.$user->id],
            'role' => ['required', 'in:customer,admin'],
            'password' => ['nullable', 'string', 'min:8'],
        ]);
        if (filled($data['password'] ?? null)) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }
        if ($data['role'] === 'admin' && ! $user->email_verified_at) {
            $data['email_verified_at'] = now();
        }
        $user->update($data);

        return back()->with('success', 'Akun pengguna diperbarui.');
    }

    public function deleteCustomer(Request $request, User $user)
    {
        abort_if($request->user()->is($user), 422, 'Akun yang sedang digunakan tidak dapat dihapus.');
        $user->delete();

        return back()->with('success', 'Akun pengguna dihapus.');
    }

    public function settings()
    {
        return view('admin.settings', [
            'settings' => VenueSetting::current(),
            'slots' => BlockedSlot::orderBy('slot')->get(),
            'courts' => Court::query()->where('is_active', true)->orderBy('name')->get(),
        ]);
    }

    public function storeFacility(Request $request)
    {
        $facility = trim($request->validate([
            'facility' => ['required', 'string', 'min:2', 'max:60'],
        ])['facility']);
        $settings = VenueSetting::current();
        $facilities = $settings->facilities ?? [];
        abort_if(collect($facilities)->contains(fn ($item) => mb_strtolower($item) === mb_strtolower($facility)), 422, 'Fasilitas tersebut sudah terdaftar.');
        $facilities[] = $facility;
        $settings->update(['facilities' => array_values($facilities)]);

        return back()->with('success', 'Fasilitas venue ditambahkan.');
    }

    public function updateFacility(Request $request, int $index)
    {
        $facility = trim($request->validate([
            'facility' => ['required', 'string', 'min:2', 'max:60'],
        ])['facility']);
        $settings = VenueSetting::current();
        $facilities = $settings->facilities ?? [];
        abort_unless(array_key_exists($index, $facilities), 404);
        abort_if(collect($facilities)->except($index)->contains(fn ($item) => mb_strtolower($item) === mb_strtolower($facility)), 422, 'Fasilitas tersebut sudah terdaftar.');
        $facilities[$index] = $facility;
        $settings->update(['facilities' => array_values($facilities)]);

        return back()->with('success', 'Fasilitas venue diperbarui.');
    }

    public function deleteFacility(int $index)
    {
        $settings = VenueSetting::current();
        $facilities = $settings->facilities ?? [];
        abort_unless(array_key_exists($index, $facilities), 404);
        unset($facilities[$index]);
        $settings->update(['facilities' => array_values($facilities)]);

        return back()->with('success', 'Fasilitas venue dihapus.');
    }

    public function updateCourtDetails(Request $request, Court $court)
    {
        $court->update($request->validate([
            'surface' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
        ]));

        return back()->with('success', 'Deskripsi lapangan diperbarui.');
    }

    public function updateSettings(Request $request)
    {
        $settings = VenueSetting::current();
        $settings->update($request->validate([
            'name' => ['required', 'string', 'max:160'],
            'address' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32'],
            'hourly_price' => ['required', 'integer', 'min:1'],
            'open_time' => ['required', 'date_format:H:i'],
            'close_time' => ['required', 'date_format:H:i', 'after:open_time'],
        ]));

        return back()->with('success', 'Informasi venue dan jam operasional disimpan.');
    }

    public function storeSlot(Request $request)
    {
        $data = $request->validate(['slot' => ['required', 'date_format:H:i', 'unique:blocked_slots,slot']]);
        BlockedSlot::create($data);

        return back()->with('success', 'Slot booking diblokir.');
    }

    public function deleteSlot(BlockedSlot $blockedSlot)
    {
        $blockedSlot->delete();

        return back()->with('success', 'Slot booking dibuka kembali.');
    }
}
