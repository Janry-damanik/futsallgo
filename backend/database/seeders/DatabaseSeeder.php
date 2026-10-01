<?php

namespace Database\Seeders;

use App\Models\Court;
use App\Models\User;
use App\Models\VenueSetting;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $password = env('ADMIN_PASSWORD');
        if ($password) {
            User::updateOrCreate(
                ['email' => env('ADMIN_EMAIL', 'admin@futsalgo.com')],
                [
                    'name' => 'Administrator',
                    'role' => 'admin',
                    'password' => Hash::make($password),
                    'email_verified_at' => now(),
                ],
            );
        }

            $settings = VenueSetting::current();
            Court::firstOrCreate(
                ['name' => 'Lapangan 1'],
                [
                    'category' => 'Futsal',
                    'price_per_hour' => $settings->hourly_price,
                    'is_active' => true,
                ],
            );
            Court::query()->whereNull('price_per_hour')->update([
                'price_per_hour' => $settings->hourly_price,
            ]);
    }
}
