<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StoredImage;
use Illuminate\Support\Facades\Storage;

class PublicCourtImageController extends Controller
{
    public function __invoke(string $directory, string $filename)
    {
        abort_unless(in_array($directory, ['courts', 'promo-banners'], true), 404);
        abort_unless($filename === basename($filename), 404);

        $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
        abort_unless(in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true), 404);

        $path = "{$directory}/{$filename}";
        $image = StoredImage::query()->where('path', $path)->first();
        if ($image !== null) {
            $contents = base64_decode($image->base64_data, true);
            abort_unless($contents !== false, 404);
            $mimeType = $image->mime_type;
        } else {
            $disk = Storage::disk('public');
            abort_unless($disk->exists($path), 404);
            $contents = $disk->get($path);
            $mimeType = $disk->mimeType($path) ?? 'application/octet-stream';
        }

        return response(
            $contents,
            200,
            [
                'Content-Type' => $mimeType,
                'Cache-Control' => 'public, max-age=31536000, immutable',
                'X-Content-Type-Options' => 'nosniff',
            ],
        );
    }
}
