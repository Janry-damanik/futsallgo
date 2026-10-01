<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('venue_settings')
            ->where('id', 1)
            ->where('open_time', '08:00:00')
            ->where('close_time', '22:00:00')
            ->update(['open_time' => '06:00:00', 'close_time' => '00:00:00']);
    }

    public function down(): void
    {
        DB::table('venue_settings')
            ->where('id', 1)
            ->where('open_time', '06:00:00')
            ->where('close_time', '00:00:00')
            ->update(['open_time' => '08:00:00', 'close_time' => '22:00:00']);
    }
};