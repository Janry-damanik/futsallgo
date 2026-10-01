<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Intentionally left empty to keep the OTP verification table enabled.
    }

    public function down(): void
    {
        Schema::dropIfExists('email_verification_codes');
    }
};