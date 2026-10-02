<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

class StoredImage extends Model
{
    protected $fillable = ['path', 'mime_type', 'base64_data'];

    protected $hidden = ['base64_data'];

    public static function fromUpload(UploadedFile $file, string $directory): string
    {
        $filename = Str::uuid().'.'.$file->guessExtension();
        $path = "{$directory}/{$filename}";

        self::query()->create([
            'path' => $path,
            'mime_type' => $file->getMimeType() ?? 'application/octet-stream',
            'base64_data' => base64_encode($file->getContent()),
        ]);

        return $path;
    }

    public static function deletePath(?string $path): void
    {
        if ($path !== null) {
            self::query()->where('path', $path)->delete();
        }
    }
}
