-- ==============================
-- MySQL User Accounts for DB
-- ==============================

-- 1) Admin: Full privileges with GRANT OPTION
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'admin'@'localhost' WITH GRANT OPTION;

-- 2) Dean: Full privileges without GRANT OPTION
CREATE USER 'dean'@'localhost' IDENTIFIED BY 'Dean@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'dean'@'localhost';

-- 3) Lecturer: Full privileges on all tables, can create users
CREATE USER 'lecturer'@'localhost' IDENTIFIED BY 'Lecturer@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'lecturer'@'localhost';
GRANT CREATE USER ON *.* TO 'lecturer'@'localhost';

-- 4) Technical Officer: Read, write, update permissions on attendance-related tables/views
CREATE USER 'technical_officer'@'localhost' IDENTIFIED BY 'Tech@123';

GRANT SELECT, INSERT, UPDATE ON db_project.attendance TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.session TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student TO 'technical_officer'@'localhost';

GRANT SELECT, INSERT, UPDATE ON db_project.attendance_detailed TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.attendance_combined TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student_attendance_summary TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student_attendance_details TO 'technical_officer'@'localhost';

-- 5) Student: Read-only permission for final attendance and marks/grades tables/views
CREATE USER 'student'@'localhost' IDENTIFIED BY 'Student@123';

-- Attendance views
GRANT SELECT ON db_project.attendance_detailed TO 'student'@'localhost';
GRANT SELECT ON db_project.attendance_combined TO 'student'@'localhost';
GRANT SELECT ON db_project.student_attendance_summary TO 'student'@'localhost';
GRANT SELECT ON db_project.student_attendance_details TO 'student'@'localhost';

-- Marks & results views
GRANT SELECT ON db_project.student_results TO 'student'@'localhost';
GRANT SELECT ON db_project.semester_pass_fail TO 'student'@'localhost';
GRANT SELECT ON db_project.student_class TO 'student'@'localhost';
GRANT SELECT ON db_project.v_progressive_cgpa TO 'student'@'localhost';

-- Batch & overall summaries (optional for student view)
GRANT SELECT ON db_project.batch_department_marks TO 'student'@'localhost';
GRANT SELECT ON db_project.batch_marks_summary TO 'student'@'localhost';
GRANT SELECT ON db_project.student_marks_summary TO 'student'@'localhost';
GRANT SELECT ON db_project.student_overall_eligibility TO 'student'@'localhost';
GRANT SELECT ON db_project.batch_overall_eligibility TO 'student'@'localhost';

FLUSH PRIVILEGES;
