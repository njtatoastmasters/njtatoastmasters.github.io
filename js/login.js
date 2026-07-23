// OnRamp login logic — external file (no inline JS, per security review)
const SUPABASE_URL = 'https://sxkmvlpzpkoiyvaowdyn.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_xget8F5pAkCg0LyWsfUf-A_QhgcZWk-';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// If already logged in, go to dashboard
sb.auth.getSession().then(({ data }) => {
  if (data.session) window.location.href = 'pages/dashboard.html';
});

// Handle auth callback (when user clicks magic link)
sb.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN' && session) {
    window.location.href = 'pages/dashboard.html';
  }
});

async function sendMagicLink() {
  const email = document.getElementById('email').value.trim();

  // Client-side email format validation
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
    showAlert('Please enter a valid email address.', 'danger');
    return;
  }

  // Require a completed CAPTCHA before sending
  const captchaToken = typeof turnstile !== 'undefined' ? turnstile.getResponse() : null;
  if (!captchaToken) {
    showAlert('Please complete the verification check below.', 'danger');
    return;
  }

  const btn = document.getElementById('send-link-btn');
  btn.textContent = 'Sending…';
  btn.disabled = true;

  await sb.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: 'https://njtatoastmasters.github.io/pages/dashboard.html',
      captchaToken
    }
  });

  // Anti-enumeration: same confirmation regardless of outcome, so the
  // response never reveals whether an email is registered with the club.
  btn.textContent = 'Send sign-in link';
  btn.disabled = false;
  document.getElementById('form-request').style.display = 'none';
  document.getElementById('sent-email').textContent = email;
  document.getElementById('form-sent').style.display = 'block';
}

function showAlert(msg, type) {
  const el = document.getElementById('login-alert');
  el.className = 'alert alert-' + type;
  el.textContent = msg;
  el.style.display = 'flex';
}

function resetForm() {
  document.getElementById('form-request').style.display = 'block';
  document.getElementById('form-sent').style.display = 'none';
  document.getElementById('email').value = '';
  if (typeof turnstile !== 'undefined') turnstile.reset();
}

// Event listeners (replaces inline onclick handlers)
document.getElementById('send-link-btn').addEventListener('click', sendMagicLink);
document.getElementById('reset-form-btn').addEventListener('click', resetForm);
document.getElementById('email').addEventListener('keydown', function (e) {
  if (e.key === 'Enter') sendMagicLink();
});
