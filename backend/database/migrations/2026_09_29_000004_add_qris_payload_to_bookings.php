<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->text('payment_qr_string')->nullable();
            $table->longText('payment_qr_code_base64')->nullable();
            $table->dateTime('payment_qr_expires_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn([
                'payment_qr_string',
                'payment_qr_code_base64',
                'payment_qr_expires_at',
            ]);
        });
    }
};