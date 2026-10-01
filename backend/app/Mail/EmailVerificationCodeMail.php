<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EmailVerificationCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $verificationUrl, public string $code) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Kode verifikasi email FutsalGo');
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.verification-code',
            with: [
                'verificationUrl' => $this->verificationUrl,
                'code' => $this->code,
            ],
        );
    }
}
