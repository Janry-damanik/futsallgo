<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
        $disk = Storage::disk('public');
        abort_unless($disk->exists($path), 404);
        $stream = $disk->readStream($path);
        abort_unless(is_resource($stream), 404);

        return response()->stream(
            function () use ($stream): void {
                fpassthru($stream);
                fclose($stream);
            },
            200,
            [
                'Content-Type' => $disk->mimeType($path) ?? 'application/octet-stream',
                'Cache-Control' => 'public, max-age=31536000, immutable',
                'X-Content-Type-Options' => 'nosniff',
            ],
        );
    }
}
