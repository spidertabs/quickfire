-- ============================================================
--  UPDATED DIAGNOSTIC & FIX SCRIPT
--  Run this in the Supabase SQL Editor
-- ============================================================

-- 1. Ensure pgcrypto is enabled (it might be in 'extensions' schema)
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

-- 2. Update fn_student_login to see the extensions schema
-- (This replaces the old version that was missing the search_path)
CREATE OR REPLACE FUNCTION public.fn_student_login(
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

-- 3. Reset password for test accounts
UPDATE students 
SET password_hash = extensions.crypt('uems@2026', extensions.gen_salt('bf', 12))
WHERE registration_number IN ('KIU/2024/0001', 'KIU/2020/1001');

-- 4. Final verification
SELECT * FROM fn_student_login('KIU/2020/1001', 'uems@2026');
