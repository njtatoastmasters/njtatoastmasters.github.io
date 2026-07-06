-- ═══════════════════════════════════════════════════════════════
-- OnRamp — NJTA Toastmasters
-- Supabase Database Schema
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

-- ── Members ──────────────────────────────────────────────────────
-- Stores club member profiles, synced to Supabase Auth
CREATE TABLE members (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT NOT NULL,
  email       TEXT,
  role        TEXT NOT NULL DEFAULT 'member'  -- 'member' | 'officer' | 'admin'
              CHECK (role IN ('member', 'officer', 'admin')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create member profile on first login
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO members (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'member')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── Meetings ──────────────────────────────────────────────────────
CREATE TABLE meetings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title               TEXT,
  meeting_date        DATE NOT NULL,
  meeting_time        TIME DEFAULT '12:00',
  location            TEXT,
  format              TEXT DEFAULT 'regular'
                      CHECK (format IN ('regular', 'contest', 'humorous', 'special')),
  speaker_slots_count INTEGER DEFAULT 3,
  notes               TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── Meeting roles ─────────────────────────────────────────────────
-- One row per role per meeting (only for filled roles)
CREATE TABLE meeting_roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id  UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  role_id     TEXT NOT NULL,  -- 'tmod' | 'ge' | 'timer' | 'grammarian' | 'ah_counter' | 'topicsmaster' | 'ballot_counter' | 'sergeant'
  member_id   UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (meeting_id, role_id)  -- one person per role per meeting
);

-- ── Speaker slots ─────────────────────────────────────────────────
-- Slots are pre-created when a meeting is scheduled; member_id is null until claimed
CREATE TABLE speaker_slots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id      UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  slot_order      INTEGER NOT NULL DEFAULT 1,
  member_id       UUID REFERENCES members(id) ON DELETE SET NULL,
  speech_title    TEXT,
  pathway         TEXT,
  project_name    TEXT,
  evaluator_notes TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Speeches (history log) ────────────────────────────────────────
-- Records each completed speech for Pathways tracking
CREATE TABLE speeches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id       UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  meeting_id      UUID REFERENCES meetings(id) ON DELETE SET NULL,
  speaker_slot_id UUID REFERENCES speaker_slots(id) ON DELETE SET NULL,
  speech_title    TEXT,
  pathway         TEXT,
  project_name    TEXT,
  notes           TEXT,           -- member's private notes
  delivered_at    DATE,           -- date delivered (defaults to meeting date if null)
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- Ensures members can only see/edit what they're allowed to
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE members       ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE speaker_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE speeches      ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM members WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Members: everyone can read; only admin can insert/update/delete
CREATE POLICY "members_select" ON members FOR SELECT TO authenticated USING (true);
CREATE POLICY "members_insert" ON members FOR INSERT TO authenticated WITH CHECK (is_admin() OR id = auth.uid());
CREATE POLICY "members_update" ON members FOR UPDATE TO authenticated USING (is_admin() OR id = auth.uid());
CREATE POLICY "members_delete" ON members FOR DELETE TO authenticated USING (is_admin());

-- Meetings: all authenticated users can read; only admins can write
CREATE POLICY "meetings_select" ON meetings FOR SELECT TO authenticated USING (true);
CREATE POLICY "meetings_insert" ON meetings FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "meetings_update" ON meetings FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "meetings_delete" ON meetings FOR DELETE TO authenticated USING (is_admin());

-- Meeting roles: all can read; members can insert for themselves; members can delete own rows
CREATE POLICY "roles_select" ON meeting_roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "roles_insert" ON meeting_roles FOR INSERT TO authenticated WITH CHECK (member_id = auth.uid() OR is_admin());
CREATE POLICY "roles_delete" ON meeting_roles FOR DELETE TO authenticated USING (member_id = auth.uid() OR is_admin());

-- Speaker slots: all can read; members can claim/update own slots; admin can do anything
CREATE POLICY "slots_select" ON speaker_slots FOR SELECT TO authenticated USING (true);
CREATE POLICY "slots_update" ON speaker_slots FOR UPDATE TO authenticated
  USING (member_id = auth.uid() OR member_id IS NULL OR is_admin())
  WITH CHECK (member_id = auth.uid() OR member_id IS NULL OR is_admin());
CREATE POLICY "slots_insert" ON speaker_slots FOR INSERT TO authenticated WITH CHECK (is_admin());

-- Speeches: members can read all; can insert/update own records; admin can do anything
CREATE POLICY "speeches_select" ON speeches FOR SELECT TO authenticated USING (true);
CREATE POLICY "speeches_insert" ON speeches FOR INSERT TO authenticated WITH CHECK (member_id = auth.uid() OR is_admin());
CREATE POLICY "speeches_update" ON speeches FOR UPDATE TO authenticated USING (member_id = auth.uid() OR is_admin());
CREATE POLICY "speeches_delete" ON speeches FOR DELETE TO authenticated USING (member_id = auth.uid() OR is_admin());

-- ═══════════════════════════════════════════════════════════════
-- Sample data (optional — uncomment to seed your database)
-- ═══════════════════════════════════════════════════════════════

/*
-- Sample meeting
INSERT INTO meetings (title, meeting_date, meeting_time, location, speaker_slots_count, notes)
VALUES ('Regular Meeting — July', '2026-07-08', '12:00', 'HQ Conference Room B, Floor 14', 3, 'Bring your best Table Topics game!');

-- Get the meeting id from above, then insert speaker slots:
-- INSERT INTO speaker_slots (meeting_id, slot_order) VALUES ('<meeting_id>', 1), ('<meeting_id>', 2), ('<meeting_id>', 3);
*/
