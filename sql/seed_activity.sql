-- Seed some recent activity (attempts) for the test student
INSERT INTO quickfire_attempts (student_id, assessment_id, status, started_at, submitted_at, total_score)
SELECT 
    s.id, 
    a.id, 
    'submitted', 
    NOW() - INTERVAL '1 day', 
    NOW() - INTERVAL '23 hours', 
    85
FROM students s, quickfire_assessments a
WHERE s.registration_number = 'KIU/2020/1001'
  AND a.title = 'Quiz 1: Network Basics'
ON CONFLICT DO NOTHING;

INSERT INTO quickfire_attempts (student_id, assessment_id, status, started_at)
SELECT 
    s.id, 
    a.id, 
    'in_progress', 
    NOW() - INTERVAL '2 hours'
FROM students s, quickfire_assessments a
WHERE s.registration_number = 'KIU/2020/1001'
  AND a.title = 'Quiz 2: Database Design'
ON CONFLICT DO NOTHING;
