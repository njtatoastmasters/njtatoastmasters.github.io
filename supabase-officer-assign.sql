-- ═══════════════════════════════════════════════════════════════
-- OnRamp — Allow officers (not just admins) to assign members
-- Run in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════
-- Change 3: officers can sign members up for roles and speaker slots
-- on their behalf. Existing policies only allowed a user to insert
-- their OWN sign-up (member_id = auth.uid) unless they were admin.
-- We extend the "or admin" part to "or officer-or-admin".
--
-- Relies on is_officer() from supabase-rls-hardening.sql, which
-- returns true for role IN ('officer','admin').
-- ═══════════════════════════════════════════════════════════════

-- Meeting roles: allow self, officers, or admins to insert
DROP POLICY IF EXISTS "roles_insert" ON meeting_roles;
CREATE POLICY "roles_insert" ON meeting_roles
  FOR INSERT TO authenticated
  WITH CHECK (member_id = auth.uid() OR is_officer());

-- Meeting roles: allow officers/admins to delete any (e.g. fix a mistaken assignment)
DROP POLICY IF EXISTS "roles_delete" ON meeting_roles;
CREATE POLICY "roles_delete" ON meeting_roles
  FOR DELETE TO authenticated
  USING (member_id = auth.uid() OR is_officer());

-- Speaker slots: allow self, officers, or admins to update (claim/assign)
DROP POLICY IF EXISTS "slots_update" ON speaker_slots;
CREATE POLICY "slots_update" ON speaker_slots
  FOR UPDATE TO authenticated
  USING (member_id = auth.uid() OR member_id IS NULL OR is_officer())
  WITH CHECK (member_id = auth.uid() OR member_id IS NULL OR is_officer());

-- Speeches: allow self, officers, or admins to insert
DROP POLICY IF EXISTS "speeches_insert" ON speeches;
CREATE POLICY "speeches_insert" ON speeches
  FOR INSERT TO authenticated
  WITH CHECK (member_id = auth.uid() OR is_officer());
