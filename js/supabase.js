// ── Supabase configuration ──────────────────────────────────────────────────
// Replace these values with your own from the Supabase dashboard:
//   Settings → API → Project URL and anon/public key
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

// Load Supabase from CDN (included in each HTML page)
const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ── Auth helpers ─────────────────────────────────────────────────────────────

async function getSession() {
  const { data } = await sb.auth.getSession();
  return data.session;
}

async function getUser() {
  const { data } = await sb.auth.getUser();
  return data.user;
}

async function getProfile() {
  const user = await getUser();
  if (!user) return null;
  const { data } = await sb.from('members').select('*').eq('id', user.id).single();
  return data;
}

async function requireAuth() {
  const session = await getSession();
  if (!session) {
    window.location.href = '/index.html';
    return null;
  }
  return session;
}

async function requireAdmin() {
  const profile = await getProfile();
  if (!profile || profile.role !== 'admin') {
    window.location.href = '/pages/dashboard.html';
    return null;
  }
  return profile;
}

async function signOut() {
  await sb.auth.signOut();
  window.location.href = '/index.html';
}

// ── Toast notifications ──────────────────────────────────────────────────────

function showToast(message, type = 'default') {
  const container = document.getElementById('toast-container') || createToastContainer();
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'opacity 0.3s, transform 0.3s';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

function createToastContainer() {
  const el = document.createElement('div');
  el.id = 'toast-container';
  el.className = 'toast-container';
  document.body.appendChild(el);
  return el;
}

// ── Nav: populate user info ──────────────────────────────────────────────────

async function initNav() {
  const profile = await getProfile();
  if (!profile) return;

  const nameEl = document.getElementById('nav-user-name');
  const avatarEl = document.getElementById('nav-avatar');

  if (nameEl) nameEl.textContent = profile.full_name.split(' ')[0];
  if (avatarEl) {
    const initials = profile.full_name.split(' ').map(n => n[0]).join('').slice(0, 2);
    avatarEl.textContent = initials;
  }

  // Highlight active nav link
  const currentPage = window.location.pathname.split('/').pop();
  document.querySelectorAll('.nav-links a').forEach(link => {
    if (link.getAttribute('href').endsWith(currentPage)) {
      link.classList.add('active');
    }
  });
}

// ── Modal helpers ────────────────────────────────────────────────────────────

function openModal(id) {
  document.getElementById(id).classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeModal(id) {
  document.getElementById(id).classList.remove('open');
  document.body.style.overflow = '';
}

// Close modal when clicking overlay
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('open');
    document.body.style.overflow = '';
  }
});

// ── Tab helpers ──────────────────────────────────────────────────────────────

function initTabs(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  const buttons = container.querySelectorAll('.tab-btn');
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'));
      container.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById(btn.dataset.tab).classList.add('active');
    });
  });
}

// ── Date helpers ─────────────────────────────────────────────────────────────

function formatDate(dateStr) {
  const d = new Date(dateStr + 'T12:00:00');
  return d.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
}

function formatDateShort(dateStr) {
  const d = new Date(dateStr + 'T12:00:00');
  return { month: d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase(), day: d.getDate() };
}

function formatTime(timeStr) {
  if (!timeStr) return '';
  const [h, m] = timeStr.split(':');
  const hour = parseInt(h);
  const ampm = hour >= 12 ? 'PM' : 'AM';
  const h12 = hour % 12 || 12;
  return `${h12}:${m} ${ampm}`;
}

// ── Pathways data ─────────────────────────────────────────────────────────────

const PATHWAYS = [
  'Presentation Mastery',
  'Persuasive Influence',
  'Dynamic Leadership',
  'Innovative Planning',
  'Motivational Strategies',
  'Strategic Relationships',
  'Visionary Communication',
  'Effective Coaching',
  'Team Collaboration',
  'Leadership Development',
  'Active Listening',
  'Engaging Humor',
];

const ROLES = [
  { id: 'tmod', name: 'Toastmaster of the Day', abbr: 'TMoD' },
  { id: 'ge', name: 'General Evaluator', abbr: 'GE' },
  { id: 'topicsmaster', name: 'Table Topics Master', abbr: 'TT Master' },
  { id: 'timer', name: 'Timer', abbr: 'Timer' },
  { id: 'ah_counter', name: 'Ah-Counter', abbr: 'Ah-Counter' },
  { id: 'grammarian', name: 'Grammarian', abbr: 'Grammarian' },
  { id: 'ballot_counter', name: 'Ballot Counter', abbr: 'Ballots' },
  { id: 'sergeant', name: 'Sergeant at Arms', abbr: 'SAA' },
];
