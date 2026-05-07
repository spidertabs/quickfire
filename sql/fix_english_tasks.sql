-- Ensure the student is enrolled in English Language Skills (UCC1101)
INSERT INTO course_enrollments (student_id, course_id, academic_year, semester)
SELECT s.id, c.id, 2026, 1
FROM students s, courses c
WHERE s.registration_number = 'KIU/2020/1001'
  AND c.code = 'UCC1101'
ON CONFLICT (student_id, course_id, academic_year, semester) DO NOTHING;

-- Create a dummy assessment for English Language Skills if it doesn't exist
INSERT INTO quickfire_assessments (course_id, lecturer_id, title, description, duration_minutes, is_active)
SELECT 
    c.id, 
    (SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug' LIMIT 1), 
    'Grammar and Composition Quiz', 
    'A quick assessment on English grammar and essay structure.', 
    45, 
    TRUE
FROM courses c
WHERE c.code = 'UCC1101'
  AND NOT EXISTS (
      SELECT 1 FROM quickfire_assessments qa 
      WHERE qa.course_id = c.id AND qa.title = 'Grammar and Composition Quiz'
  )
RETURNING id;

-- Add a sample question to this assessment
INSERT INTO quickfire_questions (assessment_id, question_text, question_type, options, correct_answer, marks)
SELECT 
    id, 
    'Which of the following is a proper noun?', 
    'multiple_choice', 
    '["city", "country", "London", "street"]'::jsonb, 
    'London', 
    5
FROM quickfire_assessments
WHERE title = 'Grammar and Composition Quiz'
ON CONFLICT DO NOTHING;
