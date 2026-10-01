<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class SportsNewsController extends Controller
{
    public function __invoke()
    {
        $apiKey = (string) config('services.newsapi.key');
        abort_if($apiKey === '', 503, 'News API belum dikonfigurasi.');

        $articles = Cache::remember('newsapi.sports.id', now()->addMinutes(15), function () use ($apiKey) {
            $response = Http::acceptJson()
                ->timeout(8)
                ->get('https://newsapi.org/v2/everything', [
                    'q' => 'football OR soccer OR futsal OR sports',
                    'language' => 'en',
                    'sortBy' => 'publishedAt',
                    'pageSize' => 10,
                    'apiKey' => $apiKey,
                ]);

            abort_unless($response->successful(), 502, 'Berita olahraga sedang tidak tersedia.');

            return collect($response->json('articles', []))
                ->filter(fn ($article) => is_array($article)
                    && ! empty($article['title'])
                    && $article['title'] !== '[Removed]'
                    && ! empty($article['url']))
                ->map(fn (array $article) => [
                    'title' => $article['title'],
                    'description' => $article['description'] ?? '',
                    'imageUrl' => $article['urlToImage'] ?? null,
                    'url' => $article['url'],
                    'source' => data_get($article, 'source.name', ''),
                    'publishedAt' => $article['publishedAt'] ?? null,
                ])
                ->values()
                ->all();
        });

        return response()->json(['data' => $articles]);
    }
}
