# OnRamp — NJTA Toastmasters Club Portal

> *Your on-ramp to confident speaking.*

A lightweight, modern meeting sign-up portal for NJTA Toastmasters. Members log in, claim roles, sign up as speakers, and track their Pathways progress — no more day-of agenda scrambles.

---

## Tech stack

| Layer | Technology | Cost |
|---|---|---|
| Hosting | GitHub Pages | Free |
| Backend / database | Supabase | Free (up to 500MB, 50k auth users) |
| Authentication | Supabase magic link email | Free |
| Frontend | Vanilla HTML + CSS + JS | — |

---

## Setup: step by step

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free).
2. Click **New project** → name it `onramp-njta` → pick a region close to NJ (US East).
3. Wait ~2 minutes for the project to spin up.

### Step 2 — Run the database schema

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar.
2. Click **New query**.
3. Copy and paste the entire contents of `supabase-schema.sql` from this repo.
4. Click **Run** (or press Cmd/Ctrl + Enter).
5. You should see "Success. No rows returned."

### Step 3 — Configure authentication

1. In Supabase, go to **Authentication → Settings**.
2. Under **Site URL**, enter your GitHub Pages URL, e.g.:  
   `https://YOUR-USERNAME.github.io/onramp`
3. Under **Redirect URLs**, add:  
   `https://YOUR-USERNAME.github.io/onramp/pages/dashboard.html`
4. Under **Email**, make sure **Enable email provider** is on and  
   **Confirm email** is OFF (so magic links work without a separate confirmation step).

### Step 4 — Get your Supabase keys

1. In Supabase, go to **Settings → API**.
2. Copy:
   - **Project URL** (looks like `https://abcxyz.supabase.co`)
   - **anon / public key** (the long JWT string under "Project API keys")

### Step 5 — Add your keys to the site files

Search for `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` in all HTML files and replace with your actual values. They appear in:

- `index.html`
- `pages/dashboard.html`
- `pages/meetings.html`
- `pages/my-speeches.html`
- `pages/admin.html`
- `pages/agenda.html`
- `pages/members.html`

> **Tip:** Use Find & Replace in VS Code: `Cmd+Shift+H` (Mac) or `Ctrl+Shift+H` (Windows).

### Step 6 — Push to GitHub Pages

1. Create a new GitHub repository named `onramp` (or any name you like).
2. Push this folder to the repo:
   ```bash
   git init
   git add .
   git commit -m "Initial OnRamp site"
   git remote add origin https://github.com/YOUR-USERNAME/onramp.git
   git push -u origin main
   ```
3. In GitHub, go to **Settings → Pages**.
4. Under **Source**, select **Deploy from a branch → main → / (root)**.
5. Your site will be live at `https://YOUR-USERNAME.github.io/onramp` within ~2 minutes.

### Step 7 — Create the first admin account (yourself)

1. Go to your live site and enter your email on the login page.
2. Click the magic link in your email.
3. You'll be logged in, but as a regular member.
4. In Supabase, go to **Table Editor → members**.
5. Find your row and change `role` from `member` to `admin`.
6. Refresh the site — you'll now see the **Admin** link in the nav.

### Step 8 — Add your club members

1. Log in as admin and go to **Admin → Members → Add member**.
2. Enter each member's name and email — they'll receive a magic link and can log in immediately.
3. No passwords, no IT involvement, no Active Directory.

---

## Page guide

| Page | URL | Who can access |
|---|---|---|
| Login | `/index.html` | Anyone (public) |
| Dashboard | `/pages/dashboard.html` | All members |
| Meetings | `/pages/meetings.html` | All members |
| My Speeches | `/pages/my-speeches.html` | All members (own data) |
| Members | `/pages/members.html` | All members |
| Admin | `/pages/admin.html` | Admins only |
| Agenda | `/pages/agenda.html?id=MEETING_ID` | All members; printable/shareable |

---

## How it works for members

1. An admin schedules a meeting with a date, time, location, and number of speaker slots.
2. Members receive (or check) the site and see upcoming meetings with open roles.
3. Members click **Take it** on any open role or **Sign up** on an open speaker slot.
4. For speaker slots, they enter their speech title, Pathways path, and project.
5. The admin (and everyone) can view a clean, printable agenda at any time.
6. Members can drop roles before the meeting if needed.
7. Speech history is automatically tracked on the My Speeches page.

---

## Roles tracked

- Toastmaster of the Day (TMoD)
- General Evaluator
- Table Topics Master
- Timer
- Ah-Counter
- Grammarian
- Ballot Counter
- Sergeant at Arms

Speaker evaluators are not automatically assigned — the TMoD or GE handles that at the meeting.

---

## IT / network access

OnRamp is hosted on `github.io` (GitHub Pages) using HTTPS. It has no corporate dependencies.
If your IT department blocks github.io, two options:

1. **Ask for an exception** — frame it as a read-mostly informational site for an employee club.
2. **Custom domain** — buy a domain (e.g. `njta-speaks.com` for ~$12/yr) and point it to GitHub Pages. This bypasses any github.io filtering.

---

## Future enhancements (not yet built)

- [ ] Email notifications when a new meeting is posted
- [ ] Automatic reminder if you haven't signed up 5 days before a meeting
- [ ] Evaluator assignment (link speakers to their evaluators)
- [ ] Club awards / Best Speaker / Best Table Topics tracking
- [ ] Export agenda to Word or PDF
- [ ] Public-facing landing page (for recruiting new members)
