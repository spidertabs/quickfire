-- Grant read permissions on assessments to students
GRANT SELECT ON public.quickfire_assessments TO anon, authenticated;
GRANT SELECT ON public.quickfire_questions   TO anon, authenticated;
GRANT SELECT ON public.courses               TO anon, authenticated;

-- Ensure RLS doesn't block active assessments
DROP POLICY IF EXISTS "anon_read_active_assessments" ON quickfire_assessments;
CREATE POLICY "anon_read_active_assessments"
    ON quickfire_assessments FOR SELECT
    TO anon, authenticated
    USING (is_active = TRUE);

-- Also allow reading questions for those assessments
DROP POLICY IF EXISTS "anon_read_questions" ON quickfire_questions;
CREATE POLICY "anon_read_questions"
    ON quickfire_questions FOR SELECT
    TO anon, authenticated
    USING (TRUE);
