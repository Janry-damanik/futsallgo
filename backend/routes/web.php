<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ManagementController;
use App\Http\Controllers\Api\EmailVerificationController;
use App\Http\Controllers\Api\PublicCourtImageController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route(auth()->check() ? 'admin.dashboard' : 'login'));
Route::get('/admin/login', [AuthController::class, 'create'])->middleware('guest')->name('login');
Route::post('/admin/login', [AuthController::class, 'store'])->middleware('guest')->name('admin.login');
Route::post('/admin/logout', [AuthController::class, 'destroy'])->middleware('auth')->name('admin.logout');
Route::get('/storage/courts/{filename}', PublicCourtImageController::class)
    ->where('filename', '[A-Za-z0-9][A-Za-z0-9_.-]{0,254}')
    ->name('court-images.show');
Route::get('/email/verify/{id}/{hash}', EmailVerificationController::class)
    ->middleware(['signed', 'throttle:6,1'])
    ->name('verification.verify');

Route::middleware(['auth', 'admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard/occupancy', [DashboardController::class, 'occupancy'])->name('dashboard.occupancy');
    Route::get('/bookings', [ManagementController::class, 'bookings'])->name('bookings');
    Route::patch('/bookings/{booking}', [ManagementController::class, 'updateBooking'])->name('bookings.update');
    Route::delete('/bookings/{booking}', [ManagementController::class, 'deleteBooking'])->name('bookings.delete');
    Route::get('/courts', [ManagementController::class, 'courts'])->name('courts');
    Route::get('/courts/create', [ManagementController::class, 'createCourt'])->name('courts.create');
    Route::post('/courts', [ManagementController::class, 'storeCourt'])->name('courts.store');
    Route::post('/courts/{court}/image', [ManagementController::class, 'uploadCourtImage'])->name('courts.image');
    Route::patch('/courts/{court}', [ManagementController::class, 'updateCourt'])->name('courts.update');
    Route::delete('/courts/{court}', [ManagementController::class, 'deleteCourt'])->name('courts.delete');
    Route::get('/promos', [ManagementController::class, 'promos'])->name('promos');
    Route::get('/promos/create', [ManagementController::class, 'createPromo'])->name('promos.create');
    Route::post('/promos', [ManagementController::class, 'storePromo'])->name('promos.store');
    Route::get('/promos/{promo}/edit', [ManagementController::class, 'editPromo'])->name('promos.edit');
    Route::put('/promos/{promo}', [ManagementController::class, 'updatePromo'])->name('promos.update');
    Route::post('/promos/{promo}/image', [ManagementController::class, 'uploadPromoImage'])->name('promos.image');
    Route::delete('/promos/{promo}', [ManagementController::class, 'deletePromo'])->name('promos.delete');
    Route::get('/customers', [ManagementController::class, 'customers'])->name('customers');
    Route::post('/customers', [ManagementController::class, 'storeCustomer'])->name('customers.store');
    Route::patch('/customers/{user}', [ManagementController::class, 'updateCustomer'])->name('customers.update');
    Route::delete('/customers/{user}', [ManagementController::class, 'deleteCustomer'])->name('customers.delete');
    Route::get('/settings', [ManagementController::class, 'settings'])->name('settings');
    Route::put('/settings', [ManagementController::class, 'updateSettings'])->name('settings.update');
    Route::post('/settings/facilities', [ManagementController::class, 'storeFacility'])->name('settings.facilities.store');
    Route::patch('/settings/facilities/{index}', [ManagementController::class, 'updateFacility'])->whereNumber('index')->name('settings.facilities.update');
    Route::delete('/settings/facilities/{index}', [ManagementController::class, 'deleteFacility'])->whereNumber('index')->name('settings.facilities.delete');
    Route::patch('/settings/courts/{court}/details', [ManagementController::class, 'updateCourtDetails'])->name('settings.courts.details');
    Route::post('/slots', [ManagementController::class, 'storeSlot'])->name('slots.store');
    Route::delete('/slots/{blockedSlot}', [ManagementController::class, 'deleteSlot'])->name('slots.delete');
});
