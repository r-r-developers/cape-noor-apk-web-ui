<?php

declare(strict_types=1);

namespace App\Services;

/**
 * Simple SMTP mailer using PHP's built-in socket support.
 * For production, replace with PHPMailer or Symfony Mailer for full STARTTLS support.
 */
class MailService
{
    public function __construct(private readonly array $settings) {}

    public function send(string $to, string $subject, string $htmlBody): bool
    {
        $smtp = $this->settings['smtp'];

        if (empty($smtp['host'])) {
            return false;
        }

        // Use PHP mail() as fallback; for proper SMTP use PHPMailer in production
        $headers = implode("\r\n", [
            'MIME-Version: 1.0',
            'Content-Type: text/html; charset=UTF-8',
            'From: ' . $smtp['from_name'] . ' <' . $smtp['from_email'] . '>',
            'Reply-To: ' . $smtp['from_email'],
            'X-Mailer: SalaahApp/2.0',
        ]);

        return @mail($to, $subject, $htmlBody, $headers);
    }

    public function sendPasswordReset(string $to, string $name, string $resetLink): bool
    {
        $appName = $this->settings['app']['name'] ?? 'Salaah Times';
        $subject = "Reset your {$appName} password";
        $body    = $this->renderTemplate('password-reset', [
            'name'       => htmlspecialchars($name, ENT_QUOTES),
            'reset_link' => $resetLink,
            'app_name'   => $appName,
        ]);

        return $this->send($to, $subject, $body);
    }

    public function sendWelcome(string $to, string $name, string $tempPassword): bool
    {
        $appName = $this->settings['app']['name'] ?? 'Salaah Times';
        $subject = "Welcome to {$appName}";
        $body    = $this->renderTemplate('welcome', [
            'name'          => htmlspecialchars($name, ENT_QUOTES),
            'temp_password' => $tempPassword,
            'app_name'      => $appName,
        ]);

        return $this->send($to, $subject, $body);
    }

    private function renderTemplate(string $name, array $vars): string
    {
        $templateFile = __DIR__ . "/../templates/emails/{$name}.php";

        if (!file_exists($templateFile)) {
            // Inline fallback
            return "<p>Hi {$vars['name']},</p><p>" . implode('</p><p>', array_values($vars)) . '</p>';
        }

        ob_start();
        extract($vars, EXTR_SKIP);
        include $templateFile;
        return ob_get_clean();
    }
}
