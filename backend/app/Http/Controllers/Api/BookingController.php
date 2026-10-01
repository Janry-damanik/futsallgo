<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BlockedSlot;
use App\Models\Booking;
use App\Models\Court;
use App\Models\VenueSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class BookingController extends Controller
{
    public function index(Request $request)
    {
        $bookings = Booking::query()
            ->when(! $request->user()->isAdmin(), fn ($query) => $query->where('user_id', $request->user()->id))
            ->latest()
            ->get();

        return response()->json(['data' => $bookings->map(fn (Booking $booking) => $this->bookingData($booking))]);
    }

    public function availability(Request $request)
    {
        $data = $request->validate([
            'courtName' => ['required', 'string', Rule::exists('courts', 'name')->where('is_active', true)],
            'date' => ['required', 'string', 'max:80'],
            'durationHours' => ['required', 'integer', 'between:1,4'],
        ]);
        $court = Court::query()->where('name', $data['courtName'])->firstOrFail();
        $settings = VenueSetting::current();
        $duration = (int) $data['durationHours'];
        $opening = $this->timeToMinutes(substr($settings->open_time, 0, 5));
        $closing = $this->closingTimeToMinutes(substr($settings->close_time, 0, 5));
        $available = [];

        for ($start = $opening; $start + ($duration * 60) <= $closing; $start += 60) {
            if ($this->periodIsAvailable($court, $data['date'], $start, $duration)) {
                $available[] = $this->formatClock($start);
            }
        }

        return response()->json(['data' => $available]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'fieldName' => ['required', 'string', 'max:180'],
            'fieldLocation' => ['nullable', 'string', 'max:255'],
            'courtName' => ['required', 'string', Rule::exists('courts', 'name')->where('is_active', true)],
            'date' => ['required', 'string', 'max:80'],
            'time' => ['required', 'regex:/^\d{2}\.\d{2} - \d{2}\.\d{2}$/'],
            'durationHours' => ['required', 'integer', 'between:1,4'],
            'paymentOrderId' => ['required', 'string', 'max:120'],
        ]);

        $user = $request->user();
        $duration = (int) $data['durationHours'];
        [$startTime, $endTime] = explode(' - ', $data['time']);
        $startMinute = $this->timeToMinutes($startTime);
        $endMinute = $this->timeToMinutes($endTime);
        if ($endMinute === 0 && $startMinute > 0) {
            $endMinute = 24 * 60;
        }
        if ($endMinute - $startMinute !== $duration * 60) {
            throw ValidationException::withMessages(['time' => ['Rentang waktu tidak sesuai durasi.']]);
        }

        $result = DB::transaction(function () use ($data, $user, $duration, $startMinute) {
            $court = Court::query()
                ->where('name', $data['courtName'])
                ->lockForUpdate()
                ->firstOrFail();
            abort_unless($court->is_active, 422, 'Lapangan tidak aktif.');

            $existing = Booking::query()
                ->where('payment_order_id', $data['paymentOrderId'])
                ->first();
            if ($existing) {
                abort_if($existing->user_id !== $user->id && ! $user->isAdmin(), 403);

                return ['booking' => $existing, 'created' => false];
            }

            if (! $this->periodIsAvailable($court, $data['date'], $startMinute, $duration)) {
                throw ValidationException::withMessages([
                    'time' => ['Jam tersebut sudah tidak tersedia untuk durasi yang dipilih.'],
                ]);
            }

            $settings = VenueSetting::current();
            $booking = Booking::query()->create([
                'code' => 'FGO-'.now()->format('ymd').'-'.Str::upper(Str::random(5)),
                'user_id' => $user->id,
                'customer_name' => $user->name,
                'customer_email' => $user->email,
                'court_id' => $court->id,
                'field_name' => $court->name,
                'field_location' => $data['fieldLocation'] ?? $settings->address,
                'booking_date' => $data['date'],
                'booking_time' => $data['time'],
                'duration_hours' => $duration,
                'amount' => ($court->price_per_hour ?? $settings->hourly_price) * $duration,
                'status' => 'Menunggu pembayaran',
                'payment_order_id' => $data['paymentOrderId'],
            ]);

            return ['booking' => $booking, 'created' => true];
        });

        return response()->json(
            ['data' => $this->bookingData($result['booking'])],
            $result['created'] ? 201 : 200,
        );
    }

    public function update(Request $request, Booking $booking)
    {
        $booking->update($request->validate([
            'status' => ['required', Rule::in(['Menunggu pembayaran', 'Dikonfirmasi', 'Selesai', 'Dibatalkan'])],
        ]));

        return response()->json(['data' => $this->bookingData($booking->fresh())]);
    }

    public function destroy(Booking $booking)
    {
        $booking->delete();

        return response()->json(['message' => 'Booking dihapus.']);
    }

    private function bookingData(Booking $booking): array
    {
        return [
            'id' => $booking->id,
            'code' => $booking->code,
            'fieldName' => $booking->field_name,
            'fieldLocation' => $booking->field_location ?? '-',
            'courtName' => $booking->court?->name,
            'date' => $booking->booking_date,
            'time' => $booking->booking_time,
            'durationHours' => $booking->duration_hours,
            'amount' => $booking->amount,
            'price' => $booking->amount,
            'total' => $booking->amount,
            'status' => $booking->status,
            'customerName' => $booking->customer_name,
            'customerEmail' => $booking->customer_email,
        ];
    }

    private function timeToMinutes(string $time): int
    {
        [$hour, $minute] = array_map('intval', explode('.', str_replace(':', '.', $time)));

        return ($hour * 60) + $minute;
    }

    private function closingTimeToMinutes(string $time): int
    {
        return $time === '00:00' ? 24 * 60 : $this->timeToMinutes($time);
    }

    private function minutesToDatabaseTime(int $minutes): string
    {
        return sprintf('%02d:%02d', intdiv($minutes, 60), $minutes % 60);
    }

    private function formatClock(int $minutes): string
    {
        return sprintf('%02d.%02d', intdiv($minutes, 60), $minutes % 60);
    }

    private function periodIsAvailable(Court $court, string $date, int $start, int $duration): bool
    {
        $settings = VenueSetting::current();
        $end = $start + ($duration * 60);
        $opening = $this->timeToMinutes(substr($settings->open_time, 0, 5));
        $closing = $this->closingTimeToMinutes(substr($settings->close_time, 0, 5));
        if ($start < $opening || $end > $closing) {
            return false;
        }

        $blockedTimes = collect(range(0, $duration - 1))
            ->map(fn ($offset) => $this->minutesToDatabaseTime($start + ($offset * 60)));
        if (BlockedSlot::query()->whereIn('slot', $blockedTimes)->exists()) {
            return false;
        }

        $bookings = Booking::query()
            ->where('court_id', $court->id)
            ->where('booking_date', $date)
            ->where('status', '!=', 'Dibatalkan')
            ->get(['booking_time', 'duration_hours']);

        return ! $bookings->contains(function (Booking $booking) use ($start, $end) {
            $range = explode(' - ', $booking->booking_time);
            if (count($range) !== 2) {
                return false;
            }
            $bookedStart = $this->timeToMinutes($range[0]);
            $bookedEnd = $bookedStart + ($booking->duration_hours * 60);

            return $start < $bookedEnd && $end > $bookedStart;
        });
    }
}