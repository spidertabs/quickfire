-- Seed sample notifications for the test student
INSERT INTO notifications (student_id, type, title, message, priority)
SELECT id, 'general', 'Welcome to Quickfire!', 'Explore your dashboard to see active assessments and enroll in new courses.', 'low'
FROM students WHERE registration_number = 'KIU/2020/1001'
ON CONFLICT DO NOTHING;

INSERT INTO notifications (student_id, type, title, message, priority)
SELECT id, 'approval_required', 'Course Enrolled Successfully', 'You have been enrolled in CSC1101 Introduction to Computer Science.', 'medium'
FROM students WHERE registration_number = 'KIU/2020/1001'
ON CONFLICT DO NOTHING;
