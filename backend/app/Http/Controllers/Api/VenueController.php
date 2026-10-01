<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BlockedSlot;
use App\Models\Court;
use App\Models\VenueSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class VenueController extends Controller
{
    public function show(Request $request)
    {
        $settings = VenueSetting::current();
        $courts = Court::query()->where('is_active', true)->withAvg('reviews', 'rating')->withCount('reviews')->orderBy('id')->get();

        return response()->json(['data' => [
            'venueName' => $settings->name,
            'address' => $settings->address,
            'phone' => $settings->phone,
            'hourlyPrice' => $settings->hourly_price,
            'openTime' => str_replace(':', '.', substr($settings->open_time, 0, 5)),
            'closeTime' => substr($settings->close_time, 0, 5) === '00:00'
                ? '24.00'
                : str_replace(':', '.', substr($settings->close_time, 0, 5)),
            'courts' => $courts->pluck('name'),
            'courtPrices' => $courts->mapWithKeys(fn (Court $court) => [
                $court->name => $court->price_per_hour ?? $settings->hourly_price,
            ]),
            'courtImages' => $courts->mapWithKeys(fn (Court $court) => [
                $court->name => $court->image_path
                    ? $request->getSchemeAndHttpHost().'/storage/'.$court->image_path
                    : null,
            ]),
            'courtDescriptions' => $courts->mapWithKeys(fn (Court $court) => [
                $court->name => $court->description,
            ]),
            'courtSurfaces' => $courts->mapWithKeys(fn (Court $court) => [
                $court->name => $court->surface,
            ]),
            'courtRatings' => $courts->mapWithKeys(fn (Court $court) => [
                $court->name => [
                    'average' => (float) ($court->reviews_avg_rating ?? 0),
                    'count' => $court->reviews_count,
                ],
            ]),
            'facilities' => $settings->facilities ?? [],
            'blockedSlots' => BlockedSlot::query()->orderBy('slot')->pluck('slot')->map(fn ($slot) => str_replace(':', '.', substr($slot, 0, 5))),
        ]]);
    }

    public function courts()
    {
        $settings = VenueSetting::current();
        $courts = Court::query()->where('is_active', true)->withAvg('reviews', 'rating')->withCount('reviews')->orderBy('id')->get();

        return response()->json(['data' => $courts->map(fn (Court $court) => [
            'id' => $court->id,
            'name' => $court->name,
            'category' => $court->category,
            'surface' => $court->surface,
            'description' => $court->description,
            'imageUrl' => $court->image_path
                ? request()->getSchemeAndHttpHost().'/storage/'.$court->image_path
                : null,
            'hourlyPrice' => $court->price_per_hour ?? $settings->hourly_price,
            'averageRating' => (float) ($court->reviews_avg_rating ?? 0),
            'reviewCount' => $court->reviews_count,
        ])]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'address' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32'],
            'hourly_price' => ['required', 'integer', 'min:1'],
            'open_time' => ['required', 'date_format:H:i'],
            'close_time' => ['required', 'date_format:H:i'],
        ]);
        if ($data['close_time'] !== '00:00' && $data['close_time'] <= $data['open_time']) {
            throw ValidationException::withMessages([
                'close_time' => ['Jam tutup harus setelah jam buka.'],
            ]);
        }
        VenueSetting::current()->update($data);

        return $this->show($request);
    }

    public function storeCourt(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120', 'unique:courts,name'],
            'price_per_hour' => ['nullable', 'integer', 'min:1'],
            'surface' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:1000'],
        ]);
        $data['price_per_hour'] ??= VenueSetting::current()->hourly_price;
        $court = Court::query()->create($data + ['category' => 'Futsal', 'is_active' => true]);

        return response()->json(['data' => $court], 201);
    }

    public function updateCourt(Request $request, string $court)
    {
        $model = Court::query()->where('name', $court)->firstOrFail();
        $data = $request->validate([
            'price_per_hour' => ['sometimes', 'required', 'integer', 'min:1'],
            'surface' => ['sometimes', 'nullable', 'string', 'max:100'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ]);
        $model->update($data);

        return response()->json(['data' => [
            'name' => $model->name,
            'hourlyPrice' => $model->price_per_hour,
            'surface' => $model->surface,
            'description' => $model->description,
        ]]);
    }

    public function updateFacilities(Request $request)
    {
        $data = $request->validate([
            'facilities' => ['present', 'array', 'max:30'],
            'facilities.*' => ['required', 'string', 'max:60'],
        ]);
        $facilities = collect($data['facilities'])
            ->map(fn (string $facility) => trim($facility))
            ->filter()
            ->unique(fn (string $facility) => mb_strtolower($facility))
            ->values()
            ->all();

        VenueSetting::current()->update(['facilities' => $facilities]);

        return response()->json(['data' => ['facilities' => $facilities]]);
    }

    public function uploadCourtImage(Request $request, string $court)
    {
        $data = $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $model = Court::query()->where('name', $court)->firstOrFail();
        $path = $data['image']->storePublicly('courts', 'public');

        if ($model->image_path) {
            Storage::disk('public')->delete($model->image_path);
        }

        $model->update(['image_path' => $path]);

        return response()->json(['data' => [
            'name' => $model->name,
            'imageUrl' => $request->getSchemeAndHttpHost().'/storage/'.$path,
        ]]);
    }

    public function destroyCourt(string $court)
    {
        $model = Court::query()->where('name', $court)->firstOrFail();
        $model->update(['is_active' => false]);

        return response()->json(['message' => 'Lapangan dinonaktifkan.']);
    }

    public function storeSlot(Request $request)
    {
        $data = $request->validate(['slot' => ['required', 'date_format:H:i']]);
        $slot = BlockedSlot::query()->firstOrCreate($data);

        return response()->json(['data' => $slot], $slot->wasRecentlyCreated ? 201 : 200);
    }

    public function destroySlot(string $slot)
    {
        $normalized = str_replace('.', ':', $slot);
        BlockedSlot::query()->where('slot', $normalized)->delete();

        return response()->json(['message' => 'Slot dibuka kembali.']);
    }
}
