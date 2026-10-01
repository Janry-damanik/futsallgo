<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class MidtransQrisController extends Controller
{
    public function status(Request $request, Booking $booking)
    {
        abort_unless($booking->user_id === $request->user()->id, 403);

        $serverKey = (string) config('services.midtrans.server_key');
        abort_if($serverKey === '', 503, 'Midtrans server key belum dikonfigurasi.');

        $baseUrl = rtrim((string) config('services.midtrans.core_api_base_url'), '/');

        try {
            $statusResponse = Http::withBasicAuth($serverKey, '')
                ->acceptJson()
                ->get("{$baseUrl}/".rawurlencode($booking->payment_order_id).'/status');

            if (! $statusResponse->successful()) {
                return response()->json(['message' => 'Status pembayaran belum dapat diperiksa.'], 502);
            }

            $transaction = $statusResponse->json();
            abort_unless(($transaction['order_id'] ?? null) === $booking->payment_order_id, 502);
            abort_unless(
                number_format((float) ($transaction['gross_amount'] ?? 0), 2, '.', '')
                    === number_format((float) $booking->amount, 2, '.', ''),
                422,
                'Nilai pembayaran tidak cocok dengan booking.',
            );

            $status = match ($transaction['transaction_status'] ?? '') {
                'capture' => ($transaction['fraud_status'] ?? '') === 'accept'
                    ? 'Lunas via Midtrans'
                    : $booking->status,
                'settlement' => 'Lunas via Midtrans',
                'pending' => 'Menunggu pembayaran',
                'deny', 'cancel', 'expire', 'failure', 'refund', 'partial_refund' => 'Dibatalkan',
                default => $booking->status,
            };

            if ($status !== $booking->status) {
                $booking->update(['status' => $status]);
            }

            return response()->json([
                'data' => [
                    'status' => $status,
                    'transactionStatus' => $transaction['transaction_status'] ?? null,
                ],
            ]);
        } catch (\Throwable $error) {
            report($error);

            return response()->json(['message' => 'Status pembayaran belum dapat diperiksa.'], 502);
        }
    }

    public function store(Request $request, Booking $booking)
    {
        abort_unless($booking->user_id === $request->user()->id, 403);
        abort_unless($booking->status === 'Menunggu pembayaran', 409, 'Booking tidak menunggu pembayaran.');
        abort_unless(
            ! $this->hasBookingConflict($booking),
            409,
            'Lapangan pada tanggal dan jam tersebut sudah dipesan.',
        );

        if (($booking->payment_qr_string || $booking->payment_qr_code_base64)
            && (! $booking->payment_qr_expires_at || $booking->payment_qr_expires_at->isFuture())) {
            return response()->json(['data' => [
                'orderId' => $booking->payment_order_id,
                'amount' => $booking->amount,
                'qrString' => $booking->payment_qr_string,
                'qrCodeBase64' => $booking->payment_qr_code_base64,
                'expiresAt' => $booking->payment_qr_expires_at?->toIso8601String(),
            ]]);
        }
        $serverKey = (string) config('services.midtrans.server_key');
        abort_if($serverKey === '', 503, 'Midtrans server key belum dikonfigurasi.');

        $baseUrl = rtrim((string) config('services.midtrans.core_api_base_url'), '/');

        try {
            $charge = fn (string $orderId) => Http::withBasicAuth($serverKey, '')
                ->acceptJson()
                ->post("{$baseUrl}/charge", [
                    'payment_type' => 'qris',
                    'transaction_details' => [
                        'order_id' => $orderId,
                        'gross_amount' => $booking->amount,
                    ],
                    'item_details' => [[
                        'id' => $orderId,
                        'price' => $booking->amount,
                        'quantity' => 1,
                        'name' => "{$booking->field_name} {$booking->booking_date} {$booking->booking_time}",
                    ]],
                    'qris' => ['acquirer' => 'gopay'],
                ]);
            $chargeResponse = $charge($booking->payment_order_id);

            if (! $chargeResponse->successful()) {
                $statusResponse = Http::withBasicAuth($serverKey, '')
                    ->acceptJson()
                    ->get("{$baseUrl}/".rawurlencode($booking->payment_order_id).'/status');
                $existingTransaction = $statusResponse->json();

                if ($statusResponse->successful()
                    && ($existingTransaction['order_id'] ?? null) === $booking->payment_order_id
                    && ($existingTransaction['transaction_status'] ?? null) === 'pending') {
                    $cancelResponse = Http::withBasicAuth($serverKey, '')
                        ->acceptJson()
                        ->post("{$baseUrl}/".rawurlencode($booking->payment_order_id).'/cancel');

                    if ($cancelResponse->successful()) {
                        $newOrderId = 'FGO-'.now()->format('ymdHis').'-'.Str::upper(Str::random(8));
                        $booking->update([
                            'payment_order_id' => $newOrderId,
                            'payment_qr_string' => null,
                            'payment_qr_code_base64' => null,
                            'payment_qr_expires_at' => null,
                        ]);
                        $chargeResponse = $charge($newOrderId);
                    }
                }

                if (! $chargeResponse->successful()) {
                    return response()->json([
                        'message' => $chargeResponse->json('status_message') ?? 'Midtrans gagal membuat QRIS.',
                    ], 502);
                }
            }

            $transaction = $chargeResponse->json();
            $qrString = $transaction['qr_string'] ?? null;
            if (is_string($qrString) && $qrString !== '') {
                $expiresAt = $transaction['expiry_time'] ?? $transaction['expire_time'] ?? null;
                $booking->update([
                    'payment_qr_string' => $qrString,
                    'payment_qr_code_base64' => null,
                    'payment_qr_expires_at' => $expiresAt,
                ]);

                return response()->json([
                    'data' => [
                        'orderId' => $booking->payment_order_id,
                        'amount' => $booking->amount,
                        'qrString' => $qrString,
                        'expiresAt' => $expiresAt,
                    ],
                ]);
            }

            $actions = collect($transaction['actions'] ?? []);
            $qrAction = $actions->firstWhere('name', 'generate-qr-code-v2')
                ?? $actions->firstWhere('name', 'generate-qr-code');
            $qrUrl = $qrAction['url'] ?? null;
            if (! is_string($qrUrl) || $qrUrl === '') {
                logger()->warning('Midtrans QRIS response did not include QR data.', [
                    'http_status' => $chargeResponse->status(),
                    'status_code' => $transaction['status_code'] ?? null,
                    'status_message' => $transaction['status_message'] ?? null,
                    'response_fields' => array_keys($transaction),
                    'action_names' => $actions->pluck('name')->all(),
                    'has_transaction_id' => isset($transaction['transaction_id']),
                    'has_qr_string' => isset($transaction['qr_string']),
                ]);

                $midtransMessage = $transaction['status_message'] ?? null;

                return response()->json([
                    'message' => is_string($midtransMessage) && $midtransMessage !== ''
                        ? "Midtrans: {$midtransMessage}; data QRIS tidak tersedia."
                        : 'Midtrans tidak mengembalikan data QRIS.',
                ], 502);
            }

            $qrHost = is_string($qrUrl) ? strtolower((string) parse_url($qrUrl, PHP_URL_HOST)) : '';
            $allowedHosts = ['api.midtrans.com', 'api.sandbox.midtrans.com'];

            if (parse_url($qrUrl, PHP_URL_SCHEME) !== 'https'
                || ! in_array($qrHost, $allowedHosts, true)) {
                logger()->warning('Midtrans returned an untrusted QRIS URL.', [
                    'scheme' => is_string($qrUrl) ? parse_url($qrUrl, PHP_URL_SCHEME) : null,
                    'host' => $qrHost ?: null,
                    'response_fields' => array_keys($transaction),
                    'action_names' => $actions->pluck('name')->all(),
                ]);
                return response()->json(['message' => 'URL QRIS dari Midtrans tidak valid.'], 502);
            }

            $qrResponse = Http::withBasicAuth($serverKey, '')
                ->accept('image/png')
                ->get($qrUrl);

            if (! $qrResponse->successful()) {
                return response()->json(['message' => 'Gagal mengambil gambar QRIS dari Midtrans.'], 502);
            }

            $qrCodeBase64 = base64_encode($qrResponse->body());
            $expiresAt = $transaction['expiry_time'] ?? $transaction['expire_time'] ?? null;
            $booking->update([
                'payment_qr_string' => null,
                'payment_qr_code_base64' => $qrCodeBase64,
                'payment_qr_expires_at' => $expiresAt,
            ]);

            return response()->json([
                'data' => [
                    'orderId' => $booking->payment_order_id,
                    'amount' => $booking->amount,
                    'qrCodeBase64' => $qrCodeBase64,
                    'expiresAt' => $expiresAt,
                ],
            ]);
        } catch (\Throwable $error) {
            report($error);

            return response()->json(['message' => 'Layanan QRIS sedang tidak tersedia.'], 502);
        }
    }

    private function hasBookingConflict(Booking $booking): bool
    {
        if ($booking->court_id === null) {
            return false;
        }

        $range = explode(' - ', $booking->booking_time);
        if (count($range) !== 2) {
            return true;
        }
        $start = $this->timeToMinutes($range[0]);
        if ($start === null) {
            return true;
        }
        $end = $start + ($booking->duration_hours * 60);

        $otherBookings = Booking::query()
            ->where('court_id', $booking->court_id)
            ->where('booking_date', $booking->booking_date)
            ->where('status', '!=', 'Dibatalkan')
            ->where('id', '!=', $booking->id)
            ->get(['booking_time', 'duration_hours']);

        return $otherBookings->contains(function (Booking $other) use ($start, $end) {
            $otherRange = explode(' - ', $other->booking_time);
            $otherStart = $this->timeToMinutes($otherRange[0] ?? '');
            if ($otherStart === null) {
                return true;
            }
            $otherEnd = $otherStart + ($other->duration_hours * 60);

            return $start < $otherEnd && $end > $otherStart;
        });
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
}