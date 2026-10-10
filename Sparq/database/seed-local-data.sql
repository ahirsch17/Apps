-- Seed data for local development
-- Run AFTER schema is created: sqlcmd -i azure-sql-schema.sql
-- This script uses same INSERT methods production will use

-- DO NOT include this in production deployment!
-- Production data comes from:
-- 1. VT SSO integration (real students)
-- 2. Canvas API sync (real courses)
-- 3. Admin dashboard (real events)

-- ========================================
-- 1. Create VT School
-- ========================================
INSERT INTO schools (id, name, email_domain, timezone)
VALUES ('vt', 'Virginia Tech', 'vt.edu', 'America/New_York');

-- ========================================
-- 2. Create Course Sections
-- ========================================
INSERT INTO sections (section_id, school_id, canonical_course_id, course_code, course_name, section_label, meeting_days, start_time, end_time, location)
VALUES
('CS2114-001', 'vt', 'CSE-1002', 'CS 2114', 'Software Design & Data Structures', '001', '["Mon","Wed","Fri"]', '09:00', '09:50', 'McBryde Hall'),
('CS2114-002', 'vt', 'CSE-1002', 'CS 2114', 'Software Design & Data Structures', '002', '["Mon","Wed","Fri"]', '10:00', '10:50', 'McBryde Hall'),
('CS3214-001', 'vt', 'CSE-1004', 'CS 3214', 'Computer Systems', '001', '["Mon","Wed"]', '14:00', '15:15', 'Torgersen Hall'),
('CS3214-002', 'vt', 'CSE-1004', 'CS 3214', 'Computer Systems', '002', '["Mon","Wed"]', '15:30', '16:45', 'Torgersen Hall'),
('MATH2204-001', 'vt', 'CSE-1006', 'MATH 2204', 'Linear Algebra', '001', '["Mon","Wed","Fri"]', '11:00', '11:50', 'Derring Hall');

-- ========================================
-- 3. Create Test Students
-- (In production: comes from VT SSO)
-- ========================================
INSERT INTO students (id, school_id, name, email, year, major, privacy_share_schedule, privacy_share_class_details)
VALUES
('stu-alex', 'vt', 'Alex Hirsch', 'alex.hirsch@vt.edu', 'Senior', 'CS', 'full', 1),
('stu-john', 'vt', 'John Martinez', 'john.martinez@vt.edu', 'Senior', 'CS', 'full', 1),
('stu-rachel', 'vt', 'Rachel Chen', 'rachel.chen@vt.edu', 'Junior', 'CS', 'full', 1),
('stu-sarah', 'vt', 'Sarah Kim', 'sarah.kim@vt.edu', 'Sophomore', 'BIT', 'full', 1);

-- ========================================
-- 4. Enroll Students in Sections
-- (In production: comes from Canvas API)
-- ========================================
INSERT INTO enrollments (student_id, section_id)
VALUES
('stu-alex', 'CS2114-001'),
('stu-alex', 'CS3214-001'),
('stu-alex', 'MATH2204-001'),
('stu-john', 'CS2114-001'),
('stu-john', 'CS3214-002'),
('stu-rachel', 'CS3214-002'),
('stu-rachel', 'MATH2204-001'),
('stu-sarah', 'CS2114-001');

-- ========================================
-- 5. Create Friendships
-- (In production: users send via app)
-- ========================================
INSERT INTO friendships (student_a, student_b, status)
VALUES
('stu-alex', 'stu-john', 'accepted'),
('stu-alex', 'stu-rachel', 'accepted'),
('stu-alex', 'stu-sarah', 'accepted');

-- ========================================
-- 6. Create Interests
-- (In production: admin adds via dashboard)
-- ========================================
INSERT INTO interests (id, school_id, name, icon)
VALUES
('int-volleyball', 'vt', 'Volleyball', 'sportscourt.fill'),
('int-soccer', 'vt', 'Soccer', 'soccerball'),
('int-basketball', 'vt', 'Basketball', 'basketball.fill'),
('int-study', 'vt', 'Study groups', 'book.fill');

-- ========================================
-- 7. Create Campus Events
-- (In production: admin adds via dashboard)
-- ========================================
INSERT INTO campus_events (id, school_id, interest_id, title, description, location, start_time, end_time, matching_kind, is_recurring, recurrence_label)
VALUES
('evt-vb-im', 'vt', 'int-volleyball', 'IM Volleyball - Open Gym', 'Drop-in at War Memorial. All skill levels.', 'War Memorial Gym', '2026-07-29 18:00:00', '2026-07-29 20:00:00', 'partner', 1, 'Every Wednesday'),
('evt-soccer-pickup', 'vt', 'int-soccer', 'Saturday Night Pickup Soccer', 'Casual game on the Drillfield.', 'Drillfield', '2026-07-30 20:00:00', '2026-07-30 22:00:00', 'newcomer', 1, 'Every Saturday night');

-- ========================================
-- 8. Opt-in to Events
-- (In production: users tap "I'm interested")
-- ========================================
INSERT INTO event_participations (event_id, student_id, kind)
VALUES
('evt-vb-im', 'stu-alex', 'interested'),
('evt-vb-im', 'stu-john', 'lookingForPartner'),
('evt-soccer-pickup', 'stu-rachel', 'interested');

-- ========================================
-- 9. Create Partner Profiles
-- (In production: created via API when user taps "Looking for partner")
-- ========================================
INSERT INTO partner_profiles (event_id, student_id, display_name, year, experience_note, looking_note)
VALUES
('evt-vb-im', 'stu-john', 'John', 'Senior', 'Intermediate', 'Need a setter for IM team');

-- ========================================
-- VERIFY DATA
-- ========================================
SELECT 'Schools' as entity, COUNT(*) as count FROM schools
UNION ALL
SELECT 'Students', COUNT(*) FROM students
UNION ALL
SELECT 'Sections', COUNT(*) FROM sections
UNION ALL
SELECT 'Enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'Friendships', COUNT(*) FROM friendships
UNION ALL
SELECT 'Interests', COUNT(*) FROM interests
UNION ALL
SELECT 'Events', COUNT(*) FROM campus_events;
