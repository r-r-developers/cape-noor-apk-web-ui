<?php
/**
 * Minimal SMTP mailer (no external dependencies).
 * Reads config from the `settings` table first, falls back to config.php constants.
 *
 * Supported secure modes:
 *   'ssl'  — implicit TLS on port 465 (ssl://host)
 *   'tls'  — STARTTLS on port 587 (plain connect, then upgrade)
 *   ''     — plain SMTP (not recommended)
 */
class Mailer {
    private string $host;
    private int    $port;
    private string $username;
    private string $password;
    private string $secure;
    private string $fromEmail;
    private string $fromName;

    public function __construct() {
        if (!defined('SMTP_HOST')) {
            require_once __DIR__ . '/../config.php';
        }
        require_once __DIR__ . '/Db.php';

        // Load overrides stored in the settings table
        $cfg = [];
        try {
            $rows = db()->query(
                "SELECT `key`, value FROM settings WHERE `key` LIKE 'smtp_%'"
            )->fetchAll();
            foreach ($rows as $r) {
                $cfg[$r['key']] = $r['value'];
            }
        } catch (Throwable) { /* DB not ready yet — use config.php defaults */ }

        $this->host      = $cfg['smtp_host']       ?? SMTP_HOST;
        $this->port      = (int)($cfg['smtp_port'] ?? SMTP_PORT);
        $this->username  = $cfg['smtp_username']   ?? SMTP_USERNAME;
        $this->password  = $cfg['smtp_password']   ?? SMTP_PASSWORD;
        $this->secure    = $cfg['smtp_secure']     ?? SMTP_SECURE;
        $this->fromEmail = $cfg['smtp_from_email'] ?? SMTP_FROM_EMAIL;
        $this->fromName  = $cfg['smtp_from_name']  ?? SMTP_FROM_NAME;
    }

    /**
     * Send an HTML email.
     *
     * @throws RuntimeException on SMTP failure
     */
    public function send(string $toEmail, string $toName, string $subject, string $htmlBody): void {
        $sock = $this->connect();

        $hostname = $_SERVER['HTTP_HOST'] ?? 'localhost';

        // Initial EHLO
        $this->read($sock); // consume greeting
        $this->cmd($sock, "EHLO {$hostname}");

        if ($this->secure === 'tls') {
            $this->cmd($sock, 'STARTTLS');
            stream_socket_enable_crypto($sock, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
            $this->cmd($sock, "EHLO {$hostname}");
        }

        $this->cmd($sock, 'AUTH LOGIN');
        $this->cmd($sock, base64_encode($this->username));
        $this->cmd($sock, base64_encode($this->password));

        $this->cmd($sock, "MAIL FROM:<{$this->fromEmail}>");
        $this->cmd($sock, "RCPT TO:<{$toEmail}>");
        $this->cmd($sock, 'DATA');

        $plainText = strip_tags(preg_replace('/<br\s*\/?>/i', "\n", $htmlBody) ?? $htmlBody);
        $boundary  = bin2hex(random_bytes(8));

        $headers  = "From: =?UTF-8?B?" . base64_encode($this->fromName) . "?= <{$this->fromEmail}>\r\n";
        $headers .= "To: =?UTF-8?B?" . base64_encode($toName) . "?= <{$toEmail}>\r\n";
        $headers .= "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n";
        $headers .= "Date: " . date('r') . "\r\n";
        $headers .= "MIME-Version: 1.0\r\n";
        $headers .= "Content-Type: multipart/alternative; boundary=\"{$boundary}\"\r\n";

        $body  = "--{$boundary}\r\n";
        $body .= "Content-Type: text/plain; charset=UTF-8\r\n\r\n";
        $body .= $plainText . "\r\n";
        $body .= "--{$boundary}\r\n";
        $body .= "Content-Type: text/html; charset=UTF-8\r\n\r\n";
        $body .= $htmlBody . "\r\n";
        $body .= "--{$boundary}--\r\n";

        fwrite($sock, $headers . "\r\n" . $body . "\r\n.\r\n");
        $response = $this->read($sock);

        if (!str_starts_with(trim($response), '250')) {
            throw new RuntimeException("SMTP DATA error: {$response}");
        }

        $this->cmd($sock, 'QUIT');
        fclose($sock);
    }

    // ── Convenience wrappers ──────────────────────────────────────────────────

    public function sendPasswordReset(string $toEmail, string $toName, string $token): void {
        $link    = APP_URL . '/admin/reset-password.php?token=' . urlencode($token);
        $appName = APP_NAME;
        $this->send($toEmail, $toName, "Password reset — {$appName}", <<<HTML
        <p>Hi {$toName},</p>
        <p>Someone requested a password reset for your {$appName} account.</p>
        <p><a href="{$link}" style="background:#3b82f6;color:#fff;padding:10px 20px;text-decoration:none;border-radius:4px;">Reset Password</a></p>
        <p>This link expires in 1 hour. If you didn't request this, ignore this email.</p>
        HTML);
    }

    public function sendPendingChangeNotification(
        string $toEmail, string $toName,
        string $mosqueName, string $submittedBy
    ): void {
        $link    = APP_URL . '/admin/#pending';
        $appName = APP_NAME;
        $this->send($toEmail, $toName, "New pending change — {$mosqueName}", <<<HTML
        <p>Hi {$toName},</p>
        <p><strong>{$submittedBy}</strong> has submitted a change for <strong>{$mosqueName}</strong> that requires your approval.</p>
        <p><a href="{$link}" style="background:#3b82f6;color:#fff;padding:10px 20px;text-decoration:none;border-radius:4px;">Review Change</a></p>
        HTML);
    }

    public function sendChangeReviewed(
        string $toEmail, string $toName,
        string $mosqueName, string $status, string $note = ''
    ): void {
        $icon    = $status === 'approved' ? '✅' : '❌';
        $appName = APP_NAME;
        $noteHtml = $note ? "<p><strong>Note:</strong> {$note}</p>" : '';
        $this->send($toEmail, $toName, "{$icon} Your change was {$status} — {$mosqueName}", <<<HTML
        <p>Hi {$toName},</p>
        <p>Your pending change for <strong>{$mosqueName}</strong> has been <strong>{$status}</strong>.</p>
        {$noteHtml}
        <p><a href="{APP_URL}/admin/" style="background:#3b82f6;color:#fff;padding:10px 20px;text-decoration:none;border-radius:4px;">Go to Admin Panel</a></p>
        HTML);
    }

    public function sendWelcome(string $toEmail, string $toName, string $tempPassword): void {
        $link    = APP_URL . '/admin/';
        $appName = APP_NAME;
        $this->send($toEmail, $toName, "Welcome to {$appName}", <<<HTML
        <p>Hi {$toName},</p>
        <p>An account has been created for you on <strong>{$appName}</strong>.</p>
        <p><strong>Login:</strong> {$toEmail}<br>
           <strong>Temporary password:</strong> {$tempPassword}</p>
        <p>Please <a href="{$link}">log in</a> and change your password immediately.</p>
        HTML);
    }

    // ── Low-level helpers ─────────────────────────────────────────────────────

    /** @return resource */
    private function connect() {
        $target = ($this->secure === 'ssl')
            ? "ssl://{$this->host}:{$this->port}"
            : "tcp://{$this->host}:{$this->port}";

        $ctx  = stream_context_create(['ssl' => ['verify_peer' => true, 'verify_peer_name' => true]]);
        $sock = @stream_socket_client($target, $errno, $errstr, 15, STREAM_CLIENT_CONNECT, $ctx);

        if (!$sock) {
            throw new RuntimeException("SMTP connection to {$target} failed: {$errstr} ({$errno})");
        }

        stream_set_timeout($sock, 15);
        return $sock;
    }

    /** @param resource $sock */
    private function cmd($sock, string $command): string {
        fwrite($sock, $command . "\r\n");
        return $this->read($sock);
    }

    /** @param resource $sock */
    private function read($sock): string {
        $response = '';
        while ($line = fgets($sock, 512)) {
            $response .= $line;
            if (strlen($line) >= 4 && $line[3] === ' ') break;
        }
        return $response;
    }
}
