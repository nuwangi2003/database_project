-- Admin

CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'admin'@'localhost' WITH GRANT OPTION;

-- Dean


CREATE USER 'dean'@'localhost' IDENTIFIED BY 'Dean@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'dean'@'localhost';

--- Lecture

CREATE USER 'lecturer'@'localhost' IDENTIFIED BY 'Lecturer@123';
GRANT ALL PRIVILEGES ON db_project.* TO 'lecturer'@'localhost';
GRANT CREATE USER ON *.* TO 'lecturer'@'localhost';


--Technical Officer

CREATE USER 'technical_officer'@'localhost' IDENTIFIED BY 'Tech@123';

GRANT SELECT, INSERT, UPDATE ON db_project.attendance TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.session TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student TO 'technical_officer'@'localhost';

GRANT SELECT, INSERT, UPDATE ON db_project.attendance_detailed TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.attendance_combined TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student_attendance_summary TO 'technical_officer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON db_project.student_attendance_details TO 'technical_officer'@'localhost';




-- Student
CREATE USER 'student'@'localhost' IDENTIFIED BY 'Student@123';

GRANT SELECT ON db_project.marks TO 'student'@'localhost';
GRANT SELECT ON db_project.result TO 'student'@'localhost';
GRANT SELECT ON db_project.student_results TO 'student'@'localhost';
GRANT SELECT ON db_project.semester_pass_fail TO 'student'@'localhost';
GRANT SELECT ON db_project.student_class TO 'student'@'localhost';
GRANT SELECT ON db_project.v_progressive_cgpa TO 'student'@'localhost';
GRANT SELECT ON db_project.batch_department_marks TO 'student'@'localhost';


