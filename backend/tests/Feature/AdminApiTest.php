<?php

namespace Tests\Feature;

use App\Mail\EmailVerificationCodeMail;
use App\Models\BlockedSlot;
use App\Models\Booking;
use App\Models\Court;
use App\Models\CourtReview;
use App\Models\PromoBanner;
use App\Models\User;
use App\Models\VenueSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_sports_news_returns_top_headlines(): void
    {
        config(['services.newsapi.key' => 'test-news-key']);
        Cache::forget('newsapi.sports.id');
        Http::fake([
            'https://newsapi.org/v2/everything*' => Http::response([
                'status' => 'ok',
                'articles' => [[
                    'title' => 'Timnas menang',
                    'description' => 'Kemenangan pada laga malam ini.',
                    'urlToImage' => 'https://example.com/football.jpg',
                    'url' => 'https://example.com/football',
                    'source' => ['name' => 'Berita Olahraga'],
                    'publishedAt' => '2026-10-02T10:00:00Z',
                ]],
            ]),
        ]);

        $this->getJson('/api/v1/sports-news')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Timnas menang')
            ->assertJsonPath('data.0.source', 'Berita Olahraga');

        Http::assertSent(fn ($request) => str_starts_with(
            $request->url(),
            'https://newsapi.org/v2/everything',
        ) && $request['q'] === 'football OR soccer OR futsal OR sports'
            && $request['sortBy'] === 'publishedAt');
    }

    public function test_admin_can_update_venue_facilities_and_court_description(): void
    {
        $admin = User::create([
            'name' => 'Admin Venue',
            'email' => 'venue-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 200000]);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/facilities', [
            'facilities' => ['Kamar mandi', 'Kantin', 'kamar mandi'],
        ])->assertOk()->assertJsonCount(2, 'data.facilities');

        $this->patchJson('/api/v1/courts/Lapangan%201', [
            'surface' => 'Rumput sintetis',
            'description' => 'Lapangan indoor dengan tribun.',
        ])->assertOk()->assertJsonPath('data.description', 'Lapangan indoor dengan tribun.');

        $this->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.facilities.0', 'Kamar mandi')
            ->assertJsonPath('data.courtDescriptions.Lapangan 1', 'Lapangan indoor dengan tribun.')
            ->assertJsonPath('data.courtSurfaces.Lapangan 1', 'Rumput sintetis');
    }

    public function test_customers_can_review_a_court_and_see_average_rating(): void
    {
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 200000]);
        $firstCustomer = User::create([
            'name' => 'Dina',
            'email' => 'dina-review@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $secondCustomer = User::create([
            'name' => 'Raka',
            'email' => 'raka-review@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        Sanctum::actingAs($firstCustomer);
        $this->postJson('/api/v1/courts/Lapangan%201/reviews', [
            'rating' => 5,
            'comment' => 'Lapangan bersih dan nyaman.',
        ])->assertOk()->assertJsonPath('data.averageRating', 5);

        Sanctum::actingAs($secondCustomer);
        $this->postJson('/api/v1/courts/Lapangan%201/reviews', [
            'rating' => 3,
            'comment' => 'Tempatnya cukup baik.',
        ])->assertOk()
            ->assertJsonPath('data.averageRating', 4)
            ->assertJsonCount(2, 'data.reviews');

        $this->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.courtRatings.Lapangan 1.average', 4)
            ->assertJsonPath('data.courtRatings.Lapangan 1.count', 2);
    }

    public function test_admin_can_upload_court_image_and_customers_cannot(): void
    {
        Storage::fake('public');
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $customer = User::create([
            'name' => 'Customer',
            'email' => 'customer@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 200000]);

        Sanctum::actingAs($admin);
        $upload = $this->postJson('/api/v1/courts/Lapangan%201/image', [
            'image' => UploadedFile::fake()->image('lapangan.png'),
        ])->assertOk()->assertJsonPath('data.name', 'Lapangan 1');

        $imagePath = Court::query()->where('name', 'Lapangan 1')->value('image_path');
        Storage::disk('public')->assertExists($imagePath);
        $this->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.courtImages.Lapangan 1', $upload->json('data.imageUrl'));

        Sanctum::actingAs($customer);
        $this->postJson('/api/v1/courts/Lapangan%201/image', [
            'image' => UploadedFile::fake()->image('forbidden.png'),
        ])->assertForbidden();
    }

    public function test_admin_can_manage_public_home_promos(): void
    {
        Storage::fake('public');
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'promo-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $customer = User::create([
            'name' => 'Customer',
            'email' => 'promo-customer@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $this->getJson('/api/v1/promos')->assertOk()->assertJsonCount(2, 'data');

        Sanctum::actingAs($admin);
        $created = $this->postJson('/api/v1/promos', [
            'eyebrow' => 'PROMO',
            'title' => 'Main bareng',
            'subtitle' => 'Pesan sesi sore ini.',
            'buttonLabel' => 'Lihat jadwal',
        ])->assertCreated()->assertJsonPath('data.title', 'Main bareng');
        $promoId = $created->json('data.id');

        $this->putJson("/api/v1/promos/{$promoId}", [
            'eyebrow' => 'PROMO SPESIAL',
            'title' => 'Main lebih seru',
            'subtitle' => 'Lapangan menunggumu.',
            'buttonLabel' => 'Pesan sekarang',
        ])->assertOk()->assertJsonPath('data.title', 'Main lebih seru')
            ->assertJsonPath('data.buttonLabel', 'Pesan sekarang');

        $this->postJson("/api/v1/promos/{$promoId}/image", [
            'image' => UploadedFile::fake()->image('banner.png'),
        ])->assertOk()->assertJsonPath('data.title', 'Main lebih seru');
        $imagePath = DB::table('promo_banners')->where('id', $promoId)->value('image_path');
        Storage::disk('public')->assertExists($imagePath);

        Sanctum::actingAs($customer);
        $this->postJson('/api/v1/promos', [
            'eyebrow' => 'PROMO',
            'title' => 'Tidak diizinkan',
            'buttonLabel' => 'Pesan',
        ])->assertForbidden();

        Sanctum::actingAs($admin);
        $this->deleteJson("/api/v1/promos/{$promoId}")->assertOk();
    }

    public function test_web_admin_can_upload_court_image_from_courts_page(): void
    {
        Storage::fake('public');
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'web-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 200000]);

        $this->actingAs($admin)
            ->get('/admin/courts')
            ->assertOk()
            ->assertSee('Unggah foto');

        $this->actingAs($admin)
            ->post("/admin/courts/{$court->id}/image", [
                'image' => UploadedFile::fake()->image('court.png'),
            ])
            ->assertRedirect();

        $imagePath = Court::query()->whereKey($court->id)->value('image_path');
        Storage::disk('public')->assertExists($imagePath);
    }

    public function test_uploaded_court_images_are_served_with_long_lived_cache_headers(): void
    {
        Storage::fake('public');
        Storage::disk('public')->putFileAs(
            'courts',
            UploadedFile::fake()->image('legacy-court.jpg'),
            'legacy-court.jpg',
        );

        $this->get('/storage/courts/legacy-court.jpg')
            ->assertOk()
            ->assertHeader('Cache-Control', 'immutable, max-age=31536000, public')
            ->assertHeader('Content-Type', 'image/jpeg');
    }

    public function test_web_admin_can_create_court_with_image_in_separate_form(): void
    {
        Storage::fake('public');
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'new-court-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);

        $this->actingAs($admin)
            ->get('/admin/courts/create')
            ->assertOk()
            ->assertSee('Foto lapangan')
            ->assertSee('multipart/form-data');

        $this->actingAs($admin)
            ->post('/admin/courts', [
                'name' => 'Lapangan Baru',
                'category' => 'Futsal',
                'surface' => 'Rumput sintetis',
                'price_per_hour' => 200000,
                'description' => 'Lapangan indoor',
                'is_active' => 1,
                'image' => UploadedFile::fake()->image('lapangan-baru.png'),
            ])
            ->assertRedirect(route('admin.courts'));

        $court = Court::query()->where('name', 'Lapangan Baru')->firstOrFail();
        $this->assertSame('Rumput sintetis', $court->surface);
        $this->assertNotNull($court->image_path);
        Storage::disk('public')->assertExists($court->image_path);
    }

    public function test_web_admin_can_manage_venue_facilities_and_court_details(): void
    {
        $admin = User::create([
            'name' => 'Venue Web Admin',
            'email' => 'venue-web-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $court = Court::create([
            'name' => 'Lapangan Web',
            'surface' => 'Rumput sintetis',
            'description' => 'Deskripsi lama.',
            'price_per_hour' => 200000,
        ]);

        $this->actingAs($admin)
            ->get('/admin/settings')
            ->assertOk()
            ->assertSee('Fasilitas venue')
            ->assertSee('Deskripsi lapangan');

        $this->post('/admin/settings/facilities', ['facility' => 'Kamar mandi'])
            ->assertRedirect();
        $this->assertContains('Kamar mandi', VenueSetting::current()->fresh()->facilities);

        $this->patch('/admin/settings/facilities/0', ['facility' => 'Kantin'])
            ->assertRedirect();
        $this->assertSame(['Kantin'], VenueSetting::current()->fresh()->facilities);

        $this->patch("/admin/settings/courts/{$court->id}/details", [
            'surface' => 'Vinyl',
            'description' => 'Lapangan indoor dengan tribun.',
        ])->assertRedirect();
        $this->assertSame('Vinyl', $court->fresh()->surface);
        $this->assertSame('Lapangan indoor dengan tribun.', $court->fresh()->description);

        $this->delete('/admin/settings/facilities/0')->assertRedirect();
        $this->assertSame([], VenueSetting::current()->fresh()->facilities);
    }

    public function test_admin_can_view_financial_order_details_and_customer_reviews(): void
    {
        $admin = User::create([
            'name' => 'Finance Admin',
            'email' => 'finance-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $customer = User::create([
            'name' => 'Review Customer',
            'email' => 'review-customer@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create(['name' => 'Lapangan Keuangan', 'price_per_hour' => 250000]);
        Booking::create([
            'code' => 'FGO-FINANCE-001',
            'user_id' => $customer->id,
            'customer_name' => $customer->name,
            'customer_email' => $customer->email,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2 Oktober 2026',
            'booking_time' => '18.00 - 19.00',
            'duration_hours' => 1,
            'amount' => 250000,
            'status' => 'Lunas via Midtrans',
            'payment_order_id' => 'ORDER-FINANCE-001',
        ]);
        CourtReview::create([
            'court_id' => $court->id,
            'user_id' => $customer->id,
            'rating' => 5,
            'comment' => 'Lapangan bersih dan nyaman.',
        ]);

        $this->actingAs($admin)
            ->get('/admin/finance')
            ->assertOk()
            ->assertSee('Keuangan & pesanan', false)
            ->assertSee('Rp 250.000')
            ->assertSee('FGO-FINANCE-001')
            ->assertSee('ORDER-FINANCE-001')
            ->assertSee('Review Customer');

        $this->get('/admin/reviews')
            ->assertOk()
            ->assertSee('Rating & ulasan', false)
            ->assertSee('Lapangan Keuangan')
            ->assertSee('Lapangan bersih dan nyaman.')
            ->assertSee('5 / 5');
    }

    public function test_web_admin_can_manage_home_promos(): void
    {
        Storage::fake('public');
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'web-promo-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        $this->actingAs($admin)
            ->get('/admin/promos')
            ->assertOk()
            ->assertSee('Tambah banner')
            ->assertSee('Waktunya masuk lapangan')
            ->assertSee('Edit')
            ->assertSee('Hapus')
            ->assertDontSee('Tulisan kecil');

        $this->actingAs($admin)
            ->get('/admin/promos/create')
            ->assertOk()
            ->assertSee('name="image"', false);

        $this->actingAs($admin)
            ->post('/admin/promos', [
                'eyebrow' => 'PROMO WEB',
                'title' => 'Main bareng teman',
                'subtitle' => 'Pesan sesi hari ini.',
                'button_label' => 'Lihat jadwal',
                'image' => UploadedFile::fake()->image('promo-create.png'),
            ])
            ->assertRedirect(route('admin.promos'));
        $promo = PromoBanner::query()
            ->where('title', 'Main bareng teman')
            ->firstOrFail();
        $oldImagePath = $promo->image_path;
        Storage::disk('public')->assertExists($oldImagePath);

        $this->actingAs($admin)
            ->get("/admin/promos/{$promo->id}/edit")
            ->assertOk()
            ->assertSee('Edit banner')
            ->assertSee('name="image"', false);

        $this->actingAs($admin)
            ->put("/admin/promos/{$promo->id}", [
                'eyebrow' => 'PROMO SPESIAL',
                'title' => 'Main lebih seru',
                'subtitle' => 'Lapangan siap.',
                'button_label' => 'Pesan sekarang',
                'image' => UploadedFile::fake()->image('promo-edit.png'),
            ])
            ->assertRedirect(route('admin.promos'));
        Storage::disk('public')->assertMissing($oldImagePath);

        $this->actingAs($admin)
            ->post("/admin/promos/{$promo->id}/image", [
                'image' => UploadedFile::fake()->image('promo.png'),
            ])
            ->assertRedirect();
        $imagePath = $promo->fresh()->image_path;
        Storage::disk('public')->assertExists($imagePath);

        $this->actingAs($admin)
            ->delete("/admin/promos/{$promo->id}")
            ->assertRedirect();
        Storage::disk('public')->assertMissing($imagePath);
    }

    public function test_mobile_can_read_venue_settings(): void
    {
        Court::create(['name' => 'Lapangan Premium', 'price_per_hour' => 250000]);

        $this->getJson('/api/v1/settings')
            ->assertOk()
            ->assertJsonPath('data.venueName', 'Arena Hijau Futsal')
            ->assertJsonPath('data.hourlyPrice', 180000)
            ->assertJsonPath('data.courtPrices.Lapangan Premium', 250000);
    }

    public function test_admin_dashboard_reports_hourly_occupied_and_available_courts(): void
    {
        $now = Carbon::parse('2026-09-30 18:30:00', 'Asia/Jakarta');
        Carbon::setTestNow($now);

        try {
            VenueSetting::current()->update([
                'open_time' => '17:00:00',
                'close_time' => '21:00:00',
            ]);
            $admin = User::create([
                'name' => 'Admin',
                'email' => 'occupancy-admin@example.com',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]);
            $court = Court::create(['name' => 'Lapangan 1', 'is_active' => true]);
            $availableCourt = Court::create(['name' => 'Lapangan 2', 'is_active' => true]);
            Court::create(['name' => 'Lapangan Nonaktif', 'is_active' => false]);
            Booking::create([
                'code' => 'FGO-OCCUPANCY-001',
                'customer_name' => 'Raka',
                'court_id' => $court->id,
                'field_name' => $court->name,
                'booking_date' => 'Rabu, 30 September 2026',
                'booking_time' => '18.00 - 20.00',
                'duration_hours' => 2,
                'amount' => 360000,
                'status' => 'Menunggu pembayaran',
            ]);
            Booking::create([
                'code' => 'FGO-OCCUPANCY-002',
                'customer_name' => 'Dina',
                'court_id' => $availableCourt->id,
                'field_name' => $availableCourt->name,
                'booking_date' => '2026-09-30',
                'booking_time' => '18.00 - 19.00',
                'duration_hours' => 1,
                'amount' => 180000,
                'status' => 'Dibatalkan',
            ]);

            $this->actingAs($admin)
                ->getJson('/admin/dashboard/occupancy')
                ->assertOk()
                ->assertJsonPath('data.courtCount', 2)
                ->assertJsonPath('data.current.label', '18.00 - 19.00')
                ->assertJsonPath('data.current.occupied', 1)
                ->assertJsonPath('data.current.available', 1)
                ->assertJsonPath('data.current.occupiedCourts.0', 'Lapangan 1')
                ->assertJsonPath('data.current.availableCourts.0', 'Lapangan 2')
                ->assertJsonPath('data.hours.2.occupied', 1)
                ->assertJsonPath('data.hours.3.status', 'Kosong');
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_admin_dashboard_reports_zero_current_counts_before_opening(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-09-30 05:30:00', 'Asia/Jakarta'));

        try {
            VenueSetting::current()->update([
                'open_time' => '06:00:00',
                'close_time' => '21:00:00',
            ]);
            $admin = User::create([
                'name' => 'Admin Early',
                'email' => 'admin-early-occupancy@example.com',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]);
            Court::create(['name' => 'Lapangan Pagi', 'is_active' => true]);

            $this->actingAs($admin)
                ->getJson('/admin/dashboard/occupancy')
                ->assertOk()
                ->assertJsonPath('data.current.label', 'Di luar jam operasional')
                ->assertJsonPath('data.current.occupied', 0)
                ->assertJsonPath('data.current.available', 0);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_mobile_booking_cannot_mark_its_own_payment_as_paid(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'raka@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        Court::create([
            'name' => 'Lapangan 1',
            'category' => 'Futsal',
            'price_per_hour' => 250000,
            'is_active' => true,
        ]);
        Sanctum::actingAs($user);
        $payload = [
            'customerName' => 'Raka',
            'customerEmail' => 'raka@example.com',
            'fieldName' => 'Arena Hijau - Lapangan 1',
            'courtName' => 'Lapangan 1',
            'date' => 'Senin, 12 Agustus',
            'time' => '18.00 - 19.00',
            'durationHours' => 1,
            'amount' => 1,
            'status' => 'Lunas via Midtrans',
            'paymentOrderId' => 'FGO-TEST-001',
        ];

        $this->postJson('/api/v1/bookings', $payload)
            ->assertCreated()->assertJsonPath('data.status', 'Menunggu pembayaran');

        Booking::query()->where('payment_order_id', 'FGO-TEST-001')
            ->update(['status' => 'Lunas via Midtrans']);
        $this->postJson('/api/v1/bookings', $payload)
            ->assertOk()->assertJsonPath('data.status', 'Lunas via Midtrans');

        $this->assertDatabaseHas('bookings', [
            'payment_order_id' => 'FGO-TEST-001',
            'status' => 'Lunas via Midtrans',
            'amount' => 250000,
            'duration_hours' => 1,
        ]);
        $this->assertDatabaseHas('users', [
            'email' => 'raka@example.com',
            'name' => 'Raka',
            'role' => 'customer',
        ]);
    }

    public function test_multi_hour_booking_charges_hourly_rate_and_rejects_overlaps(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'raka@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create([
            'name' => 'Lapangan 1',
            'price_per_hour' => 250000,
            'is_active' => true,
        ]);
        Sanctum::actingAs($user);
        $payload = [
            'fieldName' => 'Lapangan 1',
            'courtName' => $court->name,
            'date' => '2026-09-27',
            'time' => '18.00 - 20.00',
            'durationHours' => 2,
            'amount' => 1,
            'paymentOrderId' => 'FGO-MULTI-001',
        ];

        $this->postJson('/api/v1/bookings', $payload)
            ->assertCreated()
            ->assertJsonPath('data.amount', 500000)
            ->assertJsonPath('data.durationHours', 2);
        $this->assertDatabaseHas('bookings', [
            'payment_order_id' => 'FGO-MULTI-001',
            'duration_hours' => 2,
            'amount' => 500000,
        ]);

        $payload['time'] = '19.00 - 20.00';
        $payload['durationHours'] = 1;
        $payload['paymentOrderId'] = 'FGO-MULTI-002';
        $this->postJson('/api/v1/bookings', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('time');
    }

    public function test_qris_uses_the_server_booking_amount_and_only_the_booking_owner_can_create_it(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'raka@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create([
            'name' => 'Lapangan 1',
            'price_per_hour' => 250000,
            'is_active' => true,
        ]);
        $booking = Booking::create([
            'code' => 'FGO-QRIS-001',
            'user_id' => $user->id,
            'customer_name' => $user->name,
            'customer_email' => $user->email,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'field_location' => 'Arena',
            'booking_date' => '2026-09-27',
            'booking_time' => '18.00 - 20.00',
            'duration_hours' => 2,
            'amount' => 500000,
            'status' => 'Menunggu pembayaran',
            'payment_order_id' => 'FGO-QRIS-ORDER-001',
        ]);
        config([
            'services.midtrans.server_key' => 'test-server-key',
            'services.midtrans.core_api_base_url' => 'https://api.midtrans.com/v2',
        ]);
        Http::fake([
            'https://api.midtrans.com/v2/charge' => Http::response([
                'order_id' => $booking->payment_order_id,
                'transaction_status' => 'pending',
                'qr_string' => '00020101021226580014ID.CO.QRIS.WWW',
                'expiry_time' => '2026-09-27 19:00:00',
            ], 201),
        ]);

        Sanctum::actingAs($user);
        $this->postJson("/api/v1/bookings/{$booking->id}/qris")
            ->assertOk()
            ->assertJsonPath('data.orderId', $booking->payment_order_id)
            ->assertJsonPath('data.amount', 500000)
            ->assertJsonPath('data.qrString', '00020101021226580014ID.CO.QRIS.WWW');

        Http::assertSent(fn ($request) => str_ends_with($request->url(), '/charge')
            && $request['payment_type'] === 'qris'
            && $request['transaction_details']['gross_amount'] === 500000);

        Http::fake([
            'https://api.midtrans.com/v2/FGO-QRIS-ORDER-001/status' => Http::response([
                'order_id' => $booking->payment_order_id,
                'gross_amount' => '500000.00',
                'transaction_status' => 'settlement',
                'fraud_status' => 'accept',
            ]),
        ]);
        $this->getJson("/api/v1/bookings/{$booking->id}/payment-status")
            ->assertOk()
            ->assertJsonPath('data.status', 'Lunas via Midtrans');
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'status' => 'Lunas via Midtrans',
        ]);

        $otherUser = User::create([
            'name' => 'Dina',
            'email' => 'dina@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        Sanctum::actingAs($otherUser);
        $this->postJson("/api/v1/bookings/{$booking->id}/qris")->assertForbidden();
    }

    public function test_qris_is_rejected_when_another_active_booking_overlaps_the_slot(): void
    {
        $owner = User::create([
            'name' => 'Raka',
            'email' => 'conflict-owner@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 180000]);
        $pending = Booking::create([
            'code' => 'FGO-CONFLICT-PENDING',
            'user_id' => $owner->id,
            'customer_name' => $owner->name,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2026-09-30',
            'booking_time' => '18.00 - 20.00',
            'duration_hours' => 2,
            'amount' => 360000,
            'status' => 'Menunggu pembayaran',
            'payment_order_id' => 'FGO-CONFLICT-PENDING-001',
            'payment_qr_string' => 'OLD-PENDING-QR',
            'payment_qr_expires_at' => now()->addHour(),
        ]);
        Booking::create([
            'code' => 'FGO-CONFLICT-OTHER',
            'customer_name' => 'Dina',
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2026-09-30',
            'booking_time' => '19.00 - 20.00',
            'duration_hours' => 1,
            'amount' => 180000,
            'status' => 'Dikonfirmasi',
        ]);
        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/bookings/{$pending->id}/qris")
            ->assertConflict()
            ->assertJsonPath('message', 'Lapangan pada tanggal dan jam tersebut sudah dipesan.');
    }

    public function test_resuming_pending_booking_reuses_unexpired_qris_payload(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'resume-qris@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 180000]);
        $booking = Booking::create([
            'code' => 'FGO-QRIS-RESUME',
            'user_id' => $user->id,
            'customer_name' => $user->name,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2026-09-30',
            'booking_time' => '18.00 - 19.00',
            'duration_hours' => 1,
            'amount' => 180000,
            'status' => 'Menunggu pembayaran',
            'payment_order_id' => 'FGO-QRIS-RESUME-001',
        ]);
        config([
            'services.midtrans.server_key' => 'test-server-key',
            'services.midtrans.core_api_base_url' => 'https://api.midtrans.com/v2',
        ]);
        Http::fake([
            'https://api.midtrans.com/v2/charge' => Http::response([
                'qr_string' => 'QRIS-RESUME-PAYLOAD',
                'expiry_time' => now()->addHour()->format('Y-m-d H:i:s'),
            ], 201),
        ]);
        Sanctum::actingAs($user);

        $firstResponse = $this->postJson("/api/v1/bookings/{$booking->id}/qris")
            ->assertOk()
            ->assertJsonPath('data.qrString', 'QRIS-RESUME-PAYLOAD');
        $this->postJson("/api/v1/bookings/{$booking->id}/qris")
            ->assertOk()
            ->assertJsonPath('data.qrString', 'QRIS-RESUME-PAYLOAD');

        Http::assertSentCount(1);
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'payment_qr_string' => $firstResponse->json('data.qrString'),
        ]);
    }

    public function test_legacy_pending_payment_replaces_midtrans_transaction_without_qr_data(): void
    {
        $user = User::create([
            'name' => 'Dina',
            'email' => 'legacy-qris@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 180000]);
        $booking = Booking::create([
            'code' => 'FGO-QRIS-LEGACY',
            'user_id' => $user->id,
            'customer_name' => $user->name,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2026-09-30',
            'booking_time' => '18.00 - 19.00',
            'duration_hours' => 1,
            'amount' => 180000,
            'status' => 'Menunggu pembayaran',
            'payment_order_id' => 'FGO-QRIS-OLD-001',
        ]);
        config([
            'services.midtrans.server_key' => 'test-server-key',
            'services.midtrans.core_api_base_url' => 'https://api.midtrans.com/v2',
        ]);
        Http::fake([
            '*' => Http::sequence()
                ->push(['status_message' => 'Order ID already exists'], 406)
                ->push([
                    'order_id' => 'FGO-QRIS-OLD-001',
                    'transaction_status' => 'pending',
                ])
                ->push(['transaction_status' => 'cancel'])
                ->push([
                    'qr_string' => 'QRIS-REPLACEMENT-PAYLOAD',
                    'expiry_time' => now()->addHour()->format('Y-m-d H:i:s'),
                ], 201),
        ]);
        Sanctum::actingAs($user);

        $response = $this->postJson("/api/v1/bookings/{$booking->id}/qris")
            ->assertOk()
            ->assertJsonPath('data.qrString', 'QRIS-REPLACEMENT-PAYLOAD');

        $this->assertNotSame('FGO-QRIS-OLD-001', $response->json('data.orderId'));
        $this->assertDatabaseHas('bookings', [
            'id' => $booking->id,
            'payment_order_id' => $response->json('data.orderId'),
            'payment_qr_string' => 'QRIS-REPLACEMENT-PAYLOAD',
        ]);
        Http::assertSentCount(4);
    }

    public function test_availability_hides_booked_and_blocked_periods_for_matching_court_and_date(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'raka@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        $court = Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 180000]);
        $otherCourt = Court::create(['name' => 'Lapangan 2', 'price_per_hour' => 220000]);
        Booking::create([
            'code' => 'FGO-AVAIL-001',
            'user_id' => $user->id,
            'customer_name' => $user->name,
            'court_id' => $court->id,
            'field_name' => $court->name,
            'booking_date' => '2026-09-27',
            'booking_time' => '18.00 - 20.00',
            'duration_hours' => 2,
            'amount' => 360000,
        ]);
        BlockedSlot::create(['slot' => '21:00']);

        $this->getJson('/api/v1/availability?courtName=Lapangan%201&date=2026-09-27&durationHours=2')
            ->assertUnauthorized();
        Sanctum::actingAs($user);

        $sameCourt = $this->getJson('/api/v1/availability?courtName=Lapangan%201&date=2026-09-27&durationHours=2')
            ->assertOk()->json('data');
        $this->assertNotContains('17.00', $sameCourt);
        $this->assertNotContains('18.00', $sameCourt);
        $this->assertNotContains('19.00', $sameCourt);
        $this->assertNotContains('20.00', $sameCourt);

        $otherDate = $this->getJson('/api/v1/availability?courtName=Lapangan%201&date=2026-09-28&durationHours=2')
            ->assertOk()->json('data');
        $this->assertContains('18.00', $otherDate);

        $otherCourtTimes = $this->getJson('/api/v1/availability?courtName=Lapangan%202&date=2026-09-27&durationHours=2')
            ->assertOk()->json('data');
        $this->assertContains('18.00', $otherCourtTimes);
    }

    public function test_availability_runs_from_six_until_midnight(): void
    {
        $user = User::create([
            'name' => 'Raka',
            'email' => 'midnight@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);
        Court::create(['name' => 'Lapangan 1', 'price_per_hour' => 180000]);
        Sanctum::actingAs($user);

        $oneHour = $this->getJson('/api/v1/availability?courtName=Lapangan%201&date=2026-09-30&durationHours=1')
            ->assertOk()->json('data');
        $this->assertCount(18, $oneHour);
        $this->assertSame('06.00', $oneHour[0]);
        $this->assertSame('23.00', $oneHour[17]);

        $twoHours = $this->getJson('/api/v1/availability?courtName=Lapangan%201&date=2026-09-30&durationHours=2')
            ->assertOk()->json('data');
        $this->assertContains('22.00', $twoHours);
        $this->assertNotContains('23.00', $twoHours);

        $this->postJson('/api/v1/bookings', [
            'fieldName' => 'Lapangan 1',
            'fieldLocation' => 'Jl. Merdeka No. 12',
            'courtName' => 'Lapangan 1',
            'date' => '2026-09-30',
            'time' => '23.00 - 00.00',
            'durationHours' => 1,
            'paymentOrderId' => 'MIDNIGHT-BOOKING-001',
        ])->assertCreated();
    }

    public function test_admin_can_set_midnight_as_the_venue_closing_time(): void
    {
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'midnight-admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/settings', [
            'name' => 'Arena Hijau Futsal',
            'address' => 'Jl. Merdeka No. 12',
            'phone' => '0812-0000-0000',
            'hourly_price' => 180000,
            'open_time' => '06:00',
            'close_time' => '00:00',
        ])->assertOk()->assertJsonPath('data.openTime', '06.00')
            ->assertJsonPath('data.closeTime', '24.00');
    }

    public function test_resending_verification_sends_a_new_signed_link(): void
    {
        Mail::fake();
        $this->postJson('/api/v1/auth/register', [
            'name' => 'Dina',
            'email' => 'dina@example.com',
            'password' => 'password123',
        ])->assertAccepted();

        $this->postJson('/api/v1/auth/verification-link/resend', [
            'email' => 'dina@example.com',
        ])->assertAccepted();

        Mail::assertSent(EmailVerificationCodeMail::class, 2);
        $links = [];
        Mail::assertSent(EmailVerificationCodeMail::class, function (EmailVerificationCodeMail $mail) use (&$links) {
            $links[] = $mail->verificationUrl;

            return true;
        });
        $this->assertCount(2, $links);
        $this->assertStringContainsString('signature=', $links[1]);

        $this->get($links[1])->assertOk()->assertSee('Email berhasil diverifikasi');
        $this->assertNotNull(User::query()->where('email', 'dina@example.com')->firstOrFail()->fresh()->email_verified_at);
    }

    public function test_otp_pending_status_and_resend_rate_limit_are_reported(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Nina',
            'email' => 'nina@example.com',
            'password' => 'password123',
        ])->assertAccepted()
            ->assertJsonPath('status', 'otp_pending')
            ->assertJsonPath('data.email', 'nina@example.com');

        $this->postJson('/api/v1/auth/otp/resend', [
            'email' => 'nina@example.com',
        ])->assertStatus(429)
            ->assertJsonPath('status', 'rate_limited')
            ->assertJsonPath('data.resendAvailableIn', 60);
    }

    public function test_registration_uses_otp_code_and_verifies_account(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Nina',
            'email' => 'nina@example.com',
            'password' => 'password123',
        ])->assertAccepted()->assertJsonPath('data.email', 'nina@example.com');

        $code = null;
        Mail::assertSent(EmailVerificationCodeMail::class, function (EmailVerificationCodeMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->assertNotNull($code);
        $this->assertMatchesRegularExpression('/^\d{6}$/', (string) $code);

        $this->postJson('/api/v1/auth/verify-email', [
            'email' => 'nina@example.com',
            'code' => $code,
        ])->assertOk();

        $this->assertNotNull(User::query()->where('email', 'nina@example.com')->firstOrFail()->fresh()->email_verified_at);
    }

    public function test_mobile_registration_and_login_issue_a_database_user_token(): void
    {
        Mail::fake();
        $registration = $this->postJson('/api/v1/auth/register', [
            'name' => 'Raka',
            'email' => 'raka@example.com',
            'password' => 'password123',
            'role' => 'admin',
        ])->assertAccepted()->assertJsonPath('data.email', 'raka@example.com');
        $this->assertDatabaseHas('users', [
            'email' => 'raka@example.com',
            'role' => 'customer',
            'email_verified_at' => null,
        ]);
        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->postJson('/api/v1/auth/login', [
            'email' => 'raka@example.com',
            'password' => 'password123',
        ])->assertUnprocessable()->assertJsonValidationErrors('email');

        $verificationUrl = null;
        Mail::assertSent(EmailVerificationCodeMail::class, function (EmailVerificationCodeMail $mail) use (&$verificationUrl) {
            $verificationUrl = $mail->verificationUrl;

            return true;
        });
        $this->get($verificationUrl)->assertOk()->assertSee('Email berhasil diverifikasi');
        $this->assertNotNull(User::query()->where('email', 'raka@example.com')->firstOrFail()->fresh()->email_verified_at);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'raka@example.com',
            'password' => 'password123',
        ])->assertOk()->assertJsonPath('data.user.role', 'customer');
        $token = $login->json('data.token');

        $this->withToken($token)->getJson('/api/v1/auth/me')
            ->assertOk()->assertJsonPath('data.name', 'Raka');
        $this->withToken($token)->patchJson('/api/v1/auth/profile', ['name' => 'Raka Baru'])
            ->assertOk()->assertJsonPath('data.name', 'Raka Baru');
        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
        Auth::forgetGuards();
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertUnauthorized();

        $this->postJson('/api/v1/auth/login', [
            'email' => 'raka@example.com',
            'password' => 'password123',
        ])->assertOk()->assertJsonPath('data.user.name', 'Raka Baru');

        $this->assertDatabaseHas('users', ['email' => 'raka@example.com', 'role' => 'customer']);
        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->assertDatabaseHas('users', ['email' => 'raka@example.com', 'name' => 'Raka Baru']);
    }

    public function test_customer_only_reads_own_bookings(): void
    {
        $owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com', 'password' => Hash::make('password123'), 'role' => 'customer',
        ]);
        $other = User::create([
            'name' => 'Other', 'email' => 'other@example.com', 'password' => Hash::make('password123'), 'role' => 'customer',
        ]);
        Booking::create([
            'code' => 'FGO-OWNER', 'user_id' => $owner->id, 'customer_name' => 'Owner', 'field_name' => 'Lapangan 1',
            'booking_date' => 'Senin, 12 Agustus', 'booking_time' => '18.00 - 19.00', 'amount' => 180000,
        ]);
        Booking::create([
            'code' => 'FGO-OTHER', 'user_id' => $other->id, 'customer_name' => 'Other', 'field_name' => 'Lapangan 1',
            'booking_date' => 'Selasa, 13 Agustus', 'booking_time' => '18.00 - 19.00', 'amount' => 180000,
        ]);

        Sanctum::actingAs($owner);

        $this->getJson('/api/v1/bookings')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.code', 'FGO-OWNER');
    }

    public function test_only_admin_can_update_venue_settings_and_courts(): void
    {
        $customer = User::create([
            'name' => 'Customer', 'email' => 'customer@example.com', 'password' => Hash::make('password123'), 'role' => 'customer',
        ]);
        Sanctum::actingAs($customer);

        $this->putJson('/api/v1/settings', [
            'name' => 'Changed Venue',
            'address' => 'Jalan Baru',
            'phone' => '081200000000',
            'hourly_price' => 200000,
            'open_time' => '08:00',
            'close_time' => '22:00',
        ])->assertForbidden();
        $this->postJson('/api/v1/courts', ['name' => 'Lapangan 2'])->assertForbidden();

        $admin = User::create([
            'name' => 'Admin', 'email' => 'admin@example.com', 'password' => Hash::make('password123'), 'role' => 'admin',
        ]);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/settings', [
            'name' => 'Changed Venue',
            'address' => 'Jalan Baru',
            'phone' => '081200000000',
            'hourly_price' => 200000,
            'open_time' => '08:00',
            'close_time' => '22:00',
        ])->assertOk()->assertJsonPath('data.venueName', 'Changed Venue');
        $this->postJson('/api/v1/courts', ['name' => 'Lapangan 2'])
            ->assertCreated()->assertJsonPath('data.name', 'Lapangan 2');
        $this->patchJson('/api/v1/courts/Lapangan%202', ['price_per_hour' => 225000])
            ->assertOk()->assertJsonPath('data.hourlyPrice', 225000);
        $this->postJson('/api/v1/slots', ['slot' => '18:00'])->assertCreated();

        $this->assertDatabaseHas('venue_settings', ['name' => 'Changed Venue']);
        $this->assertDatabaseHas('courts', ['name' => 'Lapangan 2', 'is_active' => true]);
        $this->assertDatabaseHas('courts', ['name' => 'Lapangan 2', 'price_per_hour' => 225000]);
        $this->assertDatabaseHas('blocked_slots', ['slot' => '18:00']);
    }

    public function test_valid_midtrans_signature_confirms_payment(): void
    {
        config(['services.midtrans.server_key' => 'test-server-key']);
        $booking = Booking::create([
            'code' => 'FGO-TEST-002',
            'customer_name' => 'Raka',
            'field_name' => 'Lapangan 1',
            'booking_date' => 'Senin, 12 Agustus',
            'booking_time' => '18.00 - 19.00',
            'amount' => 180000,
            'status' => 'Menunggu pembayaran',
            'payment_order_id' => 'FGO-TEST-002',
        ]);
        $payload = [
            'order_id' => 'FGO-TEST-002',
            'status_code' => '200',
            'gross_amount' => '180000.00',
            'transaction_status' => 'settlement',
            'signature_key' => hash('sha512', 'FGO-TEST-002200180000.00test-server-key'),
        ];

        $this->postJson('/api/v1/payments/midtrans/notification', $payload)->assertOk();

        $this->assertSame('Lunas via Midtrans', $booking->fresh()->status);
    }

    public function test_invalid_midtrans_signature_is_rejected(): void
    {
        config(['services.midtrans.server_key' => 'test-server-key']);

        $this->postJson('/api/v1/payments/midtrans/notification', [
            'order_id' => 'FGO-UNKNOWN',
            'status_code' => '200',
            'gross_amount' => '180000.00',
            'transaction_status' => 'settlement',
            'signature_key' => 'invalid-signature',
        ])->assertForbidden();
    }

    public function test_admin_pages_require_an_admin_account(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');

        User::create([
            'name' => 'Admin Test',
            'email' => 'admin@example.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);

        $this->post('/admin/login', [
            'email' => 'admin@example.com',
            'password' => 'password123',
        ])->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticated();
        $this->get('/admin')->assertOk()->assertSee('Selamat datang');
    }
}
