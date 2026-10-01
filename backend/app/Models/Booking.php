<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $fillable = [
        'code', 'user_id', 'customer_name', 'customer_email', 'customer_phone',
        'court_id', 'field_name', 'field_location', 'booking_date', 'booking_time',
        'duration_hours', 'amount', 'status', 'payment_order_id',
        'payment_qr_string', 'payment_qr_code_base64', 'payment_qr_expires_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'duration_hours' => 'integer',
            'payment_qr_expires_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function court()
    {
        return $this->belongsTo(Court::class);
    }
}