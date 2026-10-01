<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmailVerificationCode extends Model
{
    protected $table = 'email_verification_codes';

    protected $fillable = [
        'user_id',
        'code_hash',
        'expires_at',
        'attempts',
        'resend_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'resend_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
