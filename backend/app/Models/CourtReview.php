<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CourtReview extends Model
{
    protected $fillable = ['court_id', 'user_id', 'rating', 'comment'];

    protected function casts(): array
    {
        return ['rating' => 'integer'];
    }

    public function court()
    {
        return $this->belongsTo(Court::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
