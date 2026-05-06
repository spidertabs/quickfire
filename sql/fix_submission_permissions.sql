-- Grant full permissions on attempts and answers to students
GRANT ALL ON public.quickfire_attempts TO anon, authenticated;
GRANT ALL ON public.quickfire_answers  TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Double check policies
DROP POLICY IF EXISTS "anon_manage_attempts" ON quickfire_attempts;
CREATE POLICY "anon_manage_attempts"
    ON quickfire_attempts FOR ALL
    TO anon, authenticated
    USING (TRUE)
    WITH CHECK (TRUE);

DROP POLICY IF EXISTS "anon_manage_answers" ON quickfire_answers;
CREATE POLICY "anon_manage_answers"
    ON quickfire_answers FOR ALL
    TO anon, authenticated
    USING (TRUE)
    WITH CHECK (TRUE);
