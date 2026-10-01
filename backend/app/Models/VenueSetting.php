<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VenueSetting extends Model
{
    protected $fillable = ['name', 'address', 'phone', 'hourly_price', 'open_time', 'close_time'];

    protected function casts(): array
    {
        return ['hourly_price' => 'integer'];
    }

    public static function current(): self
    {
        return static::query()->firstOrCreate(['id' => 1], [
            'name' => 'Arena Hijau Futsal',
            'address' => 'Jl. Merdeka No. 12',
            'phone' => '0812-0000-0000',
            'hourly_price' => 180000,
            'open_time' => '06:00:00',
            'close_time' => '00:00:00',
        ]);
    }
}