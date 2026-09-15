// OnRamp login logic — OTP (6-digit code) flow
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Already logged in? Go straight to dashboard.
sb.auth.getSession().then(({ data }) => {
  if (data.session) window.location.href = 'pages/dashboard.html';
});

let pendingEmail = null;

// ── Step 1: request a code ───────────────────────────────────────
async function sendCode() {
  const email = document.getElementById('email').value.trim();

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
    showAlert('login-alert', 'Please enter a valid email address.', 'danger');
    return;
  }

  const captchaToken = typeof turnstile !== 'undefined' ? turnstile.getResponse() : null;
  if (!captchaToken) {
    showAlert('login-alert', 'Please complete the verification check below.', 'danger');
    return;
  }

  const btn = document.getElementById('send-code-btn');
  btn.textContent = 'Sending…';
  btn.disabled = true;

  // shouldCreateUser:false means only existing/allowlisted accounts get a code.
  await sb.auth.signInWithOtp({
    email,
    options: { captchaToken, shouldCreateUser: false }
  });

  // Always advance to the code screen (don't reveal whether the email exists).
  pendingEmail = email;
  btn.textContent = 'Send my code';
  btn.disabled = false;
  document.getElementById('verify-email').textContent = email;
  document.getElementById('form-request').style.display = 'none';
  document.getElementById('form-verify').style.display = 'block';
  document.getElementById('code').focus();
}

// ── Step 2: verify the code ──────────────────────────────────────
async function verifyCode() {
  const code = document.getElementById('code').value.trim();

  if (!/^\d{6}$/.test(code)) {
    showAlert('verify-alert', 'Enter the 6-digit code from your email.', 'danger');
    return;
  }

  const btn = document.getElementById('verify-code-btn');
  btn.textContent = 'Signing in…';
  btn.disabled = true;

  const { error } = await sb.auth.verifyOtp({
    email: pendingEmail,
    token: code,
    type: 'email'
  });

  if (error) {
    showAlert('verify-alert', 'That code is incorrect or expired. Please try again.', 'danger');
    btn.textContent = 'Sign in';
    btn.disabled = false;
    return;
  }

  window.location.href = 'pages/dashboard.html';
}

function goBack() {
  document.getElementById('form-verify').style.display = 'none';
  document.getElementById('form-request').style.display = 'block';
  document.getElementById('code').value = '';
  hide('verify-alert');
  hide('login-alert');
  if (typeof turnstile !== 'undefined') turnstile.reset();
}

function showAlert(id, msg, type) {
  const el = document.getElementById(id);
  el.className = 'alert alert-' + type;
  el.textContent = msg;
  el.style.display = 'flex';
}
function hide(id) { document.getElementById(id).style.display = 'none'; }

// ── Wire up events (no inline handlers, per security review) ──────
document.getElementById('send-code-btn').addEventListener('click', sendCode);
document.getElementById('verify-code-btn').addEventListener('click', verifyCode);
document.getElementById('back-btn').addEventListener('click', goBack);
document.getElementById('email').addEventListener('keydown', e => { if (e.key === 'Enter') sendCode(); });
document.getElementById('code').addEventListener('keydown', e => { if (e.key === 'Enter') verifyCode(); });
