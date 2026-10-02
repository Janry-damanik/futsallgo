<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PromoBanner;
use App\Models\StoredImage;
use Illuminate\Http\Request;

class PromoController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => PromoBanner::query()
                ->where('is_active', true)
                ->orderBy('id')
                ->get()
                ->map(fn (PromoBanner $banner) => $this->bannerData($banner)),
        ]);
    }

    public function store(Request $request)
    {
        $banner = PromoBanner::query()->create($this->validatedData($request));

        return response()->json(['data' => $this->bannerData($banner)], 201);
    }

    public function update(Request $request, PromoBanner $promo)
    {
        $promo->update($this->validatedData($request));

        return response()->json(['data' => $this->bannerData($promo->fresh())]);
    }

    public function uploadImage(Request $request, PromoBanner $promo)
    {
        $data = $request->validate([
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $path = StoredImage::fromUpload($data['image'], 'promo-banners');
        StoredImage::deletePath($promo->image_path);

        $promo->update(['image_path' => $path]);

        return response()->json(['data' => $this->bannerData($promo->fresh())]);
    }

    public function destroy(PromoBanner $promo)
    {
        StoredImage::deletePath($promo->image_path);
        $promo->delete();

        return response()->json(['message' => 'Banner dihapus.']);
    }

    private function validatedData(Request $request): array
    {
        $data = $request->validate([
            'eyebrow' => ['required', 'string', 'max:80'],
            'title' => ['required', 'string', 'max:120'],
            'subtitle' => ['nullable', 'string', 'max:180'],
            'buttonLabel' => ['required', 'string', 'max:40'],
        ]);
        $data['subtitle'] = $data['subtitle'] ?? '';
        $data['button_label'] = $data['buttonLabel'];
        unset($data['buttonLabel']);

        return $data;
    }

    private function bannerData(PromoBanner $banner): array
    {
        return [
            'id' => $banner->id,
            'eyebrow' => $banner->eyebrow,
            'title' => $banner->title,
            'subtitle' => $banner->subtitle,
            'buttonLabel' => $banner->button_label,
            'imageUrl' => $banner->image_path
                ? request()->getSchemeAndHttpHost().'/storage/'.$banner->image_path
                : null,
        ];
    }
}
