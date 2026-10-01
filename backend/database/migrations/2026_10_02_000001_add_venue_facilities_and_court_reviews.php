<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('venue_settings', 'facilities')) {
            Schema::table('venue_settings', function (Blueprint $table) {
                $table->json('facilities')->nullable();
            });
        }

        Schema::create('court_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('court_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment');
            $table->timestamps();
            $table->unique(['court_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('court_reviews');
        if (Schema::hasColumn('venue_settings', 'facilities')) {
            Schema::table('venue_settings', function (Blueprint $table) {
                $table->dropColumn('facilities');
            });
        }
    }
};
