<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('venue_settings', function (Blueprint $table) {
            $table->id();
            $table->string('name')->default('Arena Hijau Futsal');
            $table->string('address')->default('Jl. Merdeka No. 12');
            $table->string('phone')->default('0812-0000-0000');
            $table->unsignedInteger('hourly_price')->default(180000);
            $table->time('open_time')->default('06:00:00');
            $table->time('close_time')->default('00:00:00');
            $table->timestamps();
        });

        Schema::create('courts', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('category')->default('Futsal');
            $table->string('surface')->nullable();
            $table->text('description')->nullable();
            $table->unsignedInteger('price_per_hour')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('blocked_slots', function (Blueprint $table) {
            $table->id();
            $table->string('slot', 8)->unique();
            $table->timestamps();
        });

        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('customer_name');
            $table->string('customer_email')->nullable();
            $table->string('customer_phone', 32)->nullable();
            $table->foreignId('court_id')->nullable()->constrained()->nullOnDelete();
            $table->string('field_name');
            $table->string('field_location')->nullable();
            $table->string('booking_date', 80);
            $table->string('booking_time', 40);
            $table->unsignedInteger('amount');
            $table->string('status')->default('Menunggu pembayaran')->index();
            $table->string('payment_order_id')->nullable()->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
        Schema::dropIfExists('blocked_slots');
        Schema::dropIfExists('courts');
        Schema::dropIfExists('venue_settings');
    }
};