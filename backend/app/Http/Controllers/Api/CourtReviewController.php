<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Court;
use App\Models\CourtReview;
use Illuminate\Http\Request;

class CourtReviewController extends Controller
{
    public function index(string $court)
    {
        $model = Court::query()->where('name', $court)->where('is_active', true)->firstOrFail();
        $reviews = $model->reviews()->with('user:id,name')->latest()->get();

        return response()->json(['data' => [
            'averageRating' => (float) ($model->reviews()->avg('rating') ?? 0),
            'reviewCount' => $reviews->count(),
            'reviews' => $reviews->map(fn (CourtReview $review) => [
                'id' => $review->id,
                'customerName' => $review->user?->name ?? 'Pelanggan',
                'rating' => $review->rating,
                'comment' => $review->comment,
                'createdAt' => $review->created_at?->toIso8601String(),
            ]),
        ]]);
    }

    public function store(Request $request, string $court)
    {
        abort_unless($request->user()->role === 'customer', 403);
        $model = Court::query()->where('name', $court)->where('is_active', true)->firstOrFail();
        $data = $request->validate([
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['required', 'string', 'min:2', 'max:1000'],
        ]);

        $model->reviews()->updateOrCreate(
            ['user_id' => $request->user()->id],
            $data,
        );

        return $this->index($court);
    }
}
