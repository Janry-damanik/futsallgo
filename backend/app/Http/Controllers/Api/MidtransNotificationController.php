<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;

class MidtransNotificationController extends Controller
{
    public function __invoke(Request $request)
    {
        $data = $request->validate([
            'order_id' => ['required', 'string'],
            'status_code' => ['required', 'string'],
            'gross_amount' => ['required', 'numeric'],
            'signature_key' => ['required', 'string'],
            'transaction_status' => ['required', 'string'],
            'fraud_status' => ['nullable', 'string'],
        ]);
        $serverKey = (string) config('services.midtrans.server_key');
        abort_if($serverKey === '', 503, 'Midtrans server key belum dikonfigurasi.');

        $signature = hash('sha512', $data['order_id'].$data['status_code'].$data['gross_amount'].$serverKey);
        abort_unless(hash_equals($signature, $data['signature_key']), 403, 'Signature not valid.');

        $booking = Booking::query()->where('payment_order_id', $data['order_id'])->first();
        if (! $booking) {
            return response()->json(['message' => 'Booking belum terdaftar.'], 404);
        }

        $amount = number_format((float) $data['gross_amount'], 2, '.', '');
        abort_unless((float) $amount === (float) $booking->amount, 422, 'Nilai pembayaran tidak cocok.');

        $status = match ($data['transaction_status']) {
            'capture' => ($data['fraud_status'] ?? '') === 'accept' ? 'Lunas via Midtrans' : $booking->status,
            'settlement' => 'Lunas via Midtrans',
            'pending' => 'Menunggu pembayaran',
            'deny', 'cancel', 'expire', 'failure' => 'Dibatalkan',
            'refund', 'partial_refund' => 'Dibatalkan',
            default => $booking->status,
        };

        if ($status !== $booking->status) {
            $booking->update(['status' => $status]);
        }

        return response()->json(['message' => 'Notifikasi pembayaran diproses.']);
    }
}