<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Court extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'category', 'surface', 'description', 'image_path', 'price_per_hour', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'price_per_hour' => 'integer'];
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function reviews()
    {
        return $this->hasMany(CourtReview::class);
    }
}
