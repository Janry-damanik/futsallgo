<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\EmailVerificationCodeMail;
use App\Models\EmailVerificationCode;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\URL;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:180', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::create($data + ['role' => 'customer']);
        $this->sendVerificationCode($user);

        return response()->json([
            'status' => 'otp_pending',
            'message' => 'Kode verifikasi dikirim ke email.',
            'data' => ['email' => $user->email],
        ], 202);
    }

    public function resendVerificationLink(Request $request)
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $user = User::query()->where('email', $data['email'])->first();

        if ($user && ! $user->email_verified_at) {
            $this->sendVerificationCode($user);
        }

        return response()->json([
            'status' => 'otp_pending',
            'message' => 'Jika akun perlu verifikasi, kode OTP baru akan dikirim ke email.',
            'data' => ['email' => $data['email']],
        ], 202);
    }

    public function resendVerificationCode(Request $request)
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || $user->email_verified_at) {
            return response()->json([
                'status' => 'not_required',
                'message' => 'Email sudah diverifikasi atau tidak ditemukan.',
            ], 200);
        }

        $verificationCode = EmailVerificationCode::query()->where('user_id', $user->id)->first();
        $now = now();

        if ($verificationCode && $verificationCode->resend_at && $verificationCode->resend_at->greaterThan($now)) {
            return response()->json([
                'status' => 'rate_limited',
                'message' => 'Tunggu 60 detik sebelum mengirim ulang OTP.',
                'data' => [
                    'resendAvailableIn' => 60,
                ],
            ], 429);
        }

        $this->sendVerificationCode($user);

        return response()->json([
            'status' => 'otp_resent',
            'message' => 'Kode OTP baru telah dikirim ke email.',
        ], 202);
    }

    public function verifyEmail(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'string', 'size:6'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user) {
            throw ValidationException::withMessages(['email' => ['Email tidak ditemukan.']]);
        }

        $verificationCode = EmailVerificationCode::query()->where('user_id', $user->id)->first();

        if (! $verificationCode) {
            throw ValidationException::withMessages(['code' => ['Kode verifikasi belum dibuat. Silakan kirim ulang OTP.']]);
        }

        if ($verificationCode->expires_at->isPast()) {
            $verificationCode->delete();
            throw ValidationException::withMessages(['code' => ['Kode verifikasi sudah kedaluwarsa. Silakan kirim ulang OTP.']]);
        }

        if ($verificationCode->attempts >= 5) {
            $verificationCode->delete();
            throw ValidationException::withMessages(['code' => ['Kode verifikasi diblokir karena terlalu banyak percobaan. Silakan kirim ulang OTP.']]);
        }

        if (! Hash::check($data['code'], $verificationCode->code_hash)) {
            $verificationCode->increment('attempts');
            throw ValidationException::withMessages(['code' => ['Kode verifikasi salah atau sudah kedaluwarsa.']]);
        }

        $user->forceFill(['email_verified_at' => now()])->save();
        $verificationCode->delete();

        return response()->json([
            'message' => 'Email berhasil diverifikasi.',
        ]);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);
        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => ['Email atau password salah.']]);
        }

        if (! config('app.skip_email_verification', false) && ! $user->email_verified_at) {
            throw ValidationException::withMessages(['email' => ['Email belum diverifikasi. Buka tautan yang dikirim ke email.']]);
        }

        return $this->tokenResponse($user);
    }

    public function me(Request $request)
    {
        return response()->json(['data' => $this->userData($request->user())]);
    }

    public function updateProfile(Request $request)
    {
        $data = $request->validate(['name' => ['required', 'string', 'max:120']]);
        $request->user()->update($data);

        return $this->me($request);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }

    private function tokenResponse(User $user, int $status = 200)
    {
        return response()->json([
            'data' => [
                'token' => $user->createToken('futsalgo-mobile')->plainTextToken,
                'user' => $this->userData($user),
            ],
        ], $status);
    }

    private function sendVerificationCode(User $user): void
    {
        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify',
            now()->addHour(),
            [
                'id' => $user->id,
                'hash' => sha1($user->email),
            ],
        );

        $code = (string) random_int(100000, 999999);

        EmailVerificationCode::updateOrCreate(
            ['user_id' => $user->id],
            [
                'code_hash' => Hash::make($code),
                'expires_at' => now()->addMinutes(10),
                'attempts' => 0,
                'resend_at' => now()->addSeconds(60),
            ],
        );

        Mail::to($user->email)->send(new EmailVerificationCodeMail($verificationUrl, $code));
    }

    private function userData(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
        ];
    }
}