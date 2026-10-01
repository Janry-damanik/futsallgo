<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('promo_banners', function (Blueprint $table) {
            $table->id();
            $table->string('eyebrow', 80);
            $table->string('title', 120);
            $table->string('subtitle', 180)->default('');
            $table->string('button_label', 40)->default('Pesan lapangan');
            $table->string('image_path')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::table('promo_banners')->insert([
            [
                'eyebrow' => 'FUTSALGO / LAPANGAN',
                'title' => 'Waktunya masuk lapangan',
                'subtitle' => 'Pilih sesi berikutnya bersama timmu.',
                'button_label' => 'Pesan lapangan',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'eyebrow' => 'FUTSALGO / LAPANGAN',
                'title' => 'Satu tim, satu tujuan',
                'subtitle' => 'Siapkan jadwal mainmu hari ini.',
                'button_label' => 'Pesan lapangan',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('promo_banners');
    }
};