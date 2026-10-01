<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CourtReviewController;
use App\Http\Controllers\Api\MidtransNotificationController;
use App\Http\Controllers\Api\MidtransQrisController;
use App\Http\Controllers\Api\PromoController;
use App\Http\Controllers\Api\SportsNewsController;
use App\Http\Controllers\Api\VenueController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/auth/verify-email', [AuthController::class, 'verifyEmail'])->middleware('throttle:5,1');
    Route::post('/auth/otp/resend', [AuthController::class, 'resendVerificationCode'])->middleware('throttle:3,1');
    Route::post('/auth/verification-link/resend', [AuthController::class, 'resendVerificationLink'])->middleware('throttle:10,1');
    Route::post('/auth/verification-code/resend', [AuthController::class, 'resendVerificationCode'])->middleware('throttle:3,1');
    Route::get('/settings', [VenueController::class, 'show']);
    Route::get('/courts', [VenueController::class, 'courts']);
    Route::get('/courts/{court}/reviews', [CourtReviewController::class, 'index']);
    Route::get('/promos', [PromoController::class, 'index']);
    Route::get('/sports-news', SportsNewsController::class)->middleware('throttle:30,1');
    Route::post('/payments/midtrans/notification', MidtransNotificationController::class)->middleware('throttle:60,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::patch('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/availability', [BookingController::class, 'availability']);
        Route::get('/bookings', [BookingController::class, 'index']);
        Route::post('/bookings', [BookingController::class, 'store'])->middleware('throttle:20,1');
        Route::post('/bookings/{booking}/qris', [MidtransQrisController::class, 'store'])->middleware('throttle:5,1');
        Route::get('/bookings/{booking}/payment-status', [MidtransQrisController::class, 'status'])->middleware('throttle:10,1');

        Route::middleware('admin')->group(function () {
            Route::patch('/bookings/{booking}', [BookingController::class, 'update']);
            Route::delete('/bookings/{booking}', [BookingController::class, 'destroy']);
            Route::put('/settings', [VenueController::class, 'update']);
            Route::put('/facilities', [VenueController::class, 'updateFacilities']);
            Route::post('/promos', [PromoController::class, 'store']);
            Route::put('/promos/{promo}', [PromoController::class, 'update']);
            Route::post('/promos/{promo}/image', [PromoController::class, 'uploadImage']);
            Route::delete('/promos/{promo}', [PromoController::class, 'destroy']);
            Route::post('/courts', [VenueController::class, 'storeCourt']);
            Route::post('/courts/{court}/image', [VenueController::class, 'uploadCourtImage']);
            Route::patch('/courts/{court}', [VenueController::class, 'updateCourt']);
            Route::delete('/courts/{court}', [VenueController::class, 'destroyCourt']);
            Route::post('/slots', [VenueController::class, 'storeSlot']);
            Route::delete('/slots/{slot}', [VenueController::class, 'destroySlot']);
        });

        Route::post('/courts/{court}/reviews', [CourtReviewController::class, 'store'])
            ->middleware('throttle:10,1');
    });
});
