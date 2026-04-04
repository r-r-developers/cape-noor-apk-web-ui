<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../lib/Db.php';
require_once __DIR__ . '/../lib/Auth.php';

// Server-side redirect: already logged in -> go straight to admin panel
if (getCurrentUser()) {
    header('Location: /admin/');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Login — Salaah Times Admin</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f1f5f9;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
    }
    .card {
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 4px 24px rgba(0,0,0,.1);
      padding: 2.5rem;
      width: 100%;
      max-width: 400px;
    }
    h1 { font-size: 1.6rem; margin-bottom: .25rem; }
    .sub { color: #64748b; font-size: .9rem; margin-bottom: 1.75rem; }
    .form-group { margin-bottom: 1.25rem; }
    label { display: block; font-weight: 600; font-size: .875rem; margin-bottom: .35rem; }
    input[type="text"], input[type="email"], input[type="password"] {
      width: 100%; padding: .65rem .8rem;
      border: 1.5px solid #cbd5e1; border-radius: 6px;
      font-size: .95rem; font-family: inherit;
      transition: border-color .15s;
    }
    input:focus { outline: none; border-color: #3b82f6; }
    .btn {
      width: 100%; padding: .75rem;
      background: #3b82f6; color: #fff;
      border: none; border-radius: 6px;
      font-weight: 700; font-size: 1rem;
      cursor: pointer; transition: background .15s;
      margin-top: .25rem;
    }
    .btn:hover { background: #2563eb; }
    .btn:disabled { opacity: .6; cursor: not-allowed; }
    .error {
      background: #fee2e2; border: 1px solid #fca5a5; color: #991b1b;
      padding: .7rem .9rem; border-radius: 6px;
      font-size: .875rem; margin-bottom: 1rem; display: none;
    }
    .forgot { text-align: right; margin-top: -.75rem; margin-bottom: 1rem; }
    .forgot a { font-size: .85rem; color: #3b82f6; text-decoration: none; }
    .forgot a:hover { text-decoration: underline; }
    .reset-link { margin-top: 1rem; text-align: center; font-size: .85rem; color: #64748b; }
  </style>
</head>
<body>
<div class="card">
  <h1>Admin Panel</h1>
  <p class="sub">Sign in to manage mosque profiles</p>

  <div id="error-msg" class="error" role="alert"></div>

  <form id="login-form" novalidate>
    <div class="form-group">
      <label for="username">Username or Email</label>
      <input type="text" id="username" name="username" required autocomplete="username" />
    </div>
    <div class="form-group">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" required autocomplete="current-password" />
    </div>
    <p class="forgot"><a href="#" id="forgot-link">Forgot password?</a></p>
    <button type="submit" class="btn" id="submit-btn">Sign In</button>
  </form>

  <p class="reset-link"><a href="/">← Back to site</a></p>
</div>

<script>
  const form  = document.getElementById('login-form');
  const errEl = document.getElementById('error-msg');
  const btn   = document.getElementById('submit-btn');

  function showError(msg) {
    errEl.textContent = msg;
    errEl.style.display = 'block';
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errEl.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Signing in…';

    try {
      const res  = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: document.getElementById('username').value.trim(),
          password: document.getElementById('password').value,
        }),
      });
      const json = await res.json();

      if (res.ok && json.success) {
        window.location.replace('/admin/');
      } else {
        showError(json.error || 'Login failed');
        btn.disabled = false;
        btn.textContent = 'Sign In';
      }
    } catch (err) {
      showError('Network error — please try again');
      btn.disabled = false;
      btn.textContent = 'Sign In';
    }
  });

  // Forgot password flow
  document.getElementById('forgot-link').addEventListener('click', async (e) => {
    e.preventDefault();
    const email = prompt('Enter your email address:');
    if (!email) return;

    try {
      const res  = await fetch('/api/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const json = await res.json();
      alert(json.message || 'If that email exists, a reset link has been sent.');
    } catch {
      alert('Network error — please try again.');
    }
  });
</script>
</body>
</html>
