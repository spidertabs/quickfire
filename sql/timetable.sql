-- ============================================================
--  UEMS-PHD-VV — Regenerated Exam Timetable & Enrollment Seed Data
-- ============================================================

-- 1. Published Exam Papers (Initial Set)
INSERT INTO exam_papers (paper_code, course_id, created_by, exam_type, academic_year, semester, exam_date, duration, total_marks, status, published_at) VALUES
('EP-MIS2101-2026', 15, 31, 'FINAL', 2026, 1, '2026-05-15', 180, 100, 'published', NOW()),
('EP-CS2105-2026', 21, 30, 'FINAL', 2026, 1, '2026-05-16', 180, 100, 'published', NOW()),
('EP-LAW3101-2026', 19, 29, 'FINAL', 2026, 1, '2026-05-18', 180, 100, 'published', NOW()),
('EP-PH3102-2026', 22, 33, 'FINAL', 2026, 1, '2026-05-20', 180, 100, 'published', NOW()),
('EP-BSE1203-2026', 4, 32, 'CAT',   2026, 1, '2026-05-21', 120, 50,  'published', NOW())
ON CONFLICT (paper_code) DO NOTHING;

-- 2. Timetable Slots
-- Insert slots for published papers (using NOT EXISTS to avoid constraint issues)
INSERT INTO exam_timetables (exam_paper_id, course_id, exam_date, start_time, end_time, venue, capacity, created_by)
SELECT 
    ep.id as exam_paper_id,
    ep.course_id as course_id,
    ep.exam_date,
    '09:00:00', '12:00:00',
    'Complex Room ' || (ep.id % 5 + 1),
    150, ep.created_by
FROM exam_papers ep
WHERE NOT EXISTS (
    SELECT 1 FROM exam_timetables et WHERE et.exam_paper_id = ep.id
);

-- ADD SLOTS FOR COURSES WITHOUT PUBLISHED PAPERS
INSERT INTO exam_timetables (course_id, exam_date, start_time, end_time, venue, capacity, created_by)
VALUES 
(11, '2026-06-01', '14:00:00', '17:00:00', 'University Auditorium', 500, 1),
(8,  '2026-06-02', '09:00:00', '12:00:00', 'Exhibition Hall B', 200, 1),
(14, '2026-06-03', '14:00:00', '17:00:00', 'Science Lab 4', 40, 1);

-- 3. Student Course Enrollments (Bulk Sample)
INSERT INTO course_enrollments (student_id, course_id, academic_year, semester)
SELECT s.id, c.id, 2026, 1
FROM students s, courses c
WHERE (
    (s.department_id = 15 AND c.id = 15) OR
    (s.department_id = 14 AND c.id = 21) OR
    (s.department_id = 10 AND c.id = 19) OR
    (s.department_id = 16 AND c.id = 4) OR
    (s.department_id = 22 AND c.id = 22) OR
    (s.study_year = 1 AND c.id = 5)
)
AND s.is_active = TRUE
LIMIT 100
ON CONFLICT DO NOTHING;

-- 4. Sample Supervisor Assignments (Invigilators)
INSERT INTO exam_supervisors (timetable_id, lecturer_id)
SELECT t.id, l.id
FROM exam_timetables t, staff l
WHERE l.role = 'lecturer'
AND l.is_active = TRUE
AND NOT EXISTS (
    SELECT 1 FROM exam_supervisors es WHERE es.timetable_id = t.id AND es.lecturer_id = l.id
)
LIMIT 50;
