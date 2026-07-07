-- ═══════════════════════════════════════════════════════════════
-- OnRamp additions — run in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Officer roles table (supports multiple roles per member) ──
CREATE TABLE IF NOT EXISTS officer_roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  role_title  TEXT NOT NULL,  -- 'Pres' | 'VPE' | 'VPM' | 'VPPR' | 'Sec' | 'Trea' | 'SAA'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (role_title)  -- one person per title at a time
);

ALTER TABLE officer_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "officer_roles_select" ON officer_roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "officer_roles_insert" ON officer_roles FOR INSERT TO authenticated WITH CHECK (is_admin());
CREATE POLICY "officer_roles_update" ON officer_roles FOR UPDATE TO authenticated USING (is_admin());
CREATE POLICY "officer_roles_delete" ON officer_roles FOR DELETE TO authenticated USING (is_admin());

-- ── 2. Meeting attendance tracking ──────────────────────────────
CREATE TABLE IF NOT EXISTS meeting_attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id  UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  member_id   UUID REFERENCES members(id) ON DELETE CASCADE,  -- null = guest
  guest_name  TEXT,   -- for non-members
  guest_email TEXT,
  attended    BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (meeting_id, member_id)
);

ALTER TABLE meeting_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "attendance_select" ON meeting_attendance FOR SELECT TO authenticated USING (true);
CREATE POLICY "attendance_insert" ON meeting_attendance FOR INSERT TO authenticated WITH CHECK (is_admin() OR (SELECT role FROM members WHERE id = auth.uid()) IN ('admin','officer','vpe','secretary'));
CREATE POLICY "attendance_update" ON meeting_attendance FOR UPDATE TO authenticated USING (is_admin() OR (SELECT role FROM members WHERE id = auth.uid()) IN ('admin','officer','vpe','secretary'));
CREATE POLICY "attendance_delete" ON meeting_attendance FOR DELETE TO authenticated USING (is_admin());

-- ── 3. Reconciliation columns on meeting_roles and speaker_slots ─
ALTER TABLE meeting_roles ADD COLUMN IF NOT EXISTS confirmed BOOLEAN DEFAULT NULL;
-- null = unconfirmed, true = attended/delivered, false = no-show

ALTER TABLE speaker_slots ADD COLUMN IF NOT EXISTS confirmed BOOLEAN DEFAULT NULL;
-- null = unconfirmed, true = speech delivered, false = did not speak

-- ── 4. Add 'vpe' and 'secretary' to members role check ──────────
ALTER TABLE members DROP CONSTRAINT IF EXISTS members_role_check;
ALTER TABLE members ADD CONSTRAINT members_role_check
  CHECK (role IN ('member', 'officer', 'vpe', 'secretary', 'admin'));
