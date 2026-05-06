-- ============================================================
--  STUDENT ENROLLMENT TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS student_enrollments (
    id          SERIAL      PRIMARY KEY,
    student_id  INT         NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    course_id   INT         NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, course_id)
);

-- RLS for student_enrollments
ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_manage_enrollments" 
    ON student_enrollments FOR ALL 
    TO anon, authenticated 
    USING (TRUE);

-- Seed initial enrollments for test students if they exist
-- John Mukasa (id=1 usually if seeded first)
INSERT INTO student_enrollments (student_id, course_id)
SELECT s.id, c.id 
FROM students s, courses c
WHERE s.registration_number = 'KIU/2020/1001'
  AND c.code IN ('CSC1101', 'BIT1102')
ON CONFLICT DO NOTHING;
