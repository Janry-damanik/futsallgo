<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Court;
use App\Models\User;
use App\Models\VenueSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        $today = now()->toDateString();

        return view('admin.dashboard', [
            'settings' => VenueSetting::current(),
            'bookingCount' => Booking::count(),
            'todayCount' => Booking::whereDate('created_at', $today)->count(),
            'pendingCount' => Booking::where('status', 'Menunggu pembayaran')->count(),
            'revenue' => Booking::whereIn('status', ['Dikonfirmasi', 'Selesai', 'Lunas via Midtrans'])->sum('amount'),
            'courtCount' => Court::where('is_active', true)->count(),
            'customerCount' => User::where('role', 'customer')->count(),
            'recentBookings' => Booking::latest()->limit(6)->get(),
            'occupancy' => $this->buildOccupancy(),
        ]);
    }

    public function occupancy(): JsonResponse
    {
        return response()->json(['data' => $this->buildOccupancy()]);
    }

    private function buildOccupancy(): array
    {
        $now = now('Asia/Jakarta');
        $settings = VenueSetting::current();
        $courts = Court::query()->where('is_active', true)->orderBy('id')->get(['id', 'name']);
        $courtNames = $courts->pluck('name')->all();
        $courtNamesById = $courts->keyBy('id');
        $courtNamesByName = $courts->keyBy('name');
        $bookings = Booking::query()
            ->whereIn('booking_date', $this->todayBookingDateKeys($now))
            ->where('status', '!=', 'Dibatalkan')
            ->get(['court_id', 'field_name', 'booking_time', 'duration_hours'])
            ->map(function (Booking $booking) use ($courtNamesById, $courtNamesByName) {
                $court = $booking->court_id !== null
                    ? $courtNamesById->get($booking->court_id)
                    : $courtNamesByName->get($booking->field_name);
                $timeRange = explode(' - ', $booking->booking_time);
                $start = $this->timeToMinutes($timeRange[0] ?? '');

                if ($court === null || $start === null) {
                    return null;
                }

                return [
                    'court' => $court->name,
                    'start' => $start,
                    'end' => $start + max(1, (int) $booking->duration_hours) * 60,
                ];
            })
            ->filter()
            ->values();

        $opening = $this->timeToMinutes(substr($settings->open_time, 0, 5)) ?? 0;
        $closingText = substr($settings->close_time, 0, 5);
        $closing = $closingText === '00:00'
            ? 24 * 60
            : ($this->timeToMinutes($closingText) ?? 24 * 60);
        $nowMinutes = ($now->hour * 60) + $now->minute;
        $hours = [];
        $current = null;

        for ($start = $opening; $start < $closing; $start += 60) {
            $end = min($start + 60, $closing);
            $occupiedCourts = $bookings
                ->filter(fn (array $booking) => $start < $booking['end'] && $end > $booking['start'])
                ->pluck('court')
                ->unique()
                ->values()
                ->all();
            $availableCourts = array_values(array_diff($courtNames, $occupiedCourts));
            $occupiedCount = count($occupiedCourts);
            $availableCount = count($availableCourts);
            $row = [
                'label' => $this->formatClock($start).' - '.$this->formatClock($end),
                'start' => $this->formatClock($start),
                'occupied' => $occupiedCount,
                'available' => $availableCount,
                'occupiedCourts' => $occupiedCourts,
                'availableCourts' => $availableCourts,
                'status' => count($courtNames) === 0
                    ? 'Tidak ada lapangan aktif'
                    : ($occupiedCount === count($courtNames)
                        ? 'Penuh'
                        : ($occupiedCount > 0 ? 'Sebagian terisi' : 'Kosong')),
                'isCurrent' => $nowMinutes >= $start && $nowMinutes < $end,
            ];
            $hours[] = $row;

            if ($row['isCurrent']) {
                $current = $row;
            }
        }

        $current ??= [
            'label' => 'Di luar jam operasional',
            'start' => null,
            'occupied' => 0,
            'available' => 0,
            'occupiedCourts' => [],
            'availableCourts' => [],
            'status' => count($courtNames) === 0
                ? 'Tidak ada lapangan aktif'
                : 'Di luar jam operasional',
            'isCurrent' => false,
        ];

        return [
            'updatedAt' => $now->toIso8601String(),
            'courtCount' => count($courtNames),
            'current' => $current,
            'hours' => $hours,
        ];
    }

    private function todayBookingDateKeys(Carbon $date): array
    {
        $weekdays = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        $months = [
            1 => 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
        ];
        $day = $weekdays[$date->dayOfWeek].', '.$date->day.' '.$months[$date->month];

        return [
            $date->toDateString(),
            $day.' '.$date->year,
            $day,
            $date->day.' '.$months[$date->month].' '.$date->year,
        ];
    }

    private function timeToMinutes(string $time): ?int
    {
        $normalized = str_replace(':', '.', $time);
        if (! preg_match('/^(\d{1,2})\.(\d{2})$/', $normalized, $matches)) {
            return null;
        }

        $hour = (int) $matches[1];
        $minute = (int) $matches[2];
        if ($hour > 24 || $minute > 59 || ($hour === 24 && $minute !== 0)) {
            return null;
        }

        return ($hour * 60) + $minute;
    }

    private function formatClock(int $minutes): string
    {
        return sprintf('%02d.%02d', intdiv($minutes, 60), $minutes % 60);
    }
}
