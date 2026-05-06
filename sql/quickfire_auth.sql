-- ============================================================
--  QUICKFIRE — Authentication Fix
--  Run this in Supabase SQL Editor (Dashboard → SQL Editor)
--  Kampala International University | © 2026 Spider Tabs Ltd
-- ============================================================

-- ============================================================
--  STEP 1: Enable pgcrypto (needed for crypt() / bcrypt verify)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
--  STEP 2: RLS — allow anonymous clients to call SELECT on
--           students ONLY via the login RPC below (not directly).
--           We block direct table access and use the RPC instead.
-- ============================================================

-- Enable RLS on students (Supabase enables this by default, but
-- make it explicit):
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- No direct SELECT policy for anon on `students`.
-- All access goes through the security-definer RPC below.


-- ============================================================
--  STEP 3: RPC — fn_student_login
--  Called by the Flutter app. Uses SECURITY DEFINER so it can
--  bypass RLS and read the password_hash safely.
--  Returns the student row (minus password_hash) if credentials
--  are correct, or an empty result set on failure.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_student_login(
    p_reg_no  TEXT,
    p_password TEXT
)
RETURNS TABLE (
    id                  INT,
    registration_number TEXT,
    first_name          TEXT,
    last_name           TEXT,
    email               TEXT,
    programme_id        INT,
    college_id          INT,
    department_id       INT,
    study_year          SMALLINT,
    semester            SMALLINT,
    is_active           BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.registration_number::TEXT,
        s.first_name::TEXT,
        s.last_name::TEXT,
        s.email::TEXT,
        s.programme_id,
        s.college_id,
        s.department_id,
        s.study_year,
        s.semester,
        s.is_active
    FROM students s
    WHERE s.registration_number = p_reg_no
      AND s.is_active = TRUE
      AND s.deleted_at IS NULL
      AND s.password_hash = crypt(p_password, s.password_hash::TEXT);
END;
$$;

-- Grant execute to the anon and authenticated roles
GRANT EXECUTE ON FUNCTION fn_student_login(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION fn_student_login(TEXT, TEXT) TO authenticated;


-- ============================================================
--  STEP 4: Allow anon to read quickfire_assessments (for home
--           screen listing) and related tables.
--  These tables don't contain sensitive data.
-- ============================================================

ALTER TABLE quickfire_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE quickfire_questions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE quickfire_attempts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE quickfire_answers     ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses               ENABLE ROW LEVEL SECURITY;

-- Public read for assessments & questions (anon can list them)
CREATE POLICY "anon_read_active_assessments"
    ON quickfire_assessments FOR SELECT
    TO anon, authenticated
    USING (is_active = TRUE);

CREATE POLICY "anon_read_questions"
    ON quickfire_questions FOR SELECT
    TO anon, authenticated
    USING (TRUE);

-- Courses: anon read (needed for embedded joins)
CREATE POLICY "anon_read_courses"
    ON courses FOR SELECT
    TO anon, authenticated
    USING (TRUE);

-- Colleges: anon read (needed for report headers)
CREATE POLICY "anon_read_colleges"
    ON colleges FOR SELECT
    TO anon, authenticated
    USING (TRUE);

-- Attempts: anon can read/insert/update their own attempt
-- (student_id matches; enforced app-side since we don't have
--  JWT auth — a proper production system would use Supabase Auth)
CREATE POLICY "anon_manage_attempts"
    ON quickfire_attempts FOR ALL
    TO anon, authenticated
    USING (TRUE);

CREATE POLICY "anon_manage_answers"
    ON quickfire_answers FOR ALL
    TO anon, authenticated
    USING (TRUE);


-- ============================================================
--  VERIFICATION QUERY — run this to confirm it works:
-- ============================================================
-- SELECT * FROM fn_student_login('KIU/2024/0001', 'uems@2026');
-- Expected: one row with Michael Kato's details
