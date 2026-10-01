<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('email_verification_codes')) {
            Schema::create('email_verification_codes', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
                $table->string('code_hash');
                $table->timestamp('expires_at')->index();
                $table->unsignedTinyInteger('attempts')->default(0);
                $table->timestamps();
            });
        }

        Schema::table('email_verification_codes', function (Blueprint $table) {
            if (! Schema::hasColumn('email_verification_codes', 'resend_at')) {
                $table->timestamp('resend_at')->nullable()->after('expires_at');
            }
        });
    }

    public function down(): void
    {
        if (Schema::hasTable('email_verification_codes')) {
            Schema::table('email_verification_codes', function (Blueprint $table) {
                if (Schema::hasColumn('email_verification_codes', 'resend_at')) {
                    $table->dropColumn('resend_at');
                }
            });
        }
    }
};
