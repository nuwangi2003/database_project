--db_name
CREATE DATABASE IF NOT EXISTS db_project;
USE db_project;


CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    role ENUM('Admin', 'Dean', 'Lecturer', 'Tech_Officer', 'Student') NOT NULL
);


CREATE TABLE IF NOT EXISTS department (
    department_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    faculty_name VARCHAR(100)
);


CREATE TABLE IF NOT EXISTS student (
    user_id VARCHAR(10) PRIMARY KEY,
    reg_no VARCHAR(15) UNIQUE NOT NULL,
    batch VARCHAR(10),
    department_id VARCHAR(10),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS lecture (
    user_id VARCHAR(10) PRIMARY KEY,
    specialization VARCHAR(50),
    designation VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS dean (
    lecture_id VARCHAR(10) PRIMARY KEY,
    term_start DATE NOT NULL,
    term_end DATE,
    FOREIGN KEY (lecture_id) REFERENCES lecture(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS tech_officer (
    user_id VARCHAR(10) PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS course (
    course_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    credit INT NOT NULL,
    academic_year INT CHECK (academic_year BETWEEN 1 AND 4),
    semester ENUM('1', '2') NOT NULL,
    total_hours DECIMAL(5,2) DEFAULT 50.00,
    weekly_hours DECIMAL(4,2) DEFAULT 3.00
);


CREATE TABLE IF NOT EXISTS session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id VARCHAR(10) NOT NULL,
    session_date DATE NOT NULL,
    session_hours DECIMAL(4,2) DEFAULT 3.00,
    type ENUM('Theory', 'Practical') DEFAULT 'Theory',
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    session_id INT NOT NULL,
    status ENUM('Present', 'Absent') NOT NULL,
    medical BOOLEAN DEFAULT FALSE,
    hours_attended DECIMAL(4,2) DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (session_id) REFERENCES session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS marks (
    marks_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    course_id VARCHAR(10) NOT NULL,
    quiz1_marks DECIMAL(5,2) CHECK (quiz1_marks BETWEEN 0 AND 100),
    quiz2_marks DECIMAL(5,2) CHECK (quiz2_marks BETWEEN 0 AND 100),
    quiz3_marks DECIMAL(5,2) CHECK (quiz3_marks BETWEEN 0 AND 100),
    assessment_marks DECIMAL(5,2) CHECK (assessment_marks BETWEEN 0 AND 100),
    mid_marks DECIMAL(5,2) CHECK (mid_marks BETWEEN 0 AND 100),
    final_theory DECIMAL(5,2) CHECK (final_theory BETWEEN 0 AND 100),
    final_practical DECIMAL(5,2) CHECK (final_practical BETWEEN 0 AND 100),
    ca_marks DECIMAL(5,2),                                                       
    final_marks DECIMAL(5,2),                                                     
    ca_eligible ENUM('Eligible','Not Eligible','MC','WH') DEFAULT 'Not Eligible',
    final_eligible ENUM('Eligible','Not Eligible','MC','WH','E*') DEFAULT 'Not Eligible',
    grade CHAR(10),
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS medical (
    medical_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    course_id VARCHAR(10),
    exam_type ENUM( 'Mid', 'Final', 'Attendance') NOT NULL,
    date_submitted DATE NOT NULL,
    status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS result (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    academic_year INT CHECK (academic_year BETWEEN 1 AND 4),
    semester ENUM('1','2') NOT NULL,
    sgpa VARCHAR(10) ,
    cgpa VARCHAR(10),
    total_credits INT DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS student_course (
    student_id VARCHAR(10),
    course_id VARCHAR(10),
    status ENUM('Proper', 'Repeat', 'Suspended') DEFAULT 'Proper',
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS lecture_course (
    lecture_id VARCHAR(10),
    course_id VARCHAR(10),
    PRIMARY KEY (lecture_id, course_id),
    FOREIGN KEY (lecture_id) REFERENCES lecture(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS lecture_department (
    lecture_id VARCHAR(10),
    department_id VARCHAR(10),
    PRIMARY KEY (lecture_id, department_id),
    FOREIGN KEY (lecture_id) REFERENCES lecture(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS department_course (
    department_id VARCHAR(10),
    course_id VARCHAR(10),
    PRIMARY KEY (department_id, course_id),
    FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ==============================
-- Attendance Triggers
-- ==============================
DELIMITER $$

CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT s.session_hours, sc.status
    INTO sessionHours, student_status
    FROM session s
    JOIN student_course sc
        ON sc.student_id = NEW.student_id AND sc.course_id = s.course_id
    WHERE s.session_id = NEW.session_id
    LIMIT 1;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s2 ON s2.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.exam_type = 'Attendance'
                  AND m.course_id = s2.course_id
                  AND m.date_submitted = s2.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$


CREATE TRIGGER trg_attendance_before_update
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT s.session_hours, sc.status
    INTO sessionHours, student_status
    FROM session s
    JOIN student_course sc
        ON sc.student_id = NEW.student_id AND sc.course_id = s.course_id
    WHERE s.session_id = NEW.session_id
    LIMIT 1;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s2 ON s2.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.exam_type = 'Attendance'
                  AND m.course_id = s2.course_id
                  AND m.date_submitted = s2.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


-- ==============================
-- CA Marks Calculation
-- ==============================
DELIMITER $$

CREATE TRIGGER trg_ca_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE a,b,c,best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c);
    SET NEW.ca_marks = ROUND((best_two_sum/2*0.10)+ IFNULL(NEW.assessment_marks,0)*0.15+ IFNULL(NEW.mid_marks,0)*0.15,2);
END$$


CREATE TRIGGER trg_ca_marks_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE a,b,c,best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c);
    SET NEW.ca_marks = ROUND((best_two_sum/2*0.10)
+ IFNULL(NEW.assessment_marks,0)*0.15+ IFNULL(NEW.mid_marks,0)*0.15,2);
END$$

DELIMITER ;


-- ==================================================
-- Final(CA,Final,Attendence) Eligibility Triggers
-- ==================================================


DELIMITER $$

CREATE TRIGGER trg_marks_eligibility_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med, final_med INT DEFAULT 0;

    SELECT sc.status INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    SELECT attendance_percentage INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id AND exam_type = 'Mid' AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    AND exam_type = 'Final' AND status = 'Approved';

    -- CA eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF mid_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSEIF IFNULL(NEW.ca_marks,0) < 20 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -- Final eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF student_status = 'Repeat' THEN
        SET NEW.final_eligible = 'Eligible'; -- Attendance not considered for repeat
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    -- Final marks
    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)+ IFNULL(NEW.ca_marks,0),2);
END$$


CREATE TRIGGER trg_marks_eligibility_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med, final_med INT DEFAULT 0;

    SELECT sc.status INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    SELECT attendance_percentage INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    AND exam_type = 'Mid' AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id AND exam_type = 'Final' AND status = 'Approved';

    -- CA eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF mid_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSEIF IFNULL(NEW.ca_marks,0) < 20 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -- Final eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF student_status = 'Repeat' THEN
        SET NEW.final_eligible = 'Eligible'; -- Attendance ignored
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)+ IFNULL(NEW.ca_marks,0),2);
END$$

DELIMITER ;


-- Before inser data once read the Documentation file
-- ===============================================================
-- Data for Users Table
-- ===============================================================


INSERT INTO users (user_id, name, email, password, role) VALUES
('U001','Admin Kumara','admin@uni.lk','1234','Admin'),
('U002','Dean Lakmal','dean@uni.lk','1234','Dean'),
('U003','Dr. Amal Perera','amal.perera@uni.lk','1234','Lecturer'),
('U004','Ms. Nadeesha Silva','nadeesha.silva@uni.lk','1234','Lecturer'),
('U005','Dr. Kasun Fernando','kasun.fernando@uni.lk','1234','Lecturer'),
('U006','Mr. Thilina Jayasuriya','thilina.jayasuriya@uni.lk','1234','Lecturer'),
('U007','Ms. Chamari Ratnayake','chamari.ratnayake@uni.lk','1234','Lecturer'),
('U008','TechOfficer1','to1@uni.lk','1234','Tech_Officer'),
('U009','TechOfficer2','to2@uni.lk','1234','Tech_Officer'),
('U010','TechOfficer3','to3@uni.lk','1234','Tech_Officer'),
('U011','TechOfficer4','to4@uni.lk','1234','Tech_Officer'),
('U012','TechOfficer5','to5@uni.lk','1234','Tech_Officer'),
('U013','Sahan Wijesinghe','sahan.w@uni.lk','1234','Student'),
('U014','Dinuka Perera','dinuka.p@uni.lk','1234','Student'),
('U015','Chamod Fernando','chamod.f@uni.lk','1234','Student'),
('U016','Nadeesha Jayawardena','nadeesha.j@uni.lk','1234','Student'),
('U017','Kasun Senanayake','kasun.s@uni.lk','1234','Student'),
('U018','Thilini Amarasinghe','thilini.a@uni.lk','1234','Student'),
('U019','Sanduni Wijeratne','sanduni.w@uni.lk','1234','Student'),
('U020','Heshan Silva','heshan.s@uni.lk','1234','Student'),
('U021','Pubudu Rajapaksa','pubudu.r@uni.lk','1234','Student'),
('U022','Dilani Kumari','dilani.k@uni.lk','1234','Student'),
('U023','Ravindu Perera','ravindu.p@uni.lk','1234','Student'),
('U024','Chamari de Silva','chamari.d@uni.lk','1234','Student'),
('U025','Dulan Fernando','dulan.f@uni.lk','1234','Student'),
('U026','Nipun Jayasinghe','nipun.j@uni.lk','1234','Student'),
('U027','Harini Gunasekara','harini.g@uni.lk','1234','Student');




-- ================================================================
-- Data for Department Table
-- ===============================================================

INSERT INTO department (department_id, name, faculty_name) VALUES
('D001', 'Information and Communication Technology', 'Faculty of Technology'),
('D002', 'Engineering Technology', 'Faculty of Technology'),
('D003', 'Biosystems Technology', 'Faculty of Technology');


-- ==================================================================
-- Data for Lecture Table
-- ==================================================================


INSERT INTO lecture (user_id, specialization, designation) VALUES

('U003','Database Systems','Senior Lecturer'),
('U004','Web Development','Lecturer'),
('U005','Computer Networks','Senior Lecturer'),
('U006','Computer Architecture','Lecturer'),
('U007','Discrete Mathematics','Lecturer');

-- ==================================================================
-- Data for Student Table
-- ==================================================================
INSERT INTO student (user_id, reg_no, batch, department_id) VALUES
('U013','TG/2023/1701','2023','D001'),
('U014','TG/2023/1702','2023','D001'),
('U015','TG/2023/1703','2023','D001'),
('U016','TG/2023/1704','2023','D001'),
('U017','TG/2023/1705','2023','D001'),
('U018','TG/2023/1706','2023','D001'),
('U019','TG/2023/1707','2023','D001'),
('U020','TG/2023/1708','2023','D001'),
('U021','TG/2023/1709','2023','D001'),
('U022','TG/2023/1710','2023','D001'),
('U023','TG/2023/1711','2023','D001'),
('U024','TG/2023/1712','2023','D001'),
('U025','TG/2023/1713','2023','D001'),
('U026','TG/2023/1714','2023','D001'),
('U027','TG/2023/1715','2023','D001');


-- ==================================================================
-- Data for Dean Table
-- ==================================================================
INSERT INTO dean (lecture_id, term_start, term_end) VALUES
('U003','2025-01-01','2025-12-31');

-- ==================================================================
-- Data for Technical Officer Table
-- ==================================================================
INSERT INTO tech_officer (user_id) VALUES

('U008'),
('U009'),
('U010'),
('U011'),
('U012');


-- ==================================================================
-- Data for Course Table
-- ==================================================================

INSERT INTO course (course_id, name, credit, academic_year, semester, total_hours, weekly_hours) VALUES

('ICT1222','Database Management Systems',3,1,'1',90.00,6.00),
('ICT1233','Server Side Web Development',3,1,'1',90.00,6.00),
('ICT1242','Computer Architecture',3,1,'1',45.00,3.00),
('ICT1253','Computer Networks',3,1,'1',90.00,6.00),
('TCS1212','Fundamentals of Management',2,1,'1',30.00,2.00),
('TMS1233','Discrete Mathematics',3,1,'1',45.00,3.00);


-- ==================================================================
-- Data for Student_Course Table
-- ==================================================================


-- 10 Proper students (U013-U022): all subjects Proper
INSERT INTO student_course (student_id, course_id, status) VALUES
('U013','ICT1222','Proper'),('U013','ICT1233','Proper'),('U013','ICT1242','Proper'),('U013','ICT1253','Proper'),('U013','TCS1212','Proper'),('U013','TMS1233','Proper'),
('U014','ICT1222','Proper'),('U014','ICT1233','Proper'),('U014','ICT1242','Proper'),('U014','ICT1253','Proper'),('U014','TCS1212','Proper'),('U014','TMS1233','Proper'),
('U015','ICT1222','Proper'),('U015','ICT1233','Proper'),('U015','ICT1242','Proper'),('U015','ICT1253','Proper'),('U015','TCS1212','Proper'),('U015','TMS1233','Proper'),
('U016','ICT1222','Proper'),('U016','ICT1233','Proper'),('U016','ICT1242','Proper'),('U016','ICT1253','Proper'),('U016','TCS1212','Proper'),('U016','TMS1233','Proper'),
('U017','ICT1222','Proper'),('U017','ICT1233','Proper'),('U017','ICT1242','Proper'),('U017','ICT1253','Proper'),('U017','TCS1212','Proper'),('U017','TMS1233','Proper'),
('U018','ICT1222','Proper'),('U018','ICT1233','Proper'),('U018','ICT1242','Proper'),('U018','ICT1253','Proper'),('U018','TCS1212','Proper'),('U018','TMS1233','Proper'),
('U019','ICT1222','Proper'),('U019','ICT1233','Proper'),('U019','ICT1242','Proper'),('U019','ICT1253','Proper'),('U019','TCS1212','Proper'),('U019','TMS1233','Proper'),
('U020','ICT1222','Proper'),('U020','ICT1233','Proper'),('U020','ICT1242','Proper'),('U020','ICT1253','Proper'),('U020','TCS1212','Proper'),('U020','TMS1233','Proper'),
('U021','ICT1222','Proper'),('U021','ICT1233','Proper'),('U021','ICT1242','Proper'),('U021','ICT1253','Proper'),('U021','TCS1212','Proper'),('U021','TMS1233','Proper'),
('U022','ICT1222','Proper'),('U022','ICT1233','Proper'),('U022','ICT1242','Proper'),('U022','ICT1253','Proper'),('U022','TCS1212','Proper'),('U022','TMS1233','Proper');

-- 1 Suspended student (U027): all subjects Suspended
INSERT INTO student_course (student_id, course_id, status) VALUES
('U027','ICT1222','Suspended'),('U027','ICT1233','Suspended'),('U027','ICT1242','Suspended'),('U027','ICT1253','Suspended'),('U027','TCS1212','Suspended'),('U027','TMS1233','Suspended');

-- 5 Repeat students (U023-U026): repeat only specific subjects
INSERT INTO student_course (student_id, course_id, status) VALUES
-- U023 repeats ICT1242
('U023','ICT1222','Proper'),('U023','ICT1233','Proper'),('U023','ICT1242','Repeat'),('U023','ICT1253','Proper'),('U023','TCS1212','Proper'),('U023','TMS1233','Proper'),
-- U024 repeats ICT1233 & TCS1212
('U024','ICT1222','Proper'),('U024','ICT1233','Repeat'),('U024','ICT1242','Proper'),('U024','ICT1253','Proper'),('U024','TCS1212','Repeat'),('U024','TMS1233','Proper'),
-- U025 repeats  ICT1253
('U025','ICT1222','Proper'),('U025','ICT1233','Proper'),('U025','ICT1242','Proper'),('U025','ICT1253','Repeat'),('U025','TCS1212','Proper'),('U025','TMS1233','Proper'),
-- U026 repeats  ICT1253
('U026','ICT1222','Proper'),('U026','ICT1233','Proper'),('U026','ICT1242','Proper'),('U026','ICT1253','Repeat'),('U026','TCS1212','Proper'),('U026','TMS1233','Proper');





-- ================================================================
-- Data for Department_Course Table
-- ================================================================
INSERT INTO department_course (department_id, course_id) VALUES

('D001','ICT1222'),
('D001','ICT1233'),
('D001','ICT1242'),
('D001','ICT1253'),
('D001','TCS1212'),
('D001','TMS1233');


-- ================================================================
-- Data for Lecture_Course Table
-- ================================================================
INSERT INTO lecture_course (lecture_id, course_id) VALUES

('U003','ICT1222'),
('U004','ICT1233'),
('U006','ICT1242'),
('U005','ICT1253'),
('U007','TMS1233');


-- ================================================================
-- Data for Lecture_Department Table
-- ================================================================

INSERT INTO lecture_department (lecture_id, department_id) VALUES

('U003','D001'),
('U004','D001'),
('U005','D001'),
('U006','D001'),
('U007','D001');



-- ================================================================
-- Data for Session Table
-- ================================================================

INSERT INTO session (session_id, course_id, session_date, session_hours, type) VALUES

(1,'ICT1222','2025-02-03',3.00,'Theory'),
(2,'ICT1222','2025-02-10',3.00,'Theory'),
(3,'ICT1222','2025-02-17',3.00,'Theory'),
(4,'ICT1222','2025-02-24',3.00,'Theory'),
(5,'ICT1222','2025-03-03',3.00,'Theory'),
(6,'ICT1222','2025-03-10',3.00,'Theory'),
(7,'ICT1222','2025-03-17',3.00,'Theory'),
(8,'ICT1222','2025-03-24',3.00,'Theory'),
(9,'ICT1222','2025-03-31',3.00,'Theory'),
(10,'ICT1222','2025-04-07',3.00,'Theory'),
(11,'ICT1222','2025-04-14',3.00,'Theory'),
(12,'ICT1222','2025-04-21',3.00,'Theory'),
(13,'ICT1222','2025-04-28',3.00,'Theory'),
(14,'ICT1222','2025-05-05',3.00,'Theory'),
(15,'ICT1222','2025-05-12',3.00,'Theory'),
(16,'ICT1222','2025-02-04',3.00,'Practical'),
(17,'ICT1222','2025-02-11',3.00,'Practical'),
(18,'ICT1222','2025-02-18',3.00,'Practical'),
(19,'ICT1222','2025-02-25',3.00,'Practical'),
(20,'ICT1222','2025-03-04',3.00,'Practical'),
(21,'ICT1222','2025-03-11',3.00,'Practical'),
(22,'ICT1222','2025-03-18',3.00,'Practical'),
(23,'ICT1222','2025-03-25',3.00,'Practical'),
(24,'ICT1222','2025-04-01',3.00,'Practical'),
(25,'ICT1222','2025-04-08',3.00,'Practical'),
(26,'ICT1222','2025-04-15',3.00,'Practical'),
(27,'ICT1222','2025-04-22',3.00,'Practical'),
(28,'ICT1222','2025-04-29',3.00,'Practical'),
(29,'ICT1222','2025-05-06',3.00,'Practical'),
(30,'ICT1222','2025-05-13',3.00,'Practical'),
(31,'ICT1233','2025-02-03',3.00,'Theory'),
(32,'ICT1233','2025-02-10',3.00,'Theory'),
(33,'ICT1233','2025-02-17',3.00,'Theory'),
(34,'ICT1233','2025-02-24',3.00,'Theory'),
(35,'ICT1233','2025-03-03',3.00,'Theory'),
(36,'ICT1233','2025-03-10',3.00,'Theory'),
(37,'ICT1233','2025-03-17',3.00,'Theory'),
(38,'ICT1233','2025-03-24',3.00,'Theory'),
(39,'ICT1233','2025-03-31',3.00,'Theory'),
(40,'ICT1233','2025-04-07',3.00,'Theory'),
(41,'ICT1233','2025-04-14',3.00,'Theory'),
(42,'ICT1233','2025-04-21',3.00,'Theory'),
(43,'ICT1233','2025-04-28',3.00,'Theory'),
(44,'ICT1233','2025-05-05',3.00,'Theory'),
(45,'ICT1233','2025-05-12',3.00,'Theory'),
(46,'ICT1233','2025-02-04',3.00,'Practical'),
(47,'ICT1233','2025-02-11',3.00,'Practical'),
(48,'ICT1233','2025-02-18',3.00,'Practical'),
(49,'ICT1233','2025-02-25',3.00,'Practical'),
(50,'ICT1233','2025-03-04',3.00,'Practical'),
(51,'ICT1233','2025-03-11',3.00,'Practical'),
(52,'ICT1233','2025-03-18',3.00,'Practical'),
(53,'ICT1233','2025-03-25',3.00,'Practical'),
(54,'ICT1233','2025-04-01',3.00,'Practical'),
(55,'ICT1233','2025-04-08',3.00,'Practical'),
(56,'ICT1233','2025-04-15',3.00,'Practical'),
(57,'ICT1233','2025-04-22',3.00,'Practical'),
(58,'ICT1233','2025-04-29',3.00,'Practical'),
(59,'ICT1233','2025-05-06',3.00,'Practical'),
(60,'ICT1233','2025-05-13',3.00,'Practical'),
(61,'ICT1242','2025-02-03',3.00,'Theory'),
(62,'ICT1242','2025-02-10',3.00,'Theory'),
(63,'ICT1242','2025-02-17',3.00,'Theory'),
(64,'ICT1242','2025-02-24',3.00,'Theory'),
(65,'ICT1242','2025-03-03',3.00,'Theory'),
(66,'ICT1242','2025-03-10',3.00,'Theory'),
(67,'ICT1242','2025-03-17',3.00,'Theory'),
(68,'ICT1242','2025-03-24',3.00,'Theory'),
(69,'ICT1242','2025-03-31',3.00,'Theory'),
(70,'ICT1242','2025-04-07',3.00,'Theory'),
(71,'ICT1242','2025-04-14',3.00,'Theory'),
(72,'ICT1242','2025-04-21',3.00,'Theory'),
(73,'ICT1242','2025-04-28',3.00,'Theory'),
(74,'ICT1242','2025-05-05',3.00,'Theory'),
(75,'ICT1242','2025-05-12',3.00,'Theory'),
(76,'ICT1253','2025-02-03',3.00,'Theory'),
(77,'ICT1253','2025-02-10',3.00,'Theory'),
(78,'ICT1253','2025-02-17',3.00,'Theory'),
(79,'ICT1253','2025-02-24',3.00,'Theory'),
(80,'ICT1253','2025-03-03',3.00,'Theory'),
(81,'ICT1253','2025-03-10',3.00,'Theory'),
(82,'ICT1253','2025-03-17',3.00,'Theory'),
(83,'ICT1253','2025-03-24',3.00,'Theory'),
(84,'ICT1253','2025-03-31',3.00,'Theory'),
(85,'ICT1253','2025-04-07',3.00,'Theory'),
(86,'ICT1253','2025-04-14',3.00,'Theory'),
(87,'ICT1253','2025-04-21',3.00,'Theory'),
(88,'ICT1253','2025-04-28',3.00,'Theory'),
(89,'ICT1253','2025-05-05',3.00,'Theory'),
(90,'ICT1253','2025-05-12',3.00,'Theory'),
(91,'ICT1253','2025-02-04',3.00,'Practical'),
(92,'ICT1253','2025-02-11',3.00,'Practical'),
(93,'ICT1253','2025-02-18',3.00,'Practical'),
(94,'ICT1253','2025-02-25',3.00,'Practical'),
(95,'ICT1253','2025-03-04',3.00,'Practical'),
(96,'ICT1253','2025-03-11',3.00,'Practical'),
(97,'ICT1253','2025-03-18',3.00,'Practical'),
(98,'ICT1253','2025-03-25',3.00,'Practical'),
(99,'ICT1253','2025-04-01',3.00,'Practical'),
(100,'ICT1253','2025-04-08',3.00,'Practical'),
(101,'ICT1253','2025-04-15',3.00,'Practical'),
(102,'ICT1253','2025-04-22',3.00,'Practical'),
(103,'ICT1253','2025-04-29',3.00,'Practical'),
(104,'ICT1253','2025-05-06',3.00,'Practical'),
(105,'ICT1253','2025-05-13',3.00,'Practical'),
(106,'TCS1212','2025-02-03',2.00,'Theory'),
(107,'TCS1212','2025-02-10',2.00,'Theory'),
(108,'TCS1212','2025-02-17',2.00,'Theory'),
(109,'TCS1212','2025-02-24',2.00,'Theory'),
(110,'TCS1212','2025-03-03',2.00,'Theory'),
(111,'TCS1212','2025-03-10',2.00,'Theory'),
(112,'TCS1212','2025-03-17',2.00,'Theory'),
(113,'TCS1212','2025-03-24',2.00,'Theory'),
(114,'TCS1212','2025-03-31',2.00,'Theory'),
(115,'TCS1212','2025-04-07',2.00,'Theory'),
(116,'TCS1212','2025-04-14',2.00,'Theory'),
(117,'TCS1212','2025-04-21',2.00,'Theory'),
(118,'TCS1212','2025-04-28',2.00,'Theory'),
(119,'TCS1212','2025-05-05',2.00,'Theory'),
(120,'TCS1212','2025-05-12',2.00,'Theory'),
(121,'TMS1233','2025-02-03',3.00,'Theory'),
(122,'TMS1233','2025-02-10',3.00,'Theory'),
(123,'TMS1233','2025-02-17',3.00,'Theory'),
(124,'TMS1233','2025-02-24',3.00,'Theory'),
(125,'TMS1233','2025-03-03',3.00,'Theory'),
(126,'TMS1233','2025-03-10',3.00,'Theory'),
(127,'TMS1233','2025-03-17',3.00,'Theory'),
(128,'TMS1233','2025-03-24',3.00,'Theory'),
(129,'TMS1233','2025-03-31',3.00,'Theory'),
(130,'TMS1233','2025-04-07',3.00,'Theory'),
(131,'TMS1233','2025-04-14',3.00,'Theory'),
(132,'TMS1233','2025-04-21',3.00,'Theory'),
(133,'TMS1233','2025-04-28',3.00,'Theory'),
(134,'TMS1233','2025-05-05',3.00,'Theory'),
(135,'TMS1233','2025-05-12',3.00,'Theory');


-- ==============================================================
-- Data for Medical Table
-- ==============================================================

INSERT INTO medical (medical_id, student_id, course_id, exam_type, date_submitted, status) VALUES

(1,'U013','ICT1222','Attendance','2025-02-17','Approved'),
(2,'U015','ICT1233','Mid','2025-03-10','Approved'),
(3,'U020','ICT1253','Attendance','2025-03-04','Approved'),
(4,'U021','TMS1233','Mid','2025-04-14','Approved'),
(5,'U025','ICT1222','Attendance','2025-02-10','Approved');

INSERT INTO attendance (attendance_id, student_id, session_id, status, medical, hours_attended) VALUES

(1,'U013',1,'Present',FALSE,3.00),
(2,'U013',2,'Present',FALSE,3.00),
(3,'U013',3,'Absent',TRUE,3.00),
(4,'U013',4,'Present',FALSE,3.00),
(5,'U013',5,'Present',FALSE,3.00),
(6,'U013',6,'Present',FALSE,3.00),
(7,'U013',7,'Absent',FALSE,3.00),
(8,'U013',8,'Present',FALSE,3.00),
(9,'U013',9,'Present',FALSE,3.00),
(10,'U013',10,'Present',FALSE,3.00),
(11,'U013',11,'Present',FALSE,3.00),
(12,'U013',12,'Present',FALSE,3.00),
(13,'U013',13,'Present',FALSE,3.00),
(14,'U013',14,'Present',FALSE,3.00),
(15,'U013',15,'Present',FALSE,3.00),
(16,'U013',16,'Present',FALSE,3.00),
(17,'U013',17,'Present',FALSE,3.00),
(18,'U013',18,'Present',FALSE,3.00),
(19,'U013',19,'Present',FALSE,3.00),
(20,'U013',20,'Present',FALSE,3.00),
(21,'U013',21,'Present',FALSE,3.00),
(22,'U013',22,'Present',FALSE,3.00),
(23,'U013',23,'Present',FALSE,3.00),
(24,'U013',24,'Present',FALSE,3.00),
(25,'U013',25,'Present',FALSE,3.00),
(26,'U013',26,'Present',FALSE,3.00),
(27,'U013',27,'Present',FALSE,3.00),
(28,'U013',28,'Present',FALSE,3.00),
(29,'U013',29,'Absent',FALSE,3.00),
(30,'U013',30,'Present',FALSE,3.00),
(31,'U013',31,'Present',FALSE,3.00),
(32,'U013',32,'Absent',FALSE,0.00),
(33,'U013',33,'Present',FALSE,3.00),
(34,'U013',34,'Present',FALSE,3.00),
(35,'U013',35,'Present',FALSE,3.00),
(36,'U013',36,'Present',FALSE,3.00),
(37,'U013',37,'Present',FALSE,3.00),
(38,'U013',38,'Present',FALSE,3.00),
(39,'U013',39,'Present',FALSE,3.00),
(40,'U013',40,'Present',FALSE,3.00),
(41,'U013',41,'Present',FALSE,3.00),
(42,'U013',42,'Absent',FALSE,0.00),
(43,'U013',43,'Present',FALSE,3.00),
(44,'U013',44,'Present',FALSE,3.00),
(45,'U013',45,'Present',FALSE,3.00),
(46,'U013',46,'Present',FALSE,3.00),
(47,'U013',47,'Present',FALSE,3.00),
(48,'U013',48,'Present',FALSE,3.00),
(49,'U013',49,'Present',FALSE,3.00),
(50,'U013',50,'Present',FALSE,3.00),
(51,'U013',51,'Present',FALSE,3.00),
(52,'U013',52,'Present',FALSE,3.00),
(53,'U013',53,'Present',FALSE,3.00),
(54,'U013',54,'Present',FALSE,3.00),
(55,'U013',55,'Present',FALSE,3.00),
(56,'U013',56,'Present',FALSE,3.00),
(57,'U013',57,'Present',FALSE,3.00),
(58,'U013',58,'Present',FALSE,3.00),
(59,'U013',59,'Absent',FALSE,0.00),
(60,'U013',60,'Present',FALSE,3.00),
(61,'U013',61,'Present',FALSE,3.00),
(62,'U013',62,'Present',FALSE,3.00),
(63,'U013',63,'Present',FALSE,3.00),
(64,'U013',64,'Present',FALSE,3.00),
(65,'U013',65,'Present',FALSE,3.00),
(66,'U013',66,'Present',FALSE,3.00),
(67,'U013',67,'Present',FALSE,3.00),
(68,'U013',68,'Present',FALSE,3.00),
(69,'U013',69,'Absent',FALSE,0.00),
(70,'U013',70,'Present',FALSE,3.00),
(71,'U013',71,'Absent',FALSE,3.00),
(72,'U013',72,'Present',FALSE,3.00),
(73,'U013',73,'Present',FALSE,3.00),
(74,'U013',74,'Present',FALSE,3.00),
(75,'U013',75,'Present',FALSE,3.00),
(76,'U013',76,'Present',FALSE,3.00),
(77,'U013',77,'Present',FALSE,3.00),
(78,'U013',78,'Present',FALSE,3.00),
(79,'U013',79,'Present',FALSE,3.00),
(80,'U013',80,'Present',FALSE,3.00),
(81,'U013',81,'Present',FALSE,3.00),
(82,'U013',82,'Present',FALSE,3.00),
(83,'U013',83,'Present',FALSE,3.00),
(84,'U013',84,'Absent',FALSE,0.00),
(85,'U013',85,'Present',FALSE,3.00),
(86,'U013',86,'Present',FALSE,3.00),
(87,'U013',87,'Present',FALSE,3.00),
(88,'U013',88,'Present',FALSE,3.00),
(89,'U013',89,'Present',FALSE,3.00),
(90,'U013',90,'Present',FALSE,3.00),
(91,'U013',91,'Present',FALSE,3.00),
(92,'U013',92,'Present',FALSE,3.00),
(93,'U013',93,'Present',FALSE,3.00),
(94,'U013',94,'Present',FALSE,3.00),
(95,'U013',95,'Present',FALSE,3.00),
(96,'U013',96,'Present',FALSE,3.00),
(97,'U013',97,'Present',FALSE,3.00),
(98,'U013',98,'Absent',FALSE,0.00),
(99,'U013',99,'Present',FALSE,3.00),
(100,'U013',100,'Present',FALSE,3.00),
(101,'U013',101,'Present',FALSE,3.00),
(102,'U013',102,'Present',FALSE,3.00),
(103,'U013',103,'Present',FALSE,3.00),
(104,'U013',104,'Present',FALSE,3.00),
(105,'U013',105,'Present',FALSE,3.00),
(106,'U013',106,'Present',FALSE,2.00),
(107,'U013',107,'Present',FALSE,2.00),
(108,'U013',108,'Present',FALSE,2.00),
(109,'U013',109,'Present',FALSE,2.00),
(110,'U013',110,'Absent',FALSE,0.00),
(111,'U013',111,'Present',FALSE,2.00),
(112,'U013',112,'Present',FALSE,2.00),
(113,'U013',113,'Present',FALSE,2.00),
(114,'U013',114,'Present',FALSE,2.00),
(115,'U013',115,'Present',FALSE,2.00),
(116,'U013',116,'Present',FALSE,2.00),
(117,'U013',117,'Present',FALSE,2.00),
(118,'U013',118,'Present',FALSE,2.00),
(119,'U013',119,'Present',FALSE,2.00),
(120,'U013',120,'Absent',FALSE,0.00),
(121,'U013',121,'Absent',FALSE,0.00),
(122,'U013',122,'Absent',FALSE,0.00),
(123,'U013',123,'Present',FALSE,3.00),
(124,'U013',124,'Present',FALSE,3.00),
(125,'U013',125,'Present',FALSE,3.00),
(126,'U013',126,'Present',FALSE,3.00),
(127,'U013',127,'Absent',FALSE,0.00),
(128,'U013',128,'Present',FALSE,3.00),
(129,'U013',129,'Present',FALSE,3.00),
(130,'U013',130,'Present',FALSE,3.00),
(131,'U013',131,'Present',FALSE,3.00),
(132,'U013',132,'Present',FALSE,3.00),
(133,'U013',133,'Present',FALSE,3.00),
(134,'U013',134,'Present',FALSE,3.00),
(135,'U013',135,'Absent',FALSE,0.00),
(136,'U014',1,'Present',FALSE,3.00),
(137,'U014',2,'Present',FALSE,3.00),
(138,'U014',3,'Present',FALSE,3.00),
(139,'U014',4,'Present',FALSE,3.00),
(140,'U014',5,'Present',FALSE,3.00),
(141,'U014',6,'Present',FALSE,3.00),
(142,'U014',7,'Present',FALSE,3.00),
(143,'U014',8,'Present',FALSE,3.00),
(144,'U014',9,'Absent',FALSE,0.00),
(145,'U014',10,'Present',FALSE,3.00),
(146,'U014',11,'Present',FALSE,3.00),
(147,'U014',12,'Present',FALSE,3.00),
(148,'U014',13,'Present',FALSE,3.00),
(149,'U014',14,'Present',FALSE,3.00),
(150,'U014',15,'Present',FALSE,3.00),
(151,'U014',16,'Present',FALSE,3.00),
(152,'U014',17,'Present',FALSE,3.00),
(153,'U014',18,'Present',FALSE,3.00),
(154,'U014',19,'Present',FALSE,3.00),
(155,'U014',20,'Present',FALSE,3.00),
(156,'U014',21,'Present',FALSE,3.00),
(157,'U014',22,'Absent',FALSE,0.00),
(158,'U014',23,'Present',FALSE,3.00),
(159,'U014',24,'Present',FALSE,3.00),
(160,'U014',25,'Present',FALSE,3.00),
(161,'U014',26,'Present',FALSE,3.00),
(162,'U014',27,'Present',FALSE,3.00),
(163,'U014',28,'Present',FALSE,3.00),
(164,'U014',29,'Absent',FALSE,0.00),
(165,'U014',30,'Present',FALSE,3.00),
(166,'U014',31,'Present',FALSE,3.00),
(167,'U014',32,'Present',FALSE,3.00),
(168,'U014',33,'Absent',FALSE,3.00),
(169,'U014',34,'Present',FALSE,3.00),
(170,'U014',35,'Present',FALSE,3.00),
(171,'U014',36,'Present',FALSE,3.00),
(172,'U014',37,'Present',FALSE,3.00),
(173,'U014',38,'Present',FALSE,3.00),
(174,'U014',39,'Present',FALSE,3.00),
(175,'U014',40,'Present',FALSE,3.00),
(176,'U014',41,'Absent',FALSE,0.00),
(177,'U014',42,'Present',FALSE,3.00),
(178,'U014',43,'Absent',FALSE,3.00),
(179,'U014',44,'Present',FALSE,3.00),
(180,'U014',45,'Present',FALSE,3.00),
(181,'U014',46,'Present',FALSE,3.00),
(182,'U014',47,'Present',FALSE,3.00),
(183,'U014',48,'Present',FALSE,3.00),
(184,'U014',49,'Present',FALSE,3.00),
(185,'U014',50,'Present',FALSE,3.00),
(186,'U014',51,'Present',FALSE,3.00),
(187,'U014',52,'Absent',FALSE,0.00),
(188,'U014',53,'Present',FALSE,3.00),
(189,'U014',54,'Present',FALSE,3.00),
(190,'U014',55,'Present',FALSE,3.00),
(191,'U014',56,'Present',FALSE,3.00),
(192,'U014',57,'Absent',FALSE,0.00),
(193,'U014',58,'Present',FALSE,3.00),
(194,'U014',59,'Absent',FALSE,0.00),
(195,'U014',60,'Absent',FALSE,0.00),
(196,'U014',61,'Present',FALSE,3.00),
(197,'U014',62,'Present',FALSE,3.00),
(198,'U014',63,'Present',FALSE,3.00),
(199,'U014',64,'Present',FALSE,3.00),
(200,'U014',65,'Present',FALSE,3.00),
(201,'U014',66,'Present',FALSE,3.00),
(202,'U014',67,'Present',FALSE,3.00),
(203,'U014',68,'Absent',FALSE,0.00),
(204,'U014',69,'Present',FALSE,3.00),
(205,'U014',70,'Present',FALSE,3.00),
(206,'U014',71,'Present',FALSE,3.00),
(207,'U014',72,'Present',FALSE,3.00),
(208,'U014',73,'Absent',FALSE,0.00),
(209,'U014',74,'Absent',FALSE,0.00),
(210,'U014',75,'Present',FALSE,3.00),
(211,'U014',76,'Present',FALSE,3.00),
(212,'U014',77,'Present',FALSE,3.00),
(213,'U014',78,'Present',FALSE,3.00),
(214,'U014',79,'Absent',FALSE,0.00),
(215,'U014',80,'Present',FALSE,3.00),
(216,'U014',81,'Present',FALSE,3.00),
(217,'U014',82,'Present',FALSE,3.00),
(218,'U014',83,'Present',FALSE,3.00),
(219,'U014',84,'Present',FALSE,3.00),
(220,'U014',85,'Present',FALSE,3.00),
(221,'U014',86,'Present',FALSE,3.00),
(222,'U014',87,'Present',FALSE,3.00),
(223,'U014',88,'Absent',FALSE,0.00),
(224,'U014',89,'Present',FALSE,3.00),
(225,'U014',90,'Present',FALSE,3.00),
(226,'U014',91,'Present',FALSE,3.00),
(227,'U014',92,'Present',FALSE,3.00),
(228,'U014',93,'Present',FALSE,3.00),
(229,'U014',94,'Present',FALSE,3.00),
(230,'U014',95,'Present',FALSE,3.00),
(231,'U014',96,'Present',FALSE,3.00),
(232,'U014',97,'Present',FALSE,3.00),
(233,'U014',98,'Present',FALSE,3.00),
(234,'U014',99,'Present',FALSE,3.00),
(235,'U014',100,'Present',FALSE,3.00),
(236,'U014',101,'Present',FALSE,3.00),
(237,'U014',102,'Absent',FALSE,0.00),
(238,'U014',103,'Present',FALSE,3.00),
(239,'U014',104,'Present',FALSE,3.00),
(240,'U014',105,'Present',FALSE,3.00),
(241,'U014',106,'Present',FALSE,2.00),
(242,'U014',107,'Present',FALSE,2.00),
(243,'U014',108,'Present',FALSE,2.00),
(244,'U014',109,'Present',FALSE,2.00),
(245,'U014',110,'Present',FALSE,2.00),
(246,'U014',111,'Present',FALSE,2.00),
(247,'U014',112,'Present',FALSE,2.00),
(248,'U014',113,'Absent',FALSE,0.00),
(249,'U014',114,'Absent',FALSE,0.00),
(250,'U014',115,'Present',FALSE,2.00),
(251,'U014',116,'Present',FALSE,2.00),
(252,'U014',117,'Present',FALSE,2.00),
(253,'U014',118,'Absent',FALSE,0.00),
(254,'U014',119,'Present',FALSE,2.00),
(255,'U014',120,'Present',FALSE,2.00),
(256,'U014',121,'Present',FALSE,3.00),
(257,'U014',122,'Absent',FALSE,3.00),
(258,'U014',123,'Present',FALSE,3.00),
(259,'U014',124,'Present',FALSE,3.00),
(260,'U014',125,'Present',FALSE,3.00),
(261,'U014',126,'Absent',FALSE,0.00),
(262,'U014',127,'Present',FALSE,3.00),
(263,'U014',128,'Present',FALSE,3.00),
(264,'U014',129,'Present',FALSE,3.00),
(265,'U014',130,'Present',FALSE,3.00),
(266,'U014',131,'Present',FALSE,3.00),
(267,'U014',132,'Absent',FALSE,0.00),
(268,'U014',133,'Present',FALSE,3.00),
(269,'U014',134,'Present',FALSE,3.00),
(270,'U014',135,'Present',FALSE,3.00),
(271,'U015',1,'Present',FALSE,3.00),
(272,'U015',2,'Present',FALSE,3.00),
(273,'U015',3,'Present',FALSE,3.00),
(274,'U015',4,'Present',FALSE,3.00),
(275,'U015',5,'Present',FALSE,3.00),
(276,'U015',6,'Present',FALSE,3.00),
(277,'U015',7,'Absent',FALSE,0.00),
(278,'U015',8,'Present',FALSE,3.00),
(279,'U015',9,'Present',FALSE,3.00),
(280,'U015',10,'Present',FALSE,3.00),
(281,'U015',11,'Present',FALSE,3.00),
(282,'U015',12,'Present',FALSE,3.00),
(283,'U015',13,'Present',FALSE,3.00),
(284,'U015',14,'Present',FALSE,3.00),
(285,'U015',15,'Present',FALSE,3.00),
(286,'U015',16,'Present',FALSE,3.00),
(287,'U015',17,'Present',FALSE,3.00),
(288,'U015',18,'Present',FALSE,3.00),
(289,'U015',19,'Present',FALSE,3.00),
(290,'U015',20,'Present',FALSE,3.00),
(291,'U015',21,'Present',FALSE,3.00),
(292,'U015',22,'Absent',FALSE,0.00),
(293,'U015',23,'Present',FALSE,3.00),
(294,'U015',24,'Present',FALSE,3.00),
(295,'U015',25,'Present',FALSE,3.00),
(296,'U015',26,'Present',FALSE,3.00),
(297,'U015',27,'Present',FALSE,3.00),
(298,'U015',28,'Present',FALSE,3.00),
(299,'U015',29,'Present',FALSE,3.00),
(300,'U015',30,'Present',FALSE,3.00),
(301,'U015',31,'Present',FALSE,3.00),
(302,'U015',32,'Present',FALSE,3.00),
(303,'U015',33,'Present',FALSE,3.00),
(304,'U015',34,'Present',FALSE,3.00),
(305,'U015',35,'Present',FALSE,3.00),
(306,'U015',36,'Absent',TRUE,3.00),
(307,'U015',37,'Present',FALSE,3.00),
(308,'U015',38,'Present',FALSE,3.00),
(309,'U015',39,'Present',FALSE,3.00),
(310,'U015',40,'Absent',FALSE,3.00),
(311,'U015',41,'Absent',FALSE,0.00),
(312,'U015',42,'Present',FALSE,3.00),
(313,'U015',43,'Absent',FALSE,0.00),
(314,'U015',44,'Present',FALSE,3.00),
(315,'U015',45,'Present',FALSE,3.00),
(316,'U015',46,'Present',FALSE,3.00),
(317,'U015',47,'Present',FALSE,3.00),
(318,'U015',48,'Present',FALSE,3.00),
(319,'U015',49,'Absent',FALSE,0.00),
(320,'U015',50,'Present',FALSE,3.00),
(321,'U015',51,'Present',FALSE,3.00),
(322,'U015',52,'Present',FALSE,3.00),
(323,'U015',53,'Present',FALSE,3.00),
(324,'U015',54,'Present',FALSE,3.00),
(325,'U015',55,'Present',FALSE,3.00),
(326,'U015',56,'Present',FALSE,3.00),
(327,'U015',57,'Present',FALSE,3.00),
(328,'U015',58,'Present',FALSE,3.00),
(329,'U015',59,'Present',FALSE,3.00),
(330,'U015',60,'Present',FALSE,3.00),
(331,'U015',61,'Present',FALSE,3.00),
(332,'U015',62,'Present',FALSE,3.00),
(333,'U015',63,'Present',FALSE,3.00),
(334,'U015',64,'Present',FALSE,3.00),
(335,'U015',65,'Present',FALSE,3.00),
(336,'U015',66,'Present',FALSE,3.00),
(337,'U015',67,'Present',FALSE,3.00),
(338,'U015',68,'Absent',FALSE,0.00),
(339,'U015',69,'Present',FALSE,3.00),
(340,'U015',70,'Absent',FALSE,3.00),
(341,'U015',71,'Present',FALSE,3.00),
(342,'U015',72,'Absent',FALSE,0.00),
(343,'U015',73,'Absent',FALSE,3.00),
(344,'U015',74,'Absent',FALSE,0.00),
(345,'U015',75,'Present',FALSE,3.00),
(346,'U015',76,'Absent',FALSE,0.00),
(347,'U015',77,'Present',FALSE,3.00),
(348,'U015',78,'Absent',FALSE,0.00),
(349,'U015',79,'Present',FALSE,3.00),
(350,'U015',80,'Present',FALSE,3.00),
(351,'U015',81,'Present',FALSE,3.00),
(352,'U015',82,'Present',FALSE,3.00),
(353,'U015',83,'Present',FALSE,3.00),
(354,'U015',84,'Present',FALSE,3.00),
(355,'U015',85,'Present',FALSE,3.00),
(356,'U015',86,'Present',FALSE,3.00),
(357,'U015',87,'Present',FALSE,3.00),
(358,'U015',88,'Present',FALSE,3.00),
(359,'U015',89,'Present',FALSE,3.00),
(360,'U015',90,'Present',FALSE,3.00),
(361,'U015',91,'Absent',FALSE,0.00),
(362,'U015',92,'Present',FALSE,3.00),
(363,'U015',93,'Present',FALSE,3.00),
(364,'U015',94,'Present',FALSE,3.00),
(365,'U015',95,'Present',FALSE,3.00),
(366,'U015',96,'Present',FALSE,3.00),
(367,'U015',97,'Present',FALSE,3.00),
(368,'U015',98,'Present',FALSE,3.00),
(369,'U015',99,'Present',FALSE,3.00),
(370,'U015',100,'Present',FALSE,3.00),
(371,'U015',101,'Present',FALSE,3.00),
(372,'U015',102,'Present',FALSE,3.00),
(373,'U015',103,'Present',FALSE,3.00),
(374,'U015',104,'Present',FALSE,3.00),
(375,'U015',105,'Present',FALSE,3.00),
(376,'U015',106,'Present',FALSE,2.00),
(377,'U015',107,'Present',FALSE,2.00),
(378,'U015',108,'Present',FALSE,2.00),
(379,'U015',109,'Present',FALSE,2.00),
(380,'U015',110,'Absent',FALSE,0.00),
(381,'U015',111,'Present',FALSE,2.00),
(382,'U015',112,'Absent',FALSE,0.00),
(383,'U015',113,'Present',FALSE,2.00),
(384,'U015',114,'Present',FALSE,2.00),
(385,'U015',115,'Present',FALSE,2.00),
(386,'U015',116,'Present',FALSE,2.00),
(387,'U015',117,'Present',FALSE,2.00),
(388,'U015',118,'Present',FALSE,2.00),
(389,'U015',119,'Present',FALSE,2.00),
(390,'U015',120,'Present',FALSE,2.00),
(391,'U015',121,'Present',FALSE,3.00),
(392,'U015',122,'Present',FALSE,3.00),
(393,'U015',123,'Present',FALSE,3.00),
(394,'U015',124,'Present',FALSE,3.00),
(395,'U015',125,'Absent',FALSE,0.00),
(396,'U015',126,'Present',FALSE,3.00),
(397,'U015',127,'Present',FALSE,3.00),
(398,'U015',128,'Present',FALSE,3.00),
(399,'U015',129,'Present',FALSE,3.00),
(400,'U015',130,'Present',FALSE,3.00),
(401,'U015',131,'Present',FALSE,3.00),
(402,'U015',132,'Present',FALSE,3.00),
(403,'U015',133,'Present',FALSE,3.00),
(404,'U015',134,'Present',FALSE,3.00),
(405,'U015',135,'Present',FALSE,3.00),
(406,'U016',1,'Present',FALSE,3.00),
(407,'U016',2,'Absent',FALSE,0.00),
(408,'U016',3,'Present',FALSE,3.00),
(409,'U016',4,'Present',FALSE,3.00),
(410,'U016',5,'Present',FALSE,3.00),
(411,'U016',6,'Present',FALSE,3.00),
(412,'U016',7,'Absent',FALSE,3.00),
(413,'U016',8,'Present',FALSE,3.00),
(414,'U016',9,'Present',FALSE,3.00),
(415,'U016',10,'Present',FALSE,3.00),
(416,'U016',11,'Present',FALSE,3.00),
(417,'U016',12,'Present',FALSE,3.00),
(418,'U016',13,'Present',FALSE,3.00),
(419,'U016',14,'Present',FALSE,3.00),
(420,'U016',15,'Present',FALSE,3.00),
(421,'U016',16,'Present',FALSE,3.00),
(422,'U016',17,'Present',FALSE,3.00),
(423,'U016',18,'Present',FALSE,3.00),
(424,'U016',19,'Present',FALSE,3.00),
(425,'U016',20,'Present',FALSE,3.00),
(426,'U016',21,'Present',FALSE,3.00),
(427,'U016',22,'Absent',FALSE,0.00),
(428,'U016',23,'Present',FALSE,3.00),
(429,'U016',24,'Present',FALSE,3.00),
(430,'U016',25,'Present',FALSE,3.00),
(431,'U016',26,'Present',FALSE,3.00),
(432,'U016',27,'Present',FALSE,3.00),
(433,'U016',28,'Present',FALSE,3.00),
(434,'U016',29,'Present',FALSE,3.00),
(435,'U016',30,'Present',FALSE,3.00),
(436,'U016',31,'Present',FALSE,3.00),
(437,'U016',32,'Present',FALSE,3.00),
(438,'U016',33,'Present',FALSE,3.00),
(439,'U016',34,'Absent',FALSE,0.00),
(440,'U016',35,'Present',FALSE,3.00),
(441,'U016',36,'Present',FALSE,3.00),
(442,'U016',37,'Present',FALSE,3.00),
(443,'U016',38,'Absent',FALSE,3.00),
(444,'U016',39,'Present',FALSE,3.00),
(445,'U016',40,'Present',FALSE,3.00),
(446,'U016',41,'Present',FALSE,3.00),
(447,'U016',42,'Present',FALSE,3.00),
(448,'U016',43,'Present',FALSE,3.00),
(449,'U016',44,'Present',FALSE,3.00),
(450,'U016',45,'Present',FALSE,3.00),
(451,'U016',46,'Present',FALSE,3.00),
(452,'U016',47,'Present',FALSE,3.00),
(453,'U016',48,'Present',FALSE,3.00),
(454,'U016',49,'Present',FALSE,3.00),
(455,'U016',50,'Present',FALSE,3.00),
(456,'U016',51,'Absent',FALSE,3.00),
(457,'U016',52,'Present',FALSE,3.00),
(458,'U016',53,'Present',FALSE,3.00),
(459,'U016',54,'Present',FALSE,3.00),
(460,'U016',55,'Present',FALSE,3.00),
(461,'U016',56,'Present',FALSE,3.00),
(462,'U016',57,'Present',FALSE,3.00),
(463,'U016',58,'Present',FALSE,3.00),
(464,'U016',59,'Present',FALSE,3.00),
(465,'U016',60,'Present',FALSE,3.00),
(466,'U016',61,'Present',FALSE,3.00),
(467,'U016',62,'Absent',FALSE,0.00),
(468,'U016',63,'Present',FALSE,3.00),
(469,'U016',64,'Present',FALSE,3.00),
(470,'U016',65,'Present',FALSE,3.00),
(471,'U016',66,'Present',FALSE,3.00),
(472,'U016',67,'Absent',FALSE,0.00),
(473,'U016',68,'Present',FALSE,3.00),
(474,'U016',69,'Present',FALSE,3.00),
(475,'U016',70,'Present',FALSE,3.00),
(476,'U016',71,'Present',FALSE,3.00),
(477,'U016',72,'Present',FALSE,3.00),
(478,'U016',73,'Present',FALSE,3.00),
(479,'U016',74,'Present',FALSE,3.00),
(480,'U016',75,'Present',FALSE,3.00),
(481,'U016',76,'Present',FALSE,3.00),
(482,'U016',77,'Present',FALSE,3.00),
(483,'U016',78,'Present',FALSE,3.00),
(484,'U016',79,'Present',FALSE,3.00),
(485,'U016',80,'Present',FALSE,3.00),
(486,'U016',81,'Present',FALSE,3.00),
(487,'U016',82,'Present',FALSE,3.00),
(488,'U016',83,'Present',FALSE,3.00),
(489,'U016',84,'Absent',FALSE,0.00),
(490,'U016',85,'Absent',FALSE,0.00),
(491,'U016',86,'Present',FALSE,3.00),
(492,'U016',87,'Absent',FALSE,0.00),
(493,'U016',88,'Present',FALSE,3.00),
(494,'U016',89,'Present',FALSE,3.00),
(495,'U016',90,'Present',FALSE,3.00),
(496,'U016',91,'Present',FALSE,3.00),
(497,'U016',92,'Present',FALSE,3.00),
(498,'U016',93,'Present',FALSE,3.00),
(499,'U016',94,'Present',FALSE,3.00),
(500,'U016',95,'Present',FALSE,3.00),
(501,'U016',96,'Present',FALSE,3.00),
(502,'U016',97,'Present',FALSE,3.00),
(503,'U016',98,'Present',FALSE,3.00),
(504,'U016',99,'Present',FALSE,3.00),
(505,'U016',100,'Absent',FALSE,0.00),
(506,'U016',101,'Present',FALSE,3.00),
(507,'U016',102,'Present',FALSE,3.00),
(508,'U016',103,'Present',FALSE,3.00),
(509,'U016',104,'Present',FALSE,3.00),
(510,'U016',105,'Present',FALSE,3.00),
(511,'U016',106,'Absent',FALSE,0.00),
(512,'U016',107,'Present',FALSE,2.00),
(513,'U016',108,'Present',FALSE,2.00),
(514,'U016',109,'Absent',FALSE,0.00),
(515,'U016',110,'Present',FALSE,2.00),
(516,'U016',111,'Present',FALSE,2.00),
(517,'U016',112,'Present',FALSE,2.00),
(518,'U016',113,'Present',FALSE,2.00),
(519,'U016',114,'Present',FALSE,2.00),
(520,'U016',115,'Present',FALSE,2.00),
(521,'U016',116,'Present',FALSE,2.00),
(522,'U016',117,'Present',FALSE,2.00),
(523,'U016',118,'Absent',FALSE,0.00),
(524,'U016',119,'Present',FALSE,2.00),
(525,'U016',120,'Present',FALSE,2.00),
(526,'U016',121,'Present',FALSE,3.00),
(527,'U016',122,'Present',FALSE,3.00),
(528,'U016',123,'Absent',FALSE,0.00),
(529,'U016',124,'Present',FALSE,3.00),
(530,'U016',125,'Present',FALSE,3.00),
(531,'U016',126,'Present',FALSE,3.00),
(532,'U016',127,'Present',FALSE,3.00),
(533,'U016',128,'Present',FALSE,3.00),
(534,'U016',129,'Absent',FALSE,0.00),
(535,'U016',130,'Present',FALSE,3.00),
(536,'U016',131,'Absent',FALSE,0.00),
(537,'U016',132,'Present',FALSE,3.00),
(538,'U016',133,'Absent',FALSE,0.00),
(539,'U016',134,'Present',FALSE,3.00),
(540,'U016',135,'Present',FALSE,3.00),
(541,'U017',1,'Present',FALSE,3.00),
(542,'U017',2,'Present',FALSE,3.00),
(543,'U017',3,'Present',FALSE,3.00),
(544,'U017',4,'Absent',FALSE,0.00),
(545,'U017',5,'Present',FALSE,3.00),
(546,'U017',6,'Present',FALSE,3.00),
(547,'U017',7,'Present',FALSE,3.00),
(548,'U017',8,'Present',FALSE,3.00),
(549,'U017',9,'Present',FALSE,3.00),
(550,'U017',10,'Present',FALSE,3.00),
(551,'U017',11,'Present',FALSE,3.00),
(552,'U017',12,'Present',FALSE,3.00),
(553,'U017',13,'Present',FALSE,3.00),
(554,'U017',14,'Absent',FALSE,0.00),
(555,'U017',15,'Present',FALSE,3.00),
(556,'U017',16,'Present',FALSE,3.00),
(557,'U017',17,'Present',FALSE,3.00),
(558,'U017',18,'Present',FALSE,3.00),
(559,'U017',19,'Present',FALSE,3.00),
(560,'U017',20,'Absent',FALSE,0.00),
(561,'U017',21,'Present',FALSE,3.00),
(562,'U017',22,'Present',FALSE,3.00),
(563,'U017',23,'Present',FALSE,3.00),
(564,'U017',24,'Present',FALSE,3.00),
(565,'U017',25,'Present',FALSE,3.00),
(566,'U017',26,'Present',FALSE,3.00),
(567,'U017',27,'Absent',FALSE,3.00),
(568,'U017',28,'Present',FALSE,3.00),
(569,'U017',29,'Present',FALSE,3.00),
(570,'U017',30,'Present',FALSE,3.00),
(571,'U017',31,'Present',FALSE,3.00),
(572,'U017',32,'Present',FALSE,3.00),
(573,'U017',33,'Present',FALSE,3.00),
(574,'U017',34,'Present',FALSE,3.00),
(575,'U017',35,'Present',FALSE,3.00),
(576,'U017',36,'Present',FALSE,3.00),
(577,'U017',37,'Present',FALSE,3.00),
(578,'U017',38,'Present',FALSE,3.00),
(579,'U017',39,'Present',FALSE,3.00),
(580,'U017',40,'Present',FALSE,3.00),
(581,'U017',41,'Present',FALSE,3.00),
(582,'U017',42,'Present',FALSE,3.00),
(583,'U017',43,'Present',FALSE,3.00),
(584,'U017',44,'Present',FALSE,3.00),
(585,'U017',45,'Present',FALSE,3.00),
(586,'U017',46,'Absent',FALSE,0.00),
(587,'U017',47,'Present',FALSE,3.00),
(588,'U017',48,'Present',FALSE,3.00),
(589,'U017',49,'Present',FALSE,3.00),
(590,'U017',50,'Present',FALSE,3.00),
(591,'U017',51,'Present',FALSE,3.00),
(592,'U017',52,'Present',FALSE,3.00),
(593,'U017',53,'Present',FALSE,3.00),
(594,'U017',54,'Present',FALSE,3.00),
(595,'U017',55,'Present',FALSE,3.00),
(596,'U017',56,'Present',FALSE,3.00),
(597,'U017',57,'Present',FALSE,3.00),
(598,'U017',58,'Present',FALSE,3.00),
(599,'U017',59,'Present',FALSE,3.00),
(600,'U017',60,'Present',FALSE,3.00),
(601,'U017',61,'Present',FALSE,3.00),
(602,'U017',62,'Present',FALSE,3.00),
(603,'U017',63,'Absent',FALSE,3.00),
(604,'U017',64,'Present',FALSE,3.00),
(605,'U017',65,'Present',FALSE,3.00),
(606,'U017',66,'Present',FALSE,3.00),
(607,'U017',67,'Present',FALSE,3.00),
(608,'U017',68,'Present',FALSE,3.00),
(609,'U017',69,'Present',FALSE,3.00),
(610,'U017',70,'Present',FALSE,3.00),
(611,'U017',71,'Present',FALSE,3.00),
(612,'U017',72,'Present',FALSE,3.00),
(613,'U017',73,'Present',FALSE,3.00),
(614,'U017',74,'Present',FALSE,3.00),
(615,'U017',75,'Present',FALSE,3.00),
(616,'U017',76,'Present',FALSE,3.00),
(617,'U017',77,'Absent',FALSE,0.00),
(618,'U017',78,'Absent',FALSE,3.00),
(619,'U017',79,'Present',FALSE,3.00),
(620,'U017',80,'Present',FALSE,3.00),
(621,'U017',81,'Present',FALSE,3.00),
(622,'U017',82,'Present',FALSE,3.00),
(623,'U017',83,'Present',FALSE,3.00),
(624,'U017',84,'Present',FALSE,3.00),
(625,'U017',85,'Present',FALSE,3.00),
(626,'U017',86,'Present',FALSE,3.00),
(627,'U017',87,'Absent',FALSE,0.00),
(628,'U017',88,'Present',FALSE,3.00),
(629,'U017',89,'Present',FALSE,3.00),
(630,'U017',90,'Present',FALSE,3.00),
(631,'U017',91,'Present',FALSE,3.00),
(632,'U017',92,'Present',FALSE,3.00),
(633,'U017',93,'Present',FALSE,3.00),
(634,'U017',94,'Present',FALSE,3.00),
(635,'U017',95,'Present',FALSE,3.00),
(636,'U017',96,'Present',FALSE,3.00),
(637,'U017',97,'Present',FALSE,3.00),
(638,'U017',98,'Present',FALSE,3.00),
(639,'U017',99,'Absent',FALSE,0.00),
(640,'U017',100,'Present',FALSE,3.00),
(641,'U017',101,'Present',FALSE,3.00),
(642,'U017',102,'Present',FALSE,3.00),
(643,'U017',103,'Present',FALSE,3.00),
(644,'U017',104,'Present',FALSE,3.00),
(645,'U017',105,'Present',FALSE,3.00),
(646,'U017',106,'Present',FALSE,2.00),
(647,'U017',107,'Present',FALSE,2.00),
(648,'U017',108,'Present',FALSE,2.00),
(649,'U017',109,'Absent',FALSE,0.00),
(650,'U017',110,'Present',FALSE,2.00),
(651,'U017',111,'Present',FALSE,2.00),
(652,'U017',112,'Present',FALSE,2.00),
(653,'U017',113,'Present',FALSE,2.00),
(654,'U017',114,'Present',FALSE,2.00),
(655,'U017',115,'Present',FALSE,2.00),
(656,'U017',116,'Present',FALSE,2.00),
(657,'U017',117,'Present',FALSE,2.00),
(658,'U017',118,'Present',FALSE,2.00),
(659,'U017',119,'Absent',FALSE,0.00),
(660,'U017',120,'Present',FALSE,2.00),
(661,'U017',121,'Present',FALSE,3.00),
(662,'U017',122,'Present',FALSE,3.00),
(663,'U017',123,'Present',FALSE,3.00),
(664,'U017',124,'Absent',FALSE,0.00),
(665,'U017',125,'Present',FALSE,3.00),
(666,'U017',126,'Present',FALSE,3.00),
(667,'U017',127,'Present',FALSE,3.00),
(668,'U017',128,'Present',FALSE,3.00),
(669,'U017',129,'Present',FALSE,3.00),
(670,'U017',130,'Present',FALSE,3.00),
(671,'U017',131,'Present',FALSE,3.00),
(672,'U017',132,'Present',FALSE,3.00),
(673,'U017',133,'Present',FALSE,3.00),
(674,'U017',134,'Present',FALSE,3.00),
(675,'U017',135,'Present',FALSE,3.00),
(676,'U018',1,'Present',FALSE,3.00),
(677,'U018',2,'Absent',FALSE,0.00),
(678,'U018',3,'Present',FALSE,3.00),
(679,'U018',4,'Present',FALSE,3.00),
(680,'U018',5,'Present',FALSE,3.00),
(681,'U018',6,'Absent',FALSE,0.00),
(682,'U018',7,'Present',FALSE,3.00),
(683,'U018',8,'Present',FALSE,3.00),
(684,'U018',9,'Present',FALSE,3.00),
(685,'U018',10,'Absent',FALSE,0.00),
(686,'U018',11,'Present',FALSE,3.00),
(687,'U018',12,'Present',FALSE,3.00),
(688,'U018',13,'Present',FALSE,3.00),
(689,'U018',14,'Present',FALSE,3.00),
(690,'U018',15,'Present',FALSE,3.00),
(691,'U018',16,'Present',FALSE,3.00),
(692,'U018',17,'Present',FALSE,3.00),
(693,'U018',18,'Present',FALSE,3.00),
(694,'U018',19,'Absent',FALSE,3.00),
(695,'U018',20,'Present',FALSE,3.00),
(696,'U018',21,'Absent',FALSE,0.00),
(697,'U018',22,'Present',FALSE,3.00),
(698,'U018',23,'Present',FALSE,3.00),
(699,'U018',24,'Present',FALSE,3.00),
(700,'U018',25,'Present',FALSE,3.00),
(701,'U018',26,'Present',FALSE,3.00),
(702,'U018',27,'Present',FALSE,3.00),
(703,'U018',28,'Present',FALSE,3.00),
(704,'U018',29,'Present',FALSE,3.00),
(705,'U018',30,'Absent',FALSE,0.00),
(706,'U018',31,'Present',FALSE,3.00),
(707,'U018',32,'Present',FALSE,3.00),
(708,'U018',33,'Absent',FALSE,0.00),
(709,'U018',34,'Absent',FALSE,0.00),
(710,'U018',35,'Present',FALSE,3.00),
(711,'U018',36,'Present',FALSE,3.00),
(712,'U018',37,'Present',FALSE,3.00),
(713,'U018',38,'Present',FALSE,3.00),
(714,'U018',39,'Present',FALSE,3.00),
(715,'U018',40,'Present',FALSE,3.00),
(716,'U018',41,'Absent',FALSE,0.00),
(717,'U018',42,'Present',FALSE,3.00),
(718,'U018',43,'Present',FALSE,3.00),
(719,'U018',44,'Present',FALSE,3.00),
(720,'U018',45,'Present',FALSE,3.00),
(721,'U018',46,'Present',FALSE,3.00),
(722,'U018',47,'Present',FALSE,3.00),
(723,'U018',48,'Present',FALSE,3.00),
(724,'U018',49,'Present',FALSE,3.00),
(725,'U018',50,'Present',FALSE,3.00),
(726,'U018',51,'Present',FALSE,3.00),
(727,'U018',52,'Present',FALSE,3.00),
(728,'U018',53,'Present',FALSE,3.00),
(729,'U018',54,'Absent',FALSE,0.00),
(730,'U018',55,'Present',FALSE,3.00),
(731,'U018',56,'Present',FALSE,3.00),
(732,'U018',57,'Present',FALSE,3.00),
(733,'U018',58,'Present',FALSE,3.00),
(734,'U018',59,'Present',FALSE,3.00),
(735,'U018',60,'Absent',FALSE,0.00),
(736,'U018',61,'Present',FALSE,3.00),
(737,'U018',62,'Present',FALSE,3.00),
(738,'U018',63,'Absent',FALSE,0.00),
(739,'U018',64,'Present',FALSE,3.00),
(740,'U018',65,'Present',FALSE,3.00),
(741,'U018',66,'Present',FALSE,3.00),
(742,'U018',67,'Present',FALSE,3.00),
(743,'U018',68,'Present',FALSE,3.00),
(744,'U018',69,'Present',FALSE,3.00),
(745,'U018',70,'Present',FALSE,3.00),
(746,'U018',71,'Present',FALSE,3.00),
(747,'U018',72,'Present',FALSE,3.00),
(748,'U018',73,'Absent',FALSE,3.00),
(749,'U018',74,'Absent',FALSE,0.00),
(750,'U018',75,'Present',FALSE,3.00),
(751,'U018',76,'Present',FALSE,3.00),
(752,'U018',77,'Present',FALSE,3.00),
(753,'U018',78,'Absent',FALSE,0.00),
(754,'U018',79,'Present',FALSE,3.00),
(755,'U018',80,'Present',FALSE,3.00),
(756,'U018',81,'Present',FALSE,3.00),
(757,'U018',82,'Present',FALSE,3.00),
(758,'U018',83,'Present',FALSE,3.00),
(759,'U018',84,'Present',FALSE,3.00),
(760,'U018',85,'Absent',FALSE,0.00),
(761,'U018',86,'Absent',FALSE,0.00),
(762,'U018',87,'Present',FALSE,3.00),
(763,'U018',88,'Present',FALSE,3.00),
(764,'U018',89,'Present',FALSE,3.00),
(765,'U018',90,'Present',FALSE,3.00),
(766,'U018',91,'Present',FALSE,3.00),
(767,'U018',92,'Present',FALSE,3.00),
(768,'U018',93,'Present',FALSE,3.00),
(769,'U018',94,'Present',FALSE,3.00),
(770,'U018',95,'Absent',FALSE,0.00),
(771,'U018',96,'Present',FALSE,3.00),
(772,'U018',97,'Present',FALSE,3.00),
(773,'U018',98,'Present',FALSE,3.00),
(774,'U018',99,'Absent',FALSE,0.00),
(775,'U018',100,'Present',FALSE,3.00),
(776,'U018',101,'Present',FALSE,3.00),
(777,'U018',102,'Present',FALSE,3.00),
(778,'U018',103,'Present',FALSE,3.00),
(779,'U018',104,'Present',FALSE,3.00),
(780,'U018',105,'Present',FALSE,3.00),
(781,'U018',106,'Absent',FALSE,0.00),
(782,'U018',107,'Present',FALSE,2.00),
(783,'U018',108,'Present',FALSE,2.00),
(784,'U018',109,'Present',FALSE,2.00),
(785,'U018',110,'Present',FALSE,2.00),
(786,'U018',111,'Present',FALSE,2.00),
(787,'U018',112,'Absent',FALSE,0.00),
(788,'U018',113,'Present',FALSE,2.00),
(789,'U018',114,'Present',FALSE,2.00),
(790,'U018',115,'Present',FALSE,2.00),
(791,'U018',116,'Present',FALSE,2.00),
(792,'U018',117,'Absent',FALSE,2.00),
(793,'U018',118,'Present',FALSE,2.00),
(794,'U018',119,'Present',FALSE,2.00),
(795,'U018',120,'Present',FALSE,2.00),
(796,'U018',121,'Present',FALSE,3.00),
(797,'U018',122,'Present',FALSE,3.00),
(798,'U018',123,'Present',FALSE,3.00),
(799,'U018',124,'Present',FALSE,3.00),
(800,'U018',125,'Present',FALSE,3.00),
(801,'U018',126,'Present',FALSE,3.00),
(802,'U018',127,'Present',FALSE,3.00),
(803,'U018',128,'Present',FALSE,3.00),
(804,'U018',129,'Present',FALSE,3.00),
(805,'U018',130,'Present',FALSE,3.00),
(806,'U018',131,'Present',FALSE,3.00),
(807,'U018',132,'Present',FALSE,3.00),
(808,'U018',133,'Absent',FALSE,0.00),
(809,'U018',134,'Present',FALSE,3.00),
(810,'U018',135,'Present',FALSE,3.00),
(811,'U019',1,'Present',FALSE,3.00),
(812,'U019',2,'Present',FALSE,3.00),
(813,'U019',3,'Present',FALSE,3.00),
(814,'U019',4,'Present',FALSE,3.00),
(815,'U019',5,'Present',FALSE,3.00),
(816,'U019',6,'Present',FALSE,3.00),
(817,'U019',7,'Present',FALSE,3.00),
(818,'U019',8,'Present',FALSE,3.00),
(819,'U019',9,'Present',FALSE,3.00),
(820,'U019',10,'Absent',FALSE,0.00),
(821,'U019',11,'Present',FALSE,3.00),
(822,'U019',12,'Present',FALSE,3.00),
(823,'U019',13,'Present',FALSE,3.00),
(824,'U019',14,'Present',FALSE,3.00),
(825,'U019',15,'Present',FALSE,3.00),
(826,'U019',16,'Present',FALSE,3.00),
(827,'U019',17,'Present',FALSE,3.00),
(828,'U019',18,'Present',FALSE,3.00),
(829,'U019',19,'Present',FALSE,3.00),
(830,'U019',20,'Present',FALSE,3.00),
(831,'U019',21,'Present',FALSE,3.00),
(832,'U019',22,'Present',FALSE,3.00),
(833,'U019',23,'Present',FALSE,3.00),
(834,'U019',24,'Present',FALSE,3.00),
(835,'U019',25,'Absent',FALSE,0.00),
(836,'U019',26,'Absent',FALSE,3.00),
(837,'U019',27,'Present',FALSE,3.00),
(838,'U019',28,'Present',FALSE,3.00),
(839,'U019',29,'Present',FALSE,3.00),
(840,'U019',30,'Present',FALSE,3.00),
(841,'U019',31,'Present',FALSE,3.00),
(842,'U019',32,'Present',FALSE,3.00),
(843,'U019',33,'Present',FALSE,3.00),
(844,'U019',34,'Absent',FALSE,0.00),
(845,'U019',35,'Present',FALSE,3.00),
(846,'U019',36,'Present',FALSE,3.00),
(847,'U019',37,'Present',FALSE,3.00),
(848,'U019',38,'Present',FALSE,3.00),
(849,'U019',39,'Present',FALSE,3.00),
(850,'U019',40,'Present',FALSE,3.00),
(851,'U019',41,'Present',FALSE,3.00),
(852,'U019',42,'Present',FALSE,3.00),
(853,'U019',43,'Present',FALSE,3.00),
(854,'U019',44,'Present',FALSE,3.00),
(855,'U019',45,'Present',FALSE,3.00),
(856,'U019',46,'Present',FALSE,3.00),
(857,'U019',47,'Present',FALSE,3.00),
(858,'U019',48,'Absent',FALSE,0.00),
(859,'U019',49,'Present',FALSE,3.00),
(860,'U019',50,'Present',FALSE,3.00),
(861,'U019',51,'Present',FALSE,3.00),
(862,'U019',52,'Present',FALSE,3.00),
(863,'U019',53,'Present',FALSE,3.00),
(864,'U019',54,'Present',FALSE,3.00),
(865,'U019',55,'Absent',FALSE,0.00),
(866,'U019',56,'Present',FALSE,3.00),
(867,'U019',57,'Present',FALSE,3.00),
(868,'U019',58,'Present',FALSE,3.00),
(869,'U019',59,'Present',FALSE,3.00),
(870,'U019',60,'Present',FALSE,3.00),
(871,'U019',61,'Present',FALSE,3.00),
(872,'U019',62,'Present',FALSE,3.00),
(873,'U019',63,'Present',FALSE,3.00),
(874,'U019',64,'Present',FALSE,3.00),
(875,'U019',65,'Present',FALSE,3.00),
(876,'U019',66,'Present',FALSE,3.00),
(877,'U019',67,'Present',FALSE,3.00),
(878,'U019',68,'Present',FALSE,3.00),
(879,'U019',69,'Present',FALSE,3.00),
(880,'U019',70,'Present',FALSE,3.00),
(881,'U019',71,'Absent',FALSE,0.00),
(882,'U019',72,'Present',FALSE,3.00),
(883,'U019',73,'Absent',FALSE,0.00),
(884,'U019',74,'Present',FALSE,3.00),
(885,'U019',75,'Present',FALSE,3.00),
(886,'U019',76,'Present',FALSE,3.00),
(887,'U019',77,'Present',FALSE,3.00),
(888,'U019',78,'Present',FALSE,3.00),
(889,'U019',79,'Present',FALSE,3.00),
(890,'U019',80,'Present',FALSE,3.00),
(891,'U019',81,'Present',FALSE,3.00),
(892,'U019',82,'Absent',FALSE,0.00),
(893,'U019',83,'Present',FALSE,3.00),
(894,'U019',84,'Present',FALSE,3.00),
(895,'U019',85,'Absent',FALSE,3.00),
(896,'U019',86,'Present',FALSE,3.00),
(897,'U019',87,'Present',FALSE,3.00),
(898,'U019',88,'Present',FALSE,3.00),
(899,'U019',89,'Present',FALSE,3.00),
(900,'U019',90,'Present',FALSE,3.00),
(901,'U019',91,'Present',FALSE,3.00),
(902,'U019',92,'Present',FALSE,3.00),
(903,'U019',93,'Present',FALSE,3.00),
(904,'U019',94,'Absent',FALSE,0.00),
(905,'U019',95,'Present',FALSE,3.00),
(906,'U019',96,'Present',FALSE,3.00),
(907,'U019',97,'Present',FALSE,3.00),
(908,'U019',98,'Present',FALSE,3.00),
(909,'U019',99,'Present',FALSE,3.00),
(910,'U019',100,'Present',FALSE,3.00),
(911,'U019',101,'Present',FALSE,3.00),
(912,'U019',102,'Present',FALSE,3.00),
(913,'U019',103,'Present',FALSE,3.00),
(914,'U019',104,'Present',FALSE,3.00),
(915,'U019',105,'Present',FALSE,3.00),
(916,'U019',106,'Absent',FALSE,0.00),
(917,'U019',107,'Present',FALSE,2.00),
(918,'U019',108,'Absent',FALSE,0.00),
(919,'U019',109,'Present',FALSE,2.00),
(920,'U019',110,'Present',FALSE,2.00),
(921,'U019',111,'Present',FALSE,2.00),
(922,'U019',112,'Present',FALSE,2.00),
(923,'U019',113,'Present',FALSE,2.00),
(924,'U019',114,'Present',FALSE,2.00),
(925,'U019',115,'Present',FALSE,2.00),
(926,'U019',116,'Present',FALSE,2.00),
(927,'U019',117,'Absent',FALSE,0.00),
(928,'U019',118,'Present',FALSE,2.00),
(929,'U019',119,'Absent',FALSE,0.00),
(930,'U019',120,'Present',FALSE,2.00),
(931,'U019',121,'Present',FALSE,3.00),
(932,'U019',122,'Absent',FALSE,0.00),
(933,'U019',123,'Absent',FALSE,0.00),
(934,'U019',124,'Present',FALSE,3.00),
(935,'U019',125,'Present',FALSE,3.00),
(936,'U019',126,'Present',FALSE,3.00),
(937,'U019',127,'Present',FALSE,3.00),
(938,'U019',128,'Present',FALSE,3.00),
(939,'U019',129,'Absent',FALSE,3.00),
(940,'U019',130,'Present',FALSE,3.00),
(941,'U019',131,'Present',FALSE,3.00),
(942,'U019',132,'Present',FALSE,3.00),
(943,'U019',133,'Present',FALSE,3.00),
(944,'U019',134,'Absent',FALSE,0.00),
(945,'U019',135,'Present',FALSE,3.00),
(946,'U020',1,'Present',FALSE,3.00),
(947,'U020',2,'Absent',FALSE,0.00),
(948,'U020',3,'Present',FALSE,3.00),
(949,'U020',4,'Present',FALSE,3.00),
(950,'U020',5,'Present',FALSE,3.00),
(951,'U020',6,'Present',FALSE,3.00),
(952,'U020',7,'Absent',FALSE,3.00),
(953,'U020',8,'Present',FALSE,3.00),
(954,'U020',9,'Present',FALSE,3.00),
(955,'U020',10,'Present',FALSE,3.00),
(956,'U020',11,'Present',FALSE,3.00),
(957,'U020',12,'Present',FALSE,3.00),
(958,'U020',13,'Absent',FALSE,0.00),
(959,'U020',14,'Present',FALSE,3.00),
(960,'U020',15,'Present',FALSE,3.00),
(961,'U020',16,'Present',FALSE,3.00),
(962,'U020',17,'Present',FALSE,3.00),
(963,'U020',18,'Present',FALSE,3.00),
(964,'U020',19,'Absent',FALSE,0.00),
(965,'U020',20,'Present',FALSE,3.00),
(966,'U020',21,'Present',FALSE,3.00),
(967,'U020',22,'Present',FALSE,3.00),
(968,'U020',23,'Present',FALSE,3.00),
(969,'U020',24,'Present',FALSE,3.00),
(970,'U020',25,'Present',FALSE,3.00),
(971,'U020',26,'Present',FALSE,3.00),
(972,'U020',27,'Present',FALSE,3.00),
(973,'U020',28,'Absent',FALSE,0.00),
(974,'U020',29,'Present',FALSE,3.00),
(975,'U020',30,'Present',FALSE,3.00),
(976,'U020',31,'Present',FALSE,3.00),
(977,'U020',32,'Present',FALSE,3.00),
(978,'U020',33,'Present',FALSE,3.00),
(979,'U020',34,'Present',FALSE,3.00),
(980,'U020',35,'Absent',FALSE,0.00),
(981,'U020',36,'Present',FALSE,3.00),
(982,'U020',37,'Absent',FALSE,0.00),
(983,'U020',38,'Present',FALSE,3.00),
(984,'U020',39,'Present',FALSE,3.00),
(985,'U020',40,'Present',FALSE,3.00),
(986,'U020',41,'Absent',FALSE,0.00),
(987,'U020',42,'Absent',FALSE,0.00),
(988,'U020',43,'Present',FALSE,3.00),
(989,'U020',44,'Present',FALSE,3.00),
(990,'U020',45,'Present',FALSE,3.00),
(991,'U020',46,'Present',FALSE,3.00),
(992,'U020',47,'Absent',FALSE,0.00),
(993,'U020',48,'Present',FALSE,3.00),
(994,'U020',49,'Present',FALSE,3.00),
(995,'U020',50,'Absent',FALSE,0.00),
(996,'U020',51,'Present',FALSE,3.00),
(997,'U020',52,'Present',FALSE,3.00),
(998,'U020',53,'Present',FALSE,3.00),
(999,'U020',54,'Present',FALSE,3.00),
(1000,'U020',55,'Present',FALSE,3.00),
(1001,'U020',56,'Present',FALSE,3.00),
(1002,'U020',57,'Present',FALSE,3.00),
(1003,'U020',58,'Present',FALSE,3.00),
(1004,'U020',59,'Present',FALSE,3.00),
(1005,'U020',60,'Absent',FALSE,3.00),
(1006,'U020',61,'Present',FALSE,3.00),
(1007,'U020',62,'Absent',FALSE,0.00),
(1008,'U020',63,'Absent',FALSE,0.00),
(1009,'U020',64,'Present',FALSE,3.00),
(1010,'U020',65,'Present',FALSE,3.00),
(1011,'U020',66,'Present',FALSE,3.00),
(1012,'U020',67,'Present',FALSE,3.00),
(1013,'U020',68,'Present',FALSE,3.00),
(1014,'U020',69,'Present',FALSE,3.00),
(1015,'U020',70,'Present',FALSE,3.00),
(1016,'U020',71,'Present',FALSE,3.00),
(1017,'U020',72,'Present',FALSE,3.00),
(1018,'U020',73,'Present',FALSE,3.00),
(1019,'U020',74,'Present',FALSE,3.00),
(1020,'U020',75,'Present',FALSE,3.00),
(1021,'U020',76,'Present',FALSE,3.00),
(1022,'U020',77,'Present',FALSE,3.00),
(1023,'U020',78,'Present',FALSE,3.00),
(1024,'U020',79,'Present',FALSE,3.00),
(1025,'U020',80,'Present',FALSE,3.00),
(1026,'U020',81,'Present',FALSE,3.00),
(1027,'U020',82,'Present',FALSE,3.00),
(1028,'U020',83,'Present',FALSE,3.00),
(1029,'U020',84,'Present',FALSE,3.00),
(1030,'U020',85,'Absent',FALSE,0.00),
(1031,'U020',86,'Present',FALSE,3.00),
(1032,'U020',87,'Present',FALSE,3.00),
(1033,'U020',88,'Present',FALSE,3.00),
(1034,'U020',89,'Present',FALSE,3.00),
(1035,'U020',90,'Absent',FALSE,0.00),
(1036,'U020',91,'Present',FALSE,3.00),
(1037,'U020',92,'Present',FALSE,3.00),
(1038,'U020',93,'Present',FALSE,3.00),
(1039,'U020',94,'Present',FALSE,3.00),
(1040,'U020',95,'Absent',TRUE,3.00),
(1041,'U020',96,'Present',FALSE,3.00),
(1042,'U020',97,'Present',FALSE,3.00),
(1043,'U020',98,'Present',FALSE,3.00),
(1044,'U020',99,'Present',FALSE,3.00),
(1045,'U020',100,'Present',FALSE,3.00),
(1046,'U020',101,'Present',FALSE,3.00),
(1047,'U020',102,'Present',FALSE,3.00),
(1048,'U020',103,'Present',FALSE,3.00),
(1049,'U020',104,'Present',FALSE,3.00),
(1050,'U020',105,'Present',FALSE,3.00),
(1051,'U020',106,'Present',FALSE,2.00),
(1052,'U020',107,'Present',FALSE,2.00),
(1053,'U020',108,'Present',FALSE,2.00),
(1054,'U020',109,'Present',FALSE,2.00),
(1055,'U020',110,'Present',FALSE,2.00),
(1056,'U020',111,'Present',FALSE,2.00),
(1057,'U020',112,'Present',FALSE,2.00),
(1058,'U020',113,'Present',FALSE,2.00),
(1059,'U020',114,'Present',FALSE,2.00),
(1060,'U020',115,'Present',FALSE,2.00),
(1061,'U020',116,'Present',FALSE,2.00),
(1062,'U020',117,'Present',FALSE,2.00),
(1063,'U020',118,'Present',FALSE,2.00),
(1064,'U020',119,'Present',FALSE,2.00),
(1065,'U020',120,'Present',FALSE,2.00),
(1066,'U020',121,'Absent',FALSE,3.00),
(1067,'U020',122,'Present',FALSE,3.00),
(1068,'U020',123,'Absent',FALSE,0.00),
(1069,'U020',124,'Present',FALSE,3.00),
(1070,'U020',125,'Present',FALSE,3.00),
(1071,'U020',126,'Present',FALSE,3.00),
(1072,'U020',127,'Present',FALSE,3.00),
(1073,'U020',128,'Present',FALSE,3.00),
(1074,'U020',129,'Present',FALSE,3.00),
(1075,'U020',130,'Present',FALSE,3.00),
(1076,'U020',131,'Present',FALSE,3.00),
(1077,'U020',132,'Present',FALSE,3.00),
(1078,'U020',133,'Absent',FALSE,0.00),
(1079,'U020',134,'Present',FALSE,3.00),
(1080,'U020',135,'Present',FALSE,3.00),
(1081,'U021',1,'Present',FALSE,3.00),
(1082,'U021',2,'Present',FALSE,3.00),
(1083,'U021',3,'Absent',FALSE,0.00),
(1084,'U021',4,'Present',FALSE,3.00),
(1085,'U021',5,'Present',FALSE,3.00),
(1086,'U021',6,'Present',FALSE,3.00),
(1087,'U021',7,'Present',FALSE,3.00),
(1088,'U021',8,'Present',FALSE,3.00),
(1089,'U021',9,'Present',FALSE,3.00),
(1090,'U021',10,'Present',FALSE,3.00),
(1091,'U021',11,'Present',FALSE,3.00),
(1092,'U021',12,'Present',FALSE,3.00),
(1093,'U021',13,'Present',FALSE,3.00),
(1094,'U021',14,'Present',FALSE,3.00),
(1095,'U021',15,'Present',FALSE,3.00),
(1096,'U021',16,'Present',FALSE,3.00),
(1097,'U021',17,'Absent',FALSE,0.00),
(1098,'U021',18,'Present',FALSE,3.00),
(1099,'U021',19,'Present',FALSE,3.00),
(1100,'U021',20,'Present',FALSE,3.00),
(1101,'U021',21,'Present',FALSE,3.00),
(1102,'U021',22,'Absent',FALSE,0.00),
(1103,'U021',23,'Present',FALSE,3.00),
(1104,'U021',24,'Present',FALSE,3.00),
(1105,'U021',25,'Present',FALSE,3.00),
(1106,'U021',26,'Present',FALSE,3.00),
(1107,'U021',27,'Present',FALSE,3.00),
(1108,'U021',28,'Present',FALSE,3.00),
(1109,'U021',29,'Present',FALSE,3.00),
(1110,'U021',30,'Present',FALSE,3.00),
(1111,'U021',31,'Present',FALSE,3.00),
(1112,'U021',32,'Present',FALSE,3.00),
(1113,'U021',33,'Present',FALSE,3.00),
(1114,'U021',34,'Present',FALSE,3.00),
(1115,'U021',35,'Present',FALSE,3.00),
(1116,'U021',36,'Present',FALSE,3.00),
(1117,'U021',37,'Present',FALSE,3.00),
(1118,'U021',38,'Present',FALSE,3.00),
(1119,'U021',39,'Present',FALSE,3.00),
(1120,'U021',40,'Present',FALSE,3.00),
(1121,'U021',41,'Present',FALSE,3.00),
(1122,'U021',42,'Present',FALSE,3.00),
(1123,'U021',43,'Present',FALSE,3.00),
(1124,'U021',44,'Present',FALSE,3.00),
(1125,'U021',45,'Present',FALSE,3.00),
(1126,'U021',46,'Present',FALSE,3.00),
(1127,'U021',47,'Present',FALSE,3.00),
(1128,'U021',48,'Present',FALSE,3.00),
(1129,'U021',49,'Present',FALSE,3.00),
(1130,'U021',50,'Present',FALSE,3.00),
(1131,'U021',51,'Present',FALSE,3.00),
(1132,'U021',52,'Present',FALSE,3.00),
(1133,'U021',53,'Present',FALSE,3.00),
(1134,'U021',54,'Present',FALSE,3.00),
(1135,'U021',55,'Present',FALSE,3.00),
(1136,'U021',56,'Present',FALSE,3.00),
(1137,'U021',57,'Present',FALSE,3.00),
(1138,'U021',58,'Present',FALSE,3.00),
(1139,'U021',59,'Present',FALSE,3.00),
(1140,'U021',60,'Present',FALSE,3.00),
(1141,'U021',61,'Present',FALSE,3.00),
(1142,'U021',62,'Present',FALSE,3.00),
(1143,'U021',63,'Present',FALSE,3.00),
(1144,'U021',64,'Present',FALSE,3.00),
(1145,'U021',65,'Present',FALSE,3.00),
(1146,'U021',66,'Present',FALSE,3.00),
(1147,'U021',67,'Present',FALSE,3.00),
(1148,'U021',68,'Present',FALSE,3.00),
(1149,'U021',69,'Present',FALSE,3.00),
(1150,'U021',70,'Present',FALSE,3.00),
(1151,'U021',71,'Present',FALSE,3.00),
(1152,'U021',72,'Present',FALSE,3.00),
(1153,'U021',73,'Present',FALSE,3.00),
(1154,'U021',74,'Present',FALSE,3.00),
(1155,'U021',75,'Present',FALSE,3.00),
(1156,'U021',76,'Present',FALSE,3.00),
(1157,'U021',77,'Present',FALSE,3.00),
(1158,'U021',78,'Present',FALSE,3.00),
(1159,'U021',79,'Present',FALSE,3.00),
(1160,'U021',80,'Present',FALSE,3.00),
(1161,'U021',81,'Present',FALSE,3.00),
(1162,'U021',82,'Absent',FALSE,0.00),
(1163,'U021',83,'Present',FALSE,3.00),
(1164,'U021',84,'Present',FALSE,3.00),
(1165,'U021',85,'Present',FALSE,3.00),
(1166,'U021',86,'Present',FALSE,3.00),
(1167,'U021',87,'Present',FALSE,3.00),
(1168,'U021',88,'Present',FALSE,3.00),
(1169,'U021',89,'Present',FALSE,3.00),
(1170,'U021',90,'Present',FALSE,3.00),
(1171,'U021',91,'Absent',FALSE,3.00),
(1172,'U021',92,'Present',FALSE,3.00),
(1173,'U021',93,'Present',FALSE,3.00),
(1174,'U021',94,'Absent',FALSE,0.00),
(1175,'U021',95,'Present',FALSE,3.00),
(1176,'U021',96,'Present',FALSE,3.00),
(1177,'U021',97,'Present',FALSE,3.00),
(1178,'U021',98,'Present',FALSE,3.00),
(1179,'U021',99,'Present',FALSE,3.00),
(1180,'U021',100,'Present',FALSE,3.00),
(1181,'U021',101,'Present',FALSE,3.00),
(1182,'U021',102,'Present',FALSE,3.00),
(1183,'U021',103,'Present',FALSE,3.00),
(1184,'U021',104,'Present',FALSE,3.00),
(1185,'U021',105,'Present',FALSE,3.00),
(1186,'U021',106,'Absent',FALSE,2.00),
(1187,'U021',107,'Present',FALSE,2.00),
(1188,'U021',108,'Absent',FALSE,0.00),
(1189,'U021',109,'Absent',FALSE,2.00),
(1190,'U021',110,'Present',FALSE,2.00),
(1191,'U021',111,'Present',FALSE,2.00),
(1192,'U021',112,'Present',FALSE,2.00),
(1193,'U021',113,'Present',FALSE,2.00),
(1194,'U021',114,'Present',FALSE,2.00),
(1195,'U021',115,'Present',FALSE,2.00),
(1196,'U021',116,'Present',FALSE,2.00),
(1197,'U021',117,'Present',FALSE,2.00),
(1198,'U021',118,'Present',FALSE,2.00),
(1199,'U021',119,'Present',FALSE,2.00),
(1200,'U021',120,'Present',FALSE,2.00),
(1201,'U021',121,'Present',FALSE,3.00),
(1202,'U021',122,'Present',FALSE,3.00),
(1203,'U021',123,'Present',FALSE,3.00),
(1204,'U021',124,'Present',FALSE,3.00),
(1205,'U021',125,'Absent',FALSE,0.00),
(1206,'U021',126,'Present',FALSE,3.00),
(1207,'U021',127,'Present',FALSE,3.00),
(1208,'U021',128,'Present',FALSE,3.00),
(1209,'U021',129,'Present',FALSE,3.00),
(1210,'U021',130,'Present',FALSE,3.00),
(1211,'U021',131,'Absent',TRUE,3.00),
(1212,'U021',132,'Present',FALSE,3.00),
(1213,'U021',133,'Present',FALSE,3.00),
(1214,'U021',134,'Present',FALSE,3.00),
(1215,'U021',135,'Present',FALSE,3.00),
(1216,'U022',1,'Present',FALSE,3.00),
(1217,'U022',2,'Present',FALSE,3.00),
(1218,'U022',3,'Present',FALSE,3.00),
(1219,'U022',4,'Present',FALSE,3.00),
(1220,'U022',5,'Present',FALSE,3.00),
(1221,'U022',6,'Present',FALSE,3.00),
(1222,'U022',7,'Absent',FALSE,0.00),
(1223,'U022',8,'Present',FALSE,3.00),
(1224,'U022',9,'Present',FALSE,3.00),
(1225,'U022',10,'Present',FALSE,3.00),
(1226,'U022',11,'Present',FALSE,3.00),
(1227,'U022',12,'Absent',FALSE,0.00),
(1228,'U022',13,'Present',FALSE,3.00),
(1229,'U022',14,'Present',FALSE,3.00),
(1230,'U022',15,'Absent',FALSE,3.00),
(1231,'U022',16,'Present',FALSE,3.00),
(1232,'U022',17,'Present',FALSE,3.00),
(1233,'U022',18,'Present',FALSE,3.00),
(1234,'U022',19,'Present',FALSE,3.00),
(1235,'U022',20,'Absent',FALSE,0.00),
(1236,'U022',21,'Present',FALSE,3.00),
(1237,'U022',22,'Present',FALSE,3.00),
(1238,'U022',23,'Present',FALSE,3.00),
(1239,'U022',24,'Absent',FALSE,0.00),
(1240,'U022',25,'Present',FALSE,3.00),
(1241,'U022',26,'Present',FALSE,3.00),
(1242,'U022',27,'Present',FALSE,3.00),
(1243,'U022',28,'Present',FALSE,3.00),
(1244,'U022',29,'Absent',FALSE,0.00),
(1245,'U022',30,'Present',FALSE,3.00),
(1246,'U022',31,'Present',FALSE,3.00),
(1247,'U022',32,'Present',FALSE,3.00),
(1248,'U022',33,'Absent',FALSE,0.00),
(1249,'U022',34,'Present',FALSE,3.00),
(1250,'U022',35,'Present',FALSE,3.00),
(1251,'U022',36,'Present',FALSE,3.00),
(1252,'U022',37,'Present',FALSE,3.00),
(1253,'U022',38,'Present',FALSE,3.00),
(1254,'U022',39,'Present',FALSE,3.00),
(1255,'U022',40,'Present',FALSE,3.00),
(1256,'U022',41,'Present',FALSE,3.00),
(1257,'U022',42,'Present',FALSE,3.00),
(1258,'U022',43,'Present',FALSE,3.00),
(1259,'U022',44,'Present',FALSE,3.00),
(1260,'U022',45,'Absent',FALSE,0.00),
(1261,'U022',46,'Present',FALSE,3.00),
(1262,'U022',47,'Present',FALSE,3.00),
(1263,'U022',48,'Present',FALSE,3.00),
(1264,'U022',49,'Present',FALSE,3.00),
(1265,'U022',50,'Absent',FALSE,0.00),
(1266,'U022',51,'Present',FALSE,3.00),
(1267,'U022',52,'Present',FALSE,3.00),
(1268,'U022',53,'Present',FALSE,3.00),
(1269,'U022',54,'Present',FALSE,3.00),
(1270,'U022',55,'Present',FALSE,3.00),
(1271,'U022',56,'Present',FALSE,3.00),
(1272,'U022',57,'Present',FALSE,3.00),
(1273,'U022',58,'Present',FALSE,3.00),
(1274,'U022',59,'Present',FALSE,3.00),
(1275,'U022',60,'Present',FALSE,3.00),
(1276,'U022',61,'Present',FALSE,3.00),
(1277,'U022',62,'Absent',FALSE,0.00),
(1278,'U022',63,'Absent',FALSE,0.00),
(1279,'U022',64,'Absent',FALSE,0.00),
(1280,'U022',65,'Present',FALSE,3.00),
(1281,'U022',66,'Present',FALSE,3.00),
(1282,'U022',67,'Present',FALSE,3.00),
(1283,'U022',68,'Present',FALSE,3.00),
(1284,'U022',69,'Present',FALSE,3.00),
(1285,'U022',70,'Absent',FALSE,0.00),
(1286,'U022',71,'Present',FALSE,3.00),
(1287,'U022',72,'Present',FALSE,3.00),
(1288,'U022',73,'Present',FALSE,3.00),
(1289,'U022',74,'Absent',FALSE,0.00),
(1290,'U022',75,'Present',FALSE,3.00),
(1291,'U022',76,'Present',FALSE,3.00),
(1292,'U022',77,'Present',FALSE,3.00),
(1293,'U022',78,'Present',FALSE,3.00),
(1294,'U022',79,'Present',FALSE,3.00),
(1295,'U022',80,'Present',FALSE,3.00),
(1296,'U022',81,'Present',FALSE,3.00),
(1297,'U022',82,'Present',FALSE,3.00),
(1298,'U022',83,'Present',FALSE,3.00),
(1299,'U022',84,'Present',FALSE,3.00),
(1300,'U022',85,'Present',FALSE,3.00),
(1301,'U022',86,'Present',FALSE,3.00),
(1302,'U022',87,'Present',FALSE,3.00),
(1303,'U022',88,'Present',FALSE,3.00),
(1304,'U022',89,'Present',FALSE,3.00),
(1305,'U022',90,'Absent',FALSE,0.00),
(1306,'U022',91,'Absent',FALSE,3.00),
(1307,'U022',92,'Present',FALSE,3.00),
(1308,'U022',93,'Present',FALSE,3.00),
(1309,'U022',94,'Present',FALSE,3.00),
(1310,'U022',95,'Absent',FALSE,0.00),
(1311,'U022',96,'Present',FALSE,3.00),
(1312,'U022',97,'Present',FALSE,3.00),
(1313,'U022',98,'Present',FALSE,3.00),
(1314,'U022',99,'Present',FALSE,3.00),
(1315,'U022',100,'Present',FALSE,3.00),
(1316,'U022',101,'Absent',FALSE,0.00),
(1317,'U022',102,'Present',FALSE,3.00),
(1318,'U022',103,'Absent',FALSE,0.00),
(1319,'U022',104,'Present',FALSE,3.00),
(1320,'U022',105,'Present',FALSE,3.00),
(1321,'U022',106,'Present',FALSE,2.00),
(1322,'U022',107,'Present',FALSE,2.00),
(1323,'U022',108,'Present',FALSE,2.00),
(1324,'U022',109,'Present',FALSE,2.00),
(1325,'U022',110,'Present',FALSE,2.00),
(1326,'U022',111,'Present',FALSE,2.00),
(1327,'U022',112,'Present',FALSE,2.00),
(1328,'U022',113,'Present',FALSE,2.00),
(1329,'U022',114,'Present',FALSE,2.00),
(1330,'U022',115,'Present',FALSE,2.00),
(1331,'U022',116,'Present',FALSE,2.00),
(1332,'U022',117,'Present',FALSE,2.00),
(1333,'U022',118,'Present',FALSE,2.00),
(1334,'U022',119,'Absent',FALSE,0.00),
(1335,'U022',120,'Present',FALSE,2.00),
(1336,'U022',121,'Present',FALSE,3.00),
(1337,'U022',122,'Present',FALSE,3.00),
(1338,'U022',123,'Present',FALSE,3.00),
(1339,'U022',124,'Present',FALSE,3.00),
(1340,'U022',125,'Present',FALSE,3.00),
(1341,'U022',126,'Present',FALSE,3.00),
(1342,'U022',127,'Present',FALSE,3.00),
(1343,'U022',128,'Present',FALSE,3.00),
(1344,'U022',129,'Absent',FALSE,0.00),
(1345,'U022',130,'Absent',FALSE,3.00),
(1346,'U022',131,'Present',FALSE,3.00),
(1347,'U022',132,'Absent',FALSE,0.00),
(1348,'U022',133,'Present',FALSE,3.00),
(1349,'U022',134,'Present',FALSE,3.00),
(1350,'U022',135,'Present',FALSE,3.00),
(1351,'U023',1,'Absent',FALSE,0.00),
(1352,'U023',2,'Present',FALSE,3.00),
(1353,'U023',3,'Present',FALSE,3.00),
(1354,'U023',4,'Absent',FALSE,0.00),
(1355,'U023',5,'Absent',FALSE,0.00),
(1356,'U023',6,'Present',FALSE,3.00),
(1357,'U023',7,'Absent',FALSE,0.00),
(1358,'U023',8,'Present',FALSE,3.00),
(1359,'U023',9,'Present',FALSE,3.00),
(1360,'U023',10,'Absent',FALSE,0.00),
(1361,'U023',11,'Absent',FALSE,0.00),
(1362,'U023',12,'Present',FALSE,3.00),
(1363,'U023',13,'Absent',FALSE,0.00),
(1364,'U023',14,'Present',FALSE,3.00),
(1365,'U023',15,'Present',FALSE,3.00),
(1366,'U023',16,'Present',FALSE,3.00),
(1367,'U023',17,'Present',FALSE,3.00),
(1368,'U023',18,'Absent',FALSE,0.00),
(1369,'U023',19,'Present',FALSE,3.00),
(1370,'U023',20,'Absent',FALSE,0.00),
(1371,'U023',21,'Present',FALSE,3.00),
(1372,'U023',22,'Present',FALSE,3.00),
(1373,'U023',23,'Present',FALSE,3.00),
(1374,'U023',24,'Present',FALSE,3.00),
(1375,'U023',25,'Present',FALSE,3.00),
(1376,'U023',26,'Present',FALSE,3.00),
(1377,'U023',27,'Absent',FALSE,0.00),
(1378,'U023',28,'Present',FALSE,3.00),
(1379,'U023',29,'Present',FALSE,3.00),
(1380,'U023',30,'Absent',FALSE,0.00),
(1381,'U023',31,'Present',FALSE,3.00),
(1382,'U023',32,'Present',FALSE,3.00),
(1383,'U023',33,'Present',FALSE,3.00),
(1384,'U023',34,'Present',FALSE,3.00),
(1385,'U023',35,'Present',FALSE,3.00),
(1386,'U023',36,'Present',FALSE,3.00),
(1387,'U023',37,'Present',FALSE,3.00),
(1388,'U023',38,'Present',FALSE,3.00),
(1389,'U023',39,'Present',FALSE,3.00),
(1390,'U023',40,'Present',FALSE,3.00),
(1391,'U023',41,'Present',FALSE,3.00),
(1392,'U023',42,'Absent',FALSE,0.00),
(1393,'U023',43,'Present',FALSE,3.00),
(1394,'U023',44,'Present',FALSE,3.00),
(1395,'U023',45,'Present',FALSE,3.00),
(1396,'U023',46,'Absent',FALSE,0.00),
(1397,'U023',47,'Present',FALSE,3.00),
(1398,'U023',48,'Present',FALSE,3.00),
(1399,'U023',49,'Present',FALSE,3.00),
(1400,'U023',50,'Present',FALSE,3.00),
(1401,'U023',51,'Absent',FALSE,0.00),
(1402,'U023',52,'Present',FALSE,3.00),
(1403,'U023',53,'Present',FALSE,3.00),
(1404,'U023',54,'Absent',FALSE,0.00),
(1405,'U023',55,'Present',FALSE,3.00),
(1406,'U023',56,'Absent',FALSE,0.00),
(1407,'U023',57,'Present',FALSE,3.00),
(1408,'U023',58,'Absent',FALSE,0.00),
(1409,'U023',59,'Absent',FALSE,0.00),
(1410,'U023',60,'Present',FALSE,3.00),
(1411,'U023',61,'Present',FALSE,3.00),
(1412,'U023',62,'Present',FALSE,3.00),
(1413,'U023',63,'Absent',FALSE,0.00),
(1414,'U023',64,'Present',FALSE,3.00),
(1415,'U023',65,'Absent',FALSE,0.00),
(1416,'U023',66,'Present',FALSE,3.00),
(1417,'U023',67,'Absent',FALSE,0.00),
(1418,'U023',68,'Present',FALSE,3.00),
(1419,'U023',69,'Absent',FALSE,0.00),
(1420,'U023',70,'Present',FALSE,3.00),
(1421,'U023',71,'Absent',FALSE,0.00),
(1422,'U023',72,'Present',FALSE,3.00),
(1423,'U023',73,'Present',FALSE,3.00),
(1424,'U023',74,'Present',FALSE,3.00),
(1425,'U023',75,'Present',FALSE,3.00),
(1426,'U023',76,'Present',FALSE,3.00),
(1427,'U023',77,'Absent',FALSE,0.00),
(1428,'U023',78,'Present',FALSE,3.00),
(1429,'U023',79,'Absent',FALSE,0.00),
(1430,'U023',80,'Present',FALSE,3.00),
(1431,'U023',81,'Present',FALSE,3.00),
(1432,'U023',82,'Absent',FALSE,0.00),
(1433,'U023',83,'Present',FALSE,3.00),
(1434,'U023',84,'Present',FALSE,3.00),
(1435,'U023',85,'Absent',FALSE,0.00),
(1436,'U023',86,'Absent',FALSE,0.00),
(1437,'U023',87,'Present',FALSE,3.00),
(1438,'U023',88,'Present',FALSE,3.00),
(1439,'U023',89,'Present',FALSE,3.00),
(1440,'U023',90,'Absent',FALSE,0.00),
(1441,'U023',91,'Absent',FALSE,0.00),
(1442,'U023',92,'Absent',FALSE,0.00),
(1443,'U023',93,'Present',FALSE,3.00),
(1444,'U023',94,'Absent',FALSE,0.00),
(1445,'U023',95,'Present',FALSE,3.00),
(1446,'U023',96,'Present',FALSE,3.00),
(1447,'U023',97,'Absent',FALSE,0.00),
(1448,'U023',98,'Present',FALSE,3.00),
(1449,'U023',99,'Absent',FALSE,3.00),
(1450,'U023',100,'Absent',FALSE,0.00),
(1451,'U023',101,'Present',FALSE,3.00),
(1452,'U023',102,'Present',FALSE,3.00),
(1453,'U023',103,'Absent',FALSE,0.00),
(1454,'U023',104,'Present',FALSE,3.00),
(1455,'U023',105,'Present',FALSE,3.00),
(1456,'U023',106,'Present',FALSE,2.00),
(1457,'U023',107,'Present',FALSE,2.00),
(1458,'U023',108,'Present',FALSE,2.00),
(1459,'U023',109,'Present',FALSE,2.00),
(1460,'U023',110,'Present',FALSE,2.00),
(1461,'U023',111,'Absent',FALSE,0.00),
(1462,'U023',112,'Present',FALSE,2.00),
(1463,'U023',113,'Present',FALSE,2.00),
(1464,'U023',114,'Absent',FALSE,0.00),
(1465,'U023',115,'Present',FALSE,2.00),
(1466,'U023',116,'Absent',FALSE,0.00),
(1467,'U023',117,'Present',FALSE,2.00),
(1468,'U023',118,'Absent',FALSE,0.00),
(1469,'U023',119,'Absent',FALSE,0.00),
(1470,'U023',120,'Present',FALSE,2.00),
(1471,'U023',121,'Present',FALSE,3.00),
(1472,'U023',122,'Present',FALSE,3.00),
(1473,'U023',123,'Absent',FALSE,0.00),
(1474,'U023',124,'Absent',FALSE,0.00),
(1475,'U023',125,'Absent',FALSE,0.00),
(1476,'U023',126,'Present',FALSE,3.00),
(1477,'U023',127,'Present',FALSE,3.00),
(1478,'U023',128,'Absent',FALSE,0.00),
(1479,'U023',129,'Present',FALSE,3.00),
(1480,'U023',130,'Present',FALSE,3.00),
(1481,'U023',131,'Absent',FALSE,0.00),
(1482,'U023',132,'Present',FALSE,3.00),
(1483,'U023',133,'Present',FALSE,3.00),
(1484,'U023',134,'Present',FALSE,3.00),
(1485,'U023',135,'Present',FALSE,3.00),
(1486,'U024',1,'Absent',FALSE,0.00),
(1487,'U024',2,'Present',FALSE,3.00),
(1488,'U024',3,'Absent',FALSE,0.00),
(1489,'U024',4,'Present',FALSE,3.00),
(1490,'U024',5,'Present',FALSE,3.00),
(1491,'U024',6,'Present',FALSE,3.00),
(1492,'U024',7,'Present',FALSE,3.00),
(1493,'U024',8,'Present',FALSE,3.00),
(1494,'U024',9,'Present',FALSE,3.00),
(1495,'U024',10,'Absent',FALSE,0.00),
(1496,'U024',11,'Present',FALSE,3.00),
(1497,'U024',12,'Present',FALSE,3.00),
(1498,'U024',13,'Present',FALSE,3.00),
(1499,'U024',14,'Present',FALSE,3.00),
(1500,'U024',15,'Present',FALSE,3.00),
(1501,'U024',16,'Present',FALSE,3.00),
(1502,'U024',17,'Absent',FALSE,0.00),
(1503,'U024',18,'Present',FALSE,3.00),
(1504,'U024',19,'Absent',FALSE,0.00),
(1505,'U024',20,'Present',FALSE,3.00),
(1506,'U024',21,'Present',FALSE,3.00),
(1507,'U024',22,'Absent',FALSE,0.00),
(1508,'U024',23,'Present',FALSE,3.00),
(1509,'U024',24,'Absent',FALSE,0.00),
(1510,'U024',25,'Present',FALSE,3.00),
(1511,'U024',26,'Present',FALSE,3.00),
(1512,'U024',27,'Absent',FALSE,0.00),
(1513,'U024',28,'Absent',FALSE,0.00),
(1514,'U024',29,'Present',FALSE,3.00),
(1515,'U024',30,'Present',FALSE,3.00),
(1516,'U024',31,'Present',FALSE,3.00),
(1517,'U024',32,'Present',FALSE,3.00),
(1518,'U024',33,'Absent',FALSE,0.00),
(1519,'U024',34,'Absent',FALSE,0.00),
(1520,'U024',35,'Absent',FALSE,0.00),
(1521,'U024',36,'Absent',FALSE,0.00),
(1522,'U024',37,'Present',FALSE,3.00),
(1523,'U024',38,'Absent',FALSE,0.00),
(1524,'U024',39,'Present',FALSE,3.00),
(1525,'U024',40,'Present',FALSE,3.00),
(1526,'U024',41,'Present',FALSE,3.00),
(1527,'U024',42,'Present',FALSE,3.00),
(1528,'U024',43,'Absent',FALSE,0.00),
(1529,'U024',44,'Present',FALSE,3.00),
(1530,'U024',45,'Present',FALSE,3.00),
(1531,'U024',46,'Present',FALSE,3.00),
(1532,'U024',47,'Absent',FALSE,0.00),
(1533,'U024',48,'Present',FALSE,3.00),
(1534,'U024',49,'Present',FALSE,3.00),
(1535,'U024',50,'Present',FALSE,3.00),
(1536,'U024',51,'Present',FALSE,3.00),
(1537,'U024',52,'Absent',FALSE,0.00),
(1538,'U024',53,'Absent',FALSE,0.00),
(1539,'U024',54,'Present',FALSE,3.00),
(1540,'U024',55,'Absent',FALSE,0.00),
(1541,'U024',56,'Absent',FALSE,0.00),
(1542,'U024',57,'Present',FALSE,3.00),
(1543,'U024',58,'Absent',FALSE,0.00),
(1544,'U024',59,'Present',FALSE,3.00),
(1545,'U024',60,'Present',FALSE,3.00),
(1546,'U024',61,'Absent',FALSE,0.00),
(1547,'U024',62,'Present',FALSE,3.00),
(1548,'U024',63,'Absent',FALSE,0.00),
(1549,'U024',64,'Absent',FALSE,0.00),
(1550,'U024',65,'Present',FALSE,3.00),
(1551,'U024',66,'Present',FALSE,3.00),
(1552,'U024',67,'Absent',FALSE,0.00),
(1553,'U024',68,'Present',FALSE,3.00),
(1554,'U024',69,'Absent',FALSE,0.00),
(1555,'U024',70,'Present',FALSE,3.00),
(1556,'U024',71,'Present',FALSE,3.00),
(1557,'U024',72,'Present',FALSE,3.00),
(1558,'U024',73,'Present',FALSE,3.00),
(1559,'U024',74,'Present',FALSE,3.00),
(1560,'U024',75,'Absent',FALSE,0.00),
(1561,'U024',76,'Present',FALSE,3.00),
(1562,'U024',77,'Absent',FALSE,0.00),
(1563,'U024',78,'Absent',FALSE,0.00),
(1564,'U024',79,'Absent',FALSE,0.00),
(1565,'U024',80,'Present',FALSE,3.00),
(1566,'U024',81,'Present',FALSE,3.00),
(1567,'U024',82,'Present',FALSE,3.00),
(1568,'U024',83,'Present',FALSE,3.00),
(1569,'U024',84,'Present',FALSE,3.00),
(1570,'U024',85,'Present',FALSE,3.00),
(1571,'U024',86,'Present',FALSE,3.00),
(1572,'U024',87,'Present',FALSE,3.00),
(1573,'U024',88,'Absent',FALSE,0.00),
(1574,'U024',89,'Present',FALSE,3.00),
(1575,'U024',90,'Present',FALSE,3.00),
(1576,'U024',91,'Absent',FALSE,0.00),
(1577,'U024',92,'Present',FALSE,3.00),
(1578,'U024',93,'Absent',FALSE,0.00),
(1579,'U024',94,'Present',FALSE,3.00),
(1580,'U024',95,'Absent',FALSE,0.00),
(1581,'U024',96,'Present',FALSE,3.00),
(1582,'U024',97,'Present',FALSE,3.00),
(1583,'U024',98,'Present',FALSE,3.00),
(1584,'U024',99,'Present',FALSE,3.00),
(1585,'U024',100,'Present',FALSE,3.00),
(1586,'U024',101,'Absent',FALSE,0.00),
(1587,'U024',102,'Present',FALSE,3.00),
(1588,'U024',103,'Present',FALSE,3.00),
(1589,'U024',104,'Present',FALSE,3.00),
(1590,'U024',105,'Present',FALSE,3.00),
(1591,'U024',106,'Present',FALSE,2.00),
(1592,'U024',107,'Absent',FALSE,0.00),
(1593,'U024',108,'Present',FALSE,2.00),
(1594,'U024',109,'Absent',FALSE,0.00),
(1595,'U024',110,'Absent',FALSE,0.00),
(1596,'U024',111,'Present',FALSE,2.00),
(1597,'U024',112,'Present',FALSE,2.00),
(1598,'U024',113,'Present',FALSE,2.00),
(1599,'U024',114,'Present',FALSE,2.00),
(1600,'U024',115,'Present',FALSE,2.00),
(1601,'U024',116,'Absent',FALSE,2.00),
(1602,'U024',117,'Present',FALSE,2.00),
(1603,'U024',118,'Present',FALSE,2.00),
(1604,'U024',119,'Absent',FALSE,0.00),
(1605,'U024',120,'Absent',FALSE,0.00),
(1606,'U024',121,'Absent',FALSE,0.00),
(1607,'U024',122,'Absent',FALSE,0.00),
(1608,'U024',123,'Present',FALSE,3.00),
(1609,'U024',124,'Present',FALSE,3.00),
(1610,'U024',125,'Present',FALSE,3.00),
(1611,'U024',126,'Present',FALSE,3.00),
(1612,'U024',127,'Present',FALSE,3.00),
(1613,'U024',128,'Present',FALSE,3.00),
(1614,'U024',129,'Present',FALSE,3.00),
(1615,'U024',130,'Present',FALSE,3.00),
(1616,'U024',131,'Present',FALSE,3.00),
(1617,'U024',132,'Present',FALSE,3.00),
(1618,'U024',133,'Present',FALSE,3.00),
(1619,'U024',134,'Present',FALSE,3.00),
(1620,'U024',135,'Absent',FALSE,0.00),
(1621,'U025',1,'Absent',FALSE,0.00),
(1622,'U025',2,'Absent',TRUE,0.00),
(1623,'U025',3,'Absent',FALSE,0.00),
(1624,'U025',4,'Present',FALSE,3.00),
(1625,'U025',5,'Present',FALSE,3.00),
(1626,'U025',6,'Absent',FALSE,0.00),
(1627,'U025',7,'Present',FALSE,3.00),
(1628,'U025',8,'Absent',FALSE,0.00),
(1629,'U025',9,'Present',FALSE,3.00),
(1630,'U025',10,'Present',FALSE,3.00),
(1631,'U025',11,'Present',FALSE,3.00),
(1632,'U025',12,'Present',FALSE,3.00),
(1633,'U025',13,'Present',FALSE,3.00),
(1634,'U025',14,'Present',FALSE,3.00),
(1635,'U025',15,'Present',FALSE,3.00),
(1636,'U025',16,'Present',FALSE,3.00),
(1637,'U025',17,'Present',FALSE,3.00),
(1638,'U025',18,'Absent',FALSE,0.00),
(1639,'U025',19,'Absent',FALSE,0.00),
(1640,'U025',20,'Present',FALSE,3.00),
(1641,'U025',21,'Present',FALSE,3.00),
(1642,'U025',22,'Present',FALSE,3.00),
(1643,'U025',23,'Present',FALSE,3.00),
(1644,'U025',24,'Present',FALSE,3.00),
(1645,'U025',25,'Present',FALSE,3.00),
(1646,'U025',26,'Present',FALSE,3.00),
(1647,'U025',27,'Present',FALSE,3.00),
(1648,'U025',28,'Present',FALSE,3.00),
(1649,'U025',29,'Present',FALSE,3.00),
(1650,'U025',30,'Present',FALSE,3.00),
(1651,'U025',31,'Present',FALSE,3.00),
(1652,'U025',32,'Present',FALSE,3.00),
(1653,'U025',33,'Present',FALSE,3.00),
(1654,'U025',34,'Present',FALSE,3.00),
(1655,'U025',35,'Absent',FALSE,0.00),
(1656,'U025',36,'Present',FALSE,3.00),
(1657,'U025',37,'Present',FALSE,3.00),
(1658,'U025',38,'Present',FALSE,3.00),
(1659,'U025',39,'Present',FALSE,3.00),
(1660,'U025',40,'Present',FALSE,3.00),
(1661,'U025',41,'Absent',FALSE,3.00),
(1662,'U025',42,'Present',FALSE,3.00),
(1663,'U025',43,'Present',FALSE,3.00),
(1664,'U025',44,'Present',FALSE,3.00),
(1665,'U025',45,'Present',FALSE,3.00),
(1666,'U025',46,'Present',FALSE,3.00),
(1667,'U025',47,'Present',FALSE,3.00),
(1668,'U025',48,'Present',FALSE,3.00),
(1669,'U025',49,'Absent',FALSE,0.00),
(1670,'U025',50,'Absent',FALSE,0.00),
(1671,'U025',51,'Present',FALSE,3.00),
(1672,'U025',52,'Present',FALSE,3.00),
(1673,'U025',53,'Absent',FALSE,0.00),
(1674,'U025',54,'Present',FALSE,3.00),
(1675,'U025',55,'Absent',FALSE,0.00),
(1676,'U025',56,'Present',FALSE,3.00),
(1677,'U025',57,'Present',FALSE,3.00),
(1678,'U025',58,'Present',FALSE,3.00),
(1679,'U025',59,'Absent',FALSE,0.00),
(1680,'U025',60,'Present',FALSE,3.00),
(1681,'U025',61,'Present',FALSE,3.00),
(1682,'U025',62,'Present',FALSE,3.00),
(1683,'U025',63,'Present',FALSE,3.00),
(1684,'U025',64,'Present',FALSE,3.00),
(1685,'U025',65,'Present',FALSE,3.00),
(1686,'U025',66,'Present',FALSE,3.00),
(1687,'U025',67,'Present',FALSE,3.00),
(1688,'U025',68,'Present',FALSE,3.00),
(1689,'U025',69,'Present',FALSE,3.00),
(1690,'U025',70,'Present',FALSE,3.00),
(1691,'U025',71,'Absent',FALSE,0.00),
(1692,'U025',72,'Absent',FALSE,0.00),
(1693,'U025',73,'Present',FALSE,3.00),
(1694,'U025',74,'Present',FALSE,3.00),
(1695,'U025',75,'Present',FALSE,3.00),
(1696,'U025',76,'Present',FALSE,3.00),
(1697,'U025',77,'Absent',FALSE,0.00),
(1698,'U025',78,'Present',FALSE,3.00),
(1699,'U025',79,'Present',FALSE,3.00),
(1700,'U025',80,'Present',FALSE,3.00),
(1701,'U025',81,'Present',FALSE,3.00),
(1702,'U025',82,'Present',FALSE,3.00),
(1703,'U025',83,'Absent',FALSE,0.00),
(1704,'U025',84,'Absent',FALSE,0.00),
(1705,'U025',85,'Present',FALSE,3.00),
(1706,'U025',86,'Absent',FALSE,0.00),
(1707,'U025',87,'Present',FALSE,3.00),
(1708,'U025',88,'Present',FALSE,3.00),
(1709,'U025',89,'Absent',FALSE,0.00),
(1710,'U025',90,'Present',FALSE,3.00),
(1711,'U025',91,'Present',FALSE,3.00),
(1712,'U025',92,'Present',FALSE,3.00),
(1713,'U025',93,'Present',FALSE,3.00),
(1714,'U025',94,'Present',FALSE,3.00),
(1715,'U025',95,'Present',FALSE,3.00),
(1716,'U025',96,'Present',FALSE,3.00),
(1717,'U025',97,'Present',FALSE,3.00),
(1718,'U025',98,'Absent',FALSE,0.00),
(1719,'U025',99,'Absent',FALSE,0.00),
(1720,'U025',100,'Absent',FALSE,0.00),
(1721,'U025',101,'Present',FALSE,3.00),
(1722,'U025',102,'Present',FALSE,3.00),
(1723,'U025',103,'Absent',FALSE,0.00),
(1724,'U025',104,'Present',FALSE,3.00),
(1725,'U025',105,'Present',FALSE,3.00),
(1726,'U025',106,'Absent',FALSE,0.00),
(1727,'U025',107,'Present',FALSE,2.00),
(1728,'U025',108,'Present',FALSE,2.00),
(1729,'U025',109,'Present',FALSE,2.00),
(1730,'U025',110,'Absent',FALSE,0.00),
(1731,'U025',111,'Absent',FALSE,0.00),
(1732,'U025',112,'Absent',FALSE,0.00),
(1733,'U025',113,'Absent',FALSE,0.00),
(1734,'U025',114,'Present',FALSE,2.00),
(1735,'U025',115,'Present',FALSE,2.00),
(1736,'U025',116,'Absent',FALSE,0.00),
(1737,'U025',117,'Present',FALSE,2.00),
(1738,'U025',118,'Present',FALSE,2.00),
(1739,'U025',119,'Absent',FALSE,0.00),
(1740,'U025',120,'Absent',FALSE,0.00),
(1741,'U025',121,'Absent',FALSE,0.00),
(1742,'U025',122,'Absent',FALSE,0.00),
(1743,'U025',123,'Absent',FALSE,0.00),
(1744,'U025',124,'Present',FALSE,3.00),
(1745,'U025',125,'Present',FALSE,3.00),
(1746,'U025',126,'Present',FALSE,3.00),
(1747,'U025',127,'Absent',FALSE,0.00),
(1748,'U025',128,'Absent',FALSE,0.00),
(1749,'U025',129,'Present',FALSE,3.00),
(1750,'U025',130,'Present',FALSE,3.00),
(1751,'U025',131,'Present',FALSE,3.00),
(1752,'U025',132,'Absent',FALSE,0.00),
(1753,'U025',133,'Present',FALSE,3.00),
(1754,'U025',134,'Present',FALSE,3.00),
(1755,'U025',135,'Absent',FALSE,0.00),
(1756,'U026',1,'Present',FALSE,3.00),
(1757,'U026',2,'Present',FALSE,3.00),
(1758,'U026',3,'Absent',FALSE,0.00),
(1759,'U026',4,'Present',FALSE,3.00),
(1760,'U026',5,'Present',FALSE,3.00),
(1761,'U026',6,'Present',FALSE,3.00),
(1762,'U026',7,'Present',FALSE,3.00),
(1763,'U026',8,'Present',FALSE,3.00),
(1764,'U026',9,'Present',FALSE,3.00),
(1765,'U026',10,'Absent',FALSE,0.00),
(1766,'U026',11,'Absent',FALSE,0.00),
(1767,'U026',12,'Present',FALSE,3.00),
(1768,'U026',13,'Present',FALSE,3.00),
(1769,'U026',14,'Present',FALSE,3.00),
(1770,'U026',15,'Present',FALSE,3.00),
(1771,'U026',16,'Present',FALSE,3.00),
(1772,'U026',17,'Present',FALSE,3.00),
(1773,'U026',18,'Present',FALSE,3.00),
(1774,'U026',19,'Present',FALSE,3.00),
(1775,'U026',20,'Present',FALSE,3.00),
(1776,'U026',21,'Absent',FALSE,0.00),
(1777,'U026',22,'Present',FALSE,3.00),
(1778,'U026',23,'Absent',FALSE,0.00),
(1779,'U026',24,'Present',FALSE,3.00),
(1780,'U026',25,'Present',FALSE,3.00),
(1781,'U026',26,'Absent',FALSE,0.00),
(1782,'U026',27,'Present',FALSE,3.00),
(1783,'U026',28,'Absent',FALSE,0.00),
(1784,'U026',29,'Absent',FALSE,0.00),
(1785,'U026',30,'Present',FALSE,3.00),
(1786,'U026',31,'Present',FALSE,3.00),
(1787,'U026',32,'Absent',FALSE,0.00),
(1788,'U026',33,'Present',FALSE,3.00),
(1789,'U026',34,'Present',FALSE,3.00),
(1790,'U026',35,'Absent',FALSE,0.00),
(1791,'U026',36,'Present',FALSE,3.00),
(1792,'U026',37,'Present',FALSE,3.00),
(1793,'U026',38,'Absent',FALSE,3.00),
(1794,'U026',39,'Absent',FALSE,0.00),
(1795,'U026',40,'Absent',FALSE,0.00),
(1796,'U026',41,'Absent',FALSE,0.00),
(1797,'U026',42,'Present',FALSE,3.00),
(1798,'U026',43,'Absent',FALSE,0.00),
(1799,'U026',44,'Present',FALSE,3.00),
(1800,'U026',45,'Absent',FALSE,0.00),
(1801,'U026',46,'Absent',FALSE,0.00),
(1802,'U026',47,'Present',FALSE,3.00),
(1803,'U026',48,'Present',FALSE,3.00),
(1804,'U026',49,'Absent',FALSE,0.00),
(1805,'U026',50,'Absent',FALSE,0.00),
(1806,'U026',51,'Absent',FALSE,0.00),
(1807,'U026',52,'Absent',FALSE,0.00),
(1808,'U026',53,'Present',FALSE,3.00),
(1809,'U026',54,'Present',FALSE,3.00),
(1810,'U026',55,'Present',FALSE,3.00),
(1811,'U026',56,'Absent',FALSE,0.00),
(1812,'U026',57,'Present',FALSE,3.00),
(1813,'U026',58,'Absent',FALSE,0.00),
(1814,'U026',59,'Present',FALSE,3.00),
(1815,'U026',60,'Present',FALSE,3.00),
(1816,'U026',61,'Absent',FALSE,0.00),
(1817,'U026',62,'Absent',FALSE,0.00),
(1818,'U026',63,'Present',FALSE,3.00),
(1819,'U026',64,'Present',FALSE,3.00),
(1820,'U026',65,'Present',FALSE,3.00),
(1821,'U026',66,'Present',FALSE,3.00),
(1822,'U026',67,'Present',FALSE,3.00),
(1823,'U026',68,'Present',FALSE,3.00),
(1824,'U026',69,'Present',FALSE,3.00),
(1825,'U026',70,'Absent',FALSE,0.00),
(1826,'U026',71,'Absent',FALSE,0.00),
(1827,'U026',72,'Present',FALSE,3.00),
(1828,'U026',73,'Absent',FALSE,0.00),
(1829,'U026',74,'Present',FALSE,3.00),
(1830,'U026',75,'Absent',FALSE,0.00),
(1831,'U026',76,'Absent',FALSE,0.00),
(1832,'U026',77,'Absent',FALSE,0.00),
(1833,'U026',78,'Present',FALSE,3.00),
(1834,'U026',79,'Present',FALSE,3.00),
(1835,'U026',80,'Present',FALSE,3.00),
(1836,'U026',81,'Present',FALSE,3.00),
(1837,'U026',82,'Present',FALSE,3.00),
(1838,'U026',83,'Present',FALSE,3.00),
(1839,'U026',84,'Present',FALSE,3.00),
(1840,'U026',85,'Present',FALSE,3.00),
(1841,'U026',86,'Present',FALSE,3.00),
(1842,'U026',87,'Absent',FALSE,0.00),
(1843,'U026',88,'Absent',FALSE,0.00),
(1844,'U026',89,'Present',FALSE,3.00),
(1845,'U026',90,'Absent',FALSE,0.00),
(1846,'U026',91,'Present',FALSE,3.00),
(1847,'U026',92,'Present',FALSE,3.00),
(1848,'U026',93,'Absent',FALSE,0.00),
(1849,'U026',94,'Present',FALSE,3.00),
(1850,'U026',95,'Present',FALSE,3.00),
(1851,'U026',96,'Present',FALSE,3.00),
(1852,'U026',97,'Present',FALSE,3.00),
(1853,'U026',98,'Present',FALSE,3.00),
(1854,'U026',99,'Absent',FALSE,0.00),
(1855,'U026',100,'Absent',FALSE,0.00),
(1856,'U026',101,'Present',FALSE,3.00),
(1857,'U026',102,'Present',FALSE,3.00),
(1858,'U026',103,'Absent',FALSE,0.00),
(1859,'U026',104,'Present',FALSE,3.00),
(1860,'U026',105,'Present',FALSE,3.00),
(1861,'U026',106,'Present',FALSE,2.00),
(1862,'U026',107,'Present',FALSE,2.00),
(1863,'U026',108,'Present',FALSE,2.00),
(1864,'U026',109,'Absent',FALSE,0.00),
(1865,'U026',110,'Present',FALSE,2.00),
(1866,'U026',111,'Present',FALSE,2.00),
(1867,'U026',112,'Present',FALSE,2.00),
(1868,'U026',113,'Present',FALSE,2.00),
(1869,'U026',114,'Present',FALSE,2.00),
(1870,'U026',115,'Present',FALSE,2.00),
(1871,'U026',116,'Present',FALSE,2.00),
(1872,'U026',117,'Present',FALSE,2.00),
(1873,'U026',118,'Absent',FALSE,0.00),
(1874,'U026',119,'Absent',FALSE,0.00),
(1875,'U026',120,'Present',FALSE,2.00),
(1876,'U026',121,'Present',FALSE,3.00),
(1877,'U026',122,'Absent',FALSE,0.00),
(1878,'U026',123,'Present',FALSE,3.00),
(1879,'U026',124,'Present',FALSE,3.00),
(1880,'U026',125,'Present',FALSE,3.00),
(1881,'U026',126,'Present',FALSE,3.00),
(1882,'U026',127,'Present',FALSE,3.00),
(1883,'U026',128,'Present',FALSE,3.00),
(1884,'U026',129,'Present',FALSE,3.00),
(1885,'U026',130,'Present',FALSE,3.00),
(1886,'U026',131,'Present',FALSE,3.00),
(1887,'U026',132,'Present',FALSE,3.00),
(1888,'U026',133,'Present',FALSE,3.00),
(1889,'U026',134,'Present',FALSE,3.00),
(1890,'U026',135,'Present',FALSE,3.00),
(1891,'U027',1,'Absent',FALSE,0.00),
(1892,'U027',2,'Absent',FALSE,0.00),
(1893,'U027',3,'Absent',FALSE,0.00),
(1894,'U027',4,'Absent',FALSE,0.00),
(1895,'U027',5,'Absent',FALSE,0.00),
(1896,'U027',6,'Present',FALSE,3.00),
(1897,'U027',7,'Absent',FALSE,0.00),
(1898,'U027',8,'Absent',FALSE,0.00),
(1899,'U027',9,'Absent',FALSE,0.00),
(1900,'U027',10,'Present',FALSE,3.00),
(1901,'U027',11,'Absent',FALSE,0.00),
(1902,'U027',12,'Absent',FALSE,0.00),
(1903,'U027',13,'Absent',FALSE,0.00),
(1904,'U027',14,'Present',FALSE,3.00),
(1905,'U027',15,'Present',FALSE,3.00),
(1906,'U027',16,'Present',FALSE,3.00),
(1907,'U027',17,'Absent',FALSE,0.00),
(1908,'U027',18,'Absent',FALSE,0.00),
(1909,'U027',19,'Present',FALSE,3.00),
(1910,'U027',20,'Absent',FALSE,0.00),
(1911,'U027',21,'Present',FALSE,3.00),
(1912,'U027',22,'Absent',FALSE,0.00),
(1913,'U027',23,'Absent',FALSE,0.00),
(1914,'U027',24,'Absent',FALSE,0.00),
(1915,'U027',25,'Absent',FALSE,0.00),
(1916,'U027',26,'Absent',FALSE,0.00),
(1917,'U027',27,'Absent',FALSE,0.00),
(1918,'U027',28,'Absent',FALSE,0.00),
(1919,'U027',29,'Present',FALSE,3.00),
(1920,'U027',30,'Absent',FALSE,0.00),
(1921,'U027',31,'Absent',FALSE,0.00),
(1922,'U027',32,'Present',FALSE,3.00),
(1923,'U027',33,'Absent',FALSE,0.00),
(1924,'U027',34,'Absent',FALSE,0.00),
(1925,'U027',35,'Absent',FALSE,0.00),
(1926,'U027',36,'Absent',FALSE,0.00),
(1927,'U027',37,'Present',FALSE,3.00),
(1928,'U027',38,'Present',FALSE,3.00),
(1929,'U027',39,'Absent',FALSE,0.00),
(1930,'U027',40,'Absent',FALSE,0.00),
(1931,'U027',41,'Absent',FALSE,0.00),
(1932,'U027',42,'Present',FALSE,3.00),
(1933,'U027',43,'Present',FALSE,3.00),
(1934,'U027',44,'Present',FALSE,3.00),
(1935,'U027',45,'Present',FALSE,3.00),
(1936,'U027',46,'Absent',FALSE,0.00),
(1937,'U027',47,'Absent',FALSE,0.00),
(1938,'U027',48,'Absent',FALSE,0.00),
(1939,'U027',49,'Absent',FALSE,0.00),
(1940,'U027',50,'Present',FALSE,3.00),
(1941,'U027',51,'Present',FALSE,3.00),
(1942,'U027',52,'Present',FALSE,3.00),
(1943,'U027',53,'Absent',FALSE,0.00),
(1944,'U027',54,'Absent',FALSE,0.00),
(1945,'U027',55,'Present',FALSE,3.00),
(1946,'U027',56,'Absent',FALSE,0.00),
(1947,'U027',57,'Absent',FALSE,0.00),
(1948,'U027',58,'Absent',FALSE,0.00),
(1949,'U027',59,'Absent',FALSE,0.00),
(1950,'U027',60,'Present',FALSE,3.00),
(1951,'U027',61,'Present',FALSE,3.00),
(1952,'U027',62,'Present',FALSE,3.00),
(1953,'U027',63,'Present',FALSE,3.00),
(1954,'U027',64,'Absent',FALSE,0.00),
(1955,'U027',65,'Absent',FALSE,0.00),
(1956,'U027',66,'Present',FALSE,3.00),
(1957,'U027',67,'Absent',FALSE,0.00),
(1958,'U027',68,'Absent',FALSE,0.00),
(1959,'U027',69,'Present',FALSE,3.00),
(1960,'U027',70,'Present',FALSE,3.00),
(1961,'U027',71,'Absent',FALSE,0.00),
(1962,'U027',72,'Present',FALSE,3.00),
(1963,'U027',73,'Absent',FALSE,0.00),
(1964,'U027',74,'Present',FALSE,3.00),
(1965,'U027',75,'Absent',FALSE,0.00),
(1966,'U027',76,'Absent',FALSE,0.00),
(1967,'U027',77,'Present',FALSE,3.00),
(1968,'U027',78,'Absent',FALSE,0.00),
(1969,'U027',79,'Absent',FALSE,0.00),
(1970,'U027',80,'Present',FALSE,3.00),
(1971,'U027',81,'Present',FALSE,3.00),
(1972,'U027',82,'Present',FALSE,3.00),
(1973,'U027',83,'Absent',FALSE,0.00),
(1974,'U027',84,'Present',FALSE,3.00),
(1975,'U027',85,'Present',FALSE,3.00),
(1976,'U027',86,'Present',FALSE,3.00),
(1977,'U027',87,'Absent',FALSE,0.00),
(1978,'U027',88,'Absent',FALSE,0.00),
(1979,'U027',89,'Absent',FALSE,0.00),
(1980,'U027',90,'Absent',FALSE,0.00),
(1981,'U027',91,'Absent',FALSE,0.00),
(1982,'U027',92,'Absent',FALSE,0.00),
(1983,'U027',93,'Absent',FALSE,0.00),
(1984,'U027',94,'Absent',FALSE,0.00),
(1985,'U027',95,'Absent',FALSE,0.00),
(1986,'U027',96,'Absent',FALSE,0.00),
(1987,'U027',97,'Present',FALSE,3.00),
(1988,'U027',98,'Absent',FALSE,0.00),
(1989,'U027',99,'Present',FALSE,3.00),
(1990,'U027',100,'Present',FALSE,3.00),
(1991,'U027',101,'Absent',FALSE,0.00),
(1992,'U027',102,'Absent',FALSE,0.00),
(1993,'U027',103,'Absent',FALSE,0.00),
(1994,'U027',104,'Present',FALSE,3.00),
(1995,'U027',105,'Absent',FALSE,0.00),
(1996,'U027',106,'Absent',FALSE,0.00),
(1997,'U027',107,'Absent',FALSE,0.00),
(1998,'U027',108,'Absent',FALSE,0.00),
(1999,'U027',109,'Absent',FALSE,0.00),
(2000,'U027',110,'Absent',FALSE,0.00),
(2001,'U027',111,'Present',FALSE,2.00),
(2002,'U027',112,'Present',FALSE,2.00),
(2003,'U027',113,'Present',FALSE,2.00),
(2004,'U027',114,'Absent',FALSE,0.00),
(2005,'U027',115,'Absent',FALSE,0.00),
(2006,'U027',116,'Absent',FALSE,0.00),
(2007,'U027',117,'Present',FALSE,2.00),
(2008,'U027',118,'Absent',FALSE,0.00),
(2009,'U027',119,'Present',FALSE,2.00),
(2010,'U027',120,'Present',FALSE,2.00),
(2011,'U027',121,'Absent',FALSE,0.00),
(2012,'U027',122,'Absent',FALSE,0.00),
(2013,'U027',123,'Absent',FALSE,0.00),
(2014,'U027',124,'Present',FALSE,3.00),
(2015,'U027',125,'Absent',FALSE,0.00),
(2016,'U027',126,'Absent',FALSE,0.00),
(2017,'U027',127,'Absent',FALSE,0.00),
(2018,'U027',128,'Absent',FALSE,0.00),
(2019,'U027',129,'Absent',FALSE,0.00),
(2020,'U027',130,'Present',FALSE,3.00),
(2021,'U027',131,'Absent',FALSE,0.00),
(2022,'U027',132,'Present',FALSE,3.00),
(2023,'U027',133,'Absent',FALSE,0.00),
(2024,'U027',134,'Absent',FALSE,0.00),
(2025,'U027',135,'Present',FALSE,3.00);


-- ==========================
-- Views  Attendance Related
-- ==========================
-- Detailed Attendance per Student per Course (Theory / Practical)

CREATE OR REPLACE VIEW attendance_detailed AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    se.type AS session_type,
    GROUP_CONCAT(DISTINCT se.session_date ORDER BY se.session_date) AS session_dates,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,
   
    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours) * 100,
        100), 2
    ) AS attendance_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours)
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id, se.type;



-- Combined Attendance per Student per Course

CREATE OR REPLACE VIEW attendance_combined AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,

    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / c.total_hours * 100,
        100), 2
    ) AS attendance_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / c.total_hours
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility

FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id;



-- Individual Student Attendance Summary

CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours) * 100,
        100), 2
    ) AS attendance_percentage,

    ROUND(
        (SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END)
        / SUM(se.session_hours) * 100), 2
    ) AS medical_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours)
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id;



-- Individual Session Attendance Details

CREATE OR REPLACE VIEW student_attendance_details AS
SELECT
    s.reg_no,
    a.student_id,
    se.course_id,
    c.name AS course_name,
    se.session_date,
    se.type AS session_type,
    CASE
        WHEN a.status = 'Present' THEN 'Present'
        WHEN a.status = 'Absent' THEN 'Absent'
        ELSE 'N/R'
    END AS attendance_status
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
ORDER BY s.reg_no, se.course_id, se.session_date;



-- ==============================================
-- Marks Data Insertions
-- ==============================================

INSERT INTO marks (marks_id, student_id, course_id, quiz1_marks, quiz2_marks, quiz3_marks, assessment_marks, mid_marks, final_theory, final_practical, ca_marks, final_marks, ca_eligible, final_eligible, grade)
VALUES
(1,'U013','ICT1222',52,46,49,46,41,37,26,NULL,NULL,'Eligible','Eligible',NULL),
(2,'U013','ICT1233',60,59,73,59,65,26,33,NULL,NULL,'Eligible','Eligible',NULL),
(3,'U013','ICT1242',69,85,79,62,56,62,0,NULL,NULL,'Eligible','Eligible',NULL),
(4,'U013','ICT1253',50,60,55,82,76,28,39,NULL,NULL,'Eligible','Eligible',NULL),
(5,'U013','TCS1212',64,81,53,83,46,76,0,NULL,NULL,'Eligible','Eligible',NULL),
(6,'U013','TMS1233',62,56,60,71,66,93,0,NULL,NULL,'Eligible','Eligible',NULL),
(7,'U014','ICT1222',57,46,53,48,61,27,44,NULL,NULL,'Eligible','Eligible',NULL),
(8,'U014','ICT1233',76,55,54,46,57,33,48,NULL,NULL,'Eligible','Eligible',NULL),
(9,'U014','ICT1242',79,82,46,59,61,67,0,NULL,NULL,'Eligible','Eligible',NULL),
(10,'U014','ICT1253',45,48,60,47,74,38,41,NULL,NULL,'Eligible','Eligible',NULL),
(11,'U014','TCS1212',47,74,65,48,64,95,0,NULL,NULL,'Eligible','Eligible',NULL),
(12,'U014','TMS1233',83,63,71,74,78,70,0,NULL,NULL,'Eligible','Eligible',NULL),
(13,'U015','ICT1222',69,69,49,82,72,50,44,NULL,NULL,'Eligible','Eligible',NULL),
(14,'U015','ICT1233',80,80,70,56,71,43,35,NULL,NULL,'Eligible','Eligible',NULL),
(15,'U015','ICT1242',71,84,53,59,51,75,0,NULL,NULL,'Eligible','Eligible',NULL),
(16,'U015','ICT1253',54,45,57,60,40,30,41,NULL,NULL,'Eligible','Eligible',NULL),
(17,'U015','TCS1212',80,83,44,45,75,99,0,NULL,NULL,'Eligible','Eligible',NULL),
(18,'U015','TMS1233',63,58,46,49,68,100,0,NULL,NULL,'Eligible','Eligible',NULL),
(19,'U016','ICT1222',51,49,65,69,67,31,34,NULL,NULL,'Eligible','Eligible',NULL),
(20,'U016','ICT1233',79,52,74,66,63,44,29,NULL,NULL,'Eligible','Eligible',NULL),
(21,'U016','ICT1242',49,81,51,61,58,81,0,NULL,NULL,'Eligible','Eligible',NULL),
(22,'U016','ICT1253',59,50,40,70,59,27,26,NULL,NULL,'Eligible','Eligible',NULL),
(23,'U016','TCS1212',76,54,46,82,44,61,0,NULL,NULL,'Eligible','Eligible',NULL),
(24,'U016','TMS1233',64,83,70,63,71,86,0,NULL,NULL,'Eligible','Eligible',NULL),
(25,'U017','ICT1222',57,72,64,72,52,35,38,NULL,NULL,'Eligible','Eligible',NULL),
(26,'U017','ICT1233',83,60,80,70,68,47,42,NULL,NULL,'Eligible','Eligible',NULL),
(27,'U017','ICT1242',80,84,47,53,46,77,0,NULL,NULL,'Eligible','Eligible',NULL),
(28,'U017','ICT1253',72,49,48,52,77,27,39,NULL,NULL,'Eligible','Eligible',NULL),
(29,'U017','TCS1212',59,48,65,71,56,90,0,NULL,NULL,'Eligible','Eligible',NULL),
(30,'U017','TMS1233',61,63,85,58,45,78,0,NULL,NULL,'Eligible','Eligible',NULL),
(31,'U018','ICT1222',63,67,75,69,46,45,40,NULL,NULL,'Eligible','Eligible',NULL),
(32,'U018','ICT1233',51,70,74,72,45,40,33,NULL,NULL,'Eligible','Eligible',NULL),
(33,'U018','ICT1242',65,61,85,45,75,63,0,NULL,NULL,'Eligible','Eligible',NULL),
(34,'U018','ICT1253',58,84,41,78,46,43,48,NULL,NULL,'Eligible','Eligible',NULL),
(35,'U018','TCS1212',83,61,47,69,40,77,0,NULL,NULL,'Eligible','Eligible',NULL),
(36,'U018','TMS1233',65,66,63,80,67,79,0,NULL,NULL,'Eligible','Eligible',NULL),
(37,'U019','ICT1222',48,83,77,73,68,49,43,NULL,NULL,'Eligible','Eligible',NULL),
(38,'U019','ICT1233',62,53,63,52,43,32,46,NULL,NULL,'Eligible','Eligible',NULL),
(39,'U019','ICT1242',74,77,53,77,45,71,0,NULL,NULL,'Eligible','Eligible',NULL),
(40,'U019','ICT1253',69,49,80,76,67,32,38,NULL,NULL,'Eligible','Eligible',NULL),
(41,'U019','TCS1212',80,69,80,48,41,79,0,NULL,NULL,'Eligible','Eligible',NULL),
(42,'U019','TMS1233',53,83,46,66,48,93,0,NULL,NULL,'Eligible','Eligible',NULL),
(43,'U020','ICT1222',84,48,75,66,41,32,32,NULL,NULL,'Eligible','Eligible',NULL),
(44,'U020','ICT1233',70,78,41,52,60,26,37,NULL,NULL,'Eligible','Eligible',NULL),
(45,'U020','ICT1242',76,49,79,62,80,72,0,NULL,NULL,'Eligible','Eligible',NULL),
(46,'U020','ICT1253',85,73,73,70,80,47,35,NULL,NULL,'Eligible','Eligible',NULL),
(47,'U020','TCS1212',82,72,77,66,40,78,0,NULL,NULL,'Eligible','Eligible',NULL),
(48,'U020','TMS1233',51,85,55,75,46,64,0,NULL,NULL,'Eligible','Eligible',NULL),
(49,'U021','ICT1222',51,62,53,50,41,38,38,NULL,NULL,'Eligible','Eligible',NULL),
(50,'U021','ICT1233',68,73,75,48,73,40,25,NULL,NULL,'Eligible','Eligible',NULL),
(51,'U021','ICT1242',61,46,76,82,64,82,0,NULL,NULL,'Eligible','Eligible',NULL),
(52,'U021','ICT1253',59,68,80,85,41,31,27,NULL,NULL,'Eligible','Eligible',NULL),
(53,'U021','TCS1212',47,48,64,58,44,70,0,NULL,NULL,'Eligible','Eligible',NULL),
(54,'U021','TMS1233',61,61,80,67,49,74,0,NULL,NULL,'Eligible','Eligible',NULL),
(55,'U022','ICT1222',77,56,79,81,61,35,43,NULL,NULL,'Eligible','Eligible',NULL),
(56,'U022','ICT1233',84,51,64,50,58,34,40,NULL,NULL,'Eligible','Eligible',NULL),
(57,'U022','ICT1242',56,57,82,69,61,76,0,NULL,NULL,'Eligible','Eligible',NULL),
(58,'U022','ICT1253',56,53,66,50,67,30,29,NULL,NULL,'Eligible','Eligible',NULL),
(59,'U022','TCS1212',47,53,69,51,54,76,0,NULL,NULL,'Eligible','Eligible',NULL),
(60,'U022','TMS1233',45,72,51,75,70,91,0,NULL,NULL,'Eligible','Eligible',NULL),
(61,'U023','ICT1222',85,73,62,50,50,44,44,NULL,NULL,'Eligible','Eligible',NULL),
(62,'U023','ICT1233',80,81,85,75,63,46,30,NULL,NULL,'Eligible','Eligible',NULL),
(63,'U023','ICT1242',52,48,54,78,65,72,0,NULL,NULL,'Eligible','Eligible',NULL),
(64,'U023','ICT1253',69,61,43,57,77,32,46,NULL,NULL,'Eligible','Eligible',NULL),
(65,'U023','TCS1212',79,76,85,80,62,69,0,NULL,NULL,'Eligible','Eligible',NULL),
(66,'U023','TMS1233',69,81,63,63,80,77,0,NULL,NULL,'Eligible','Eligible',NULL),
(67,'U024','ICT1222',63,51,82,59,78,38,50,NULL,NULL,'Eligible','Eligible',NULL),
(68,'U024','ICT1233',59,68,82,64,73,38,31,NULL,NULL,'Eligible','Eligible',NULL),
(69,'U024','ICT1242',64,51,66,81,78,70,0,NULL,NULL,'Eligible','Eligible',NULL),
(70,'U024','ICT1253',49,68,45,76,51,43,25,NULL,NULL,'Eligible','Eligible',NULL),
(71,'U024','TCS1212',65,76,64,63,58,99,0,NULL,NULL,'Eligible','Eligible',NULL),
(72,'U024','TMS1233',61,49,41,47,65,84,0,NULL,NULL,'Eligible','Eligible',NULL),
(73,'U025','ICT1222',84,71,53,71,54,41,40,NULL,NULL,'Eligible','Eligible',NULL),
(74,'U025','ICT1233',49,55,82,72,70,27,44,NULL,NULL,'Eligible','Eligible',NULL),
(75,'U025','ICT1242',82,67,78,49,42,84,0,NULL,NULL,'Eligible','Eligible',NULL),
(76,'U025','ICT1253',76,66,55,70,54,48,35,NULL,NULL,'Eligible','Eligible',NULL),
(77,'U025','TCS1212',68,62,48,73,76,74,0,NULL,NULL,'Eligible','Eligible',NULL),
(78,'U025','TMS1233',63,73,47,56,50,71,0,NULL,NULL,'Eligible','Eligible',NULL),
(79,'U026','ICT1222',55,52,80,67,63,38,43,NULL,NULL,'Eligible','Eligible',NULL),
(80,'U026','ICT1233',69,81,77,46,79,25,47,NULL,NULL,'Eligible','Eligible',NULL),
(81,'U026','ICT1242',54,58,62,61,56,72,0,NULL,NULL,'Eligible','Eligible',NULL),
(82,'U026','ICT1253',52,77,66,72,73,48,44,NULL,NULL,'Eligible','Eligible',NULL),
(83,'U026','TCS1212',79,79,74,55,78,85,0,NULL,NULL,'Eligible','Eligible',NULL),
(84,'U026','TMS1233',74,45,54,61,78,74,0,NULL,NULL,'Eligible','Eligible',NULL),
(85,'U027','ICT1222',58,67,49,51,40,38,50,NULL,NULL,'Eligible','Eligible',NULL),
(86,'U027','ICT1233',63,65,49,46,77,32,41,NULL,NULL,'Eligible','Eligible',NULL),
(87,'U027','ICT1242',45,79,66,57,40,81,0,NULL,NULL,'Eligible','Eligible',NULL),
(88,'U027','ICT1253',66,68,73,80,68,45,46,NULL,NULL,'Eligible','Eligible',NULL),
(89,'U027','TCS1212',71,53,85,50,58,98,0,NULL,NULL,'Eligible','Eligible',NULL),
(90,'U027','TMS1233',65,81,58,70,67,86,0,NULL,NULL,'Eligible','Eligible',NULL);



--- =============================================
-- Procedure 1: Update marks with grades
-- =============================================
DELIMITER $$

DROP PROCEDURE IF EXISTS update_marks_grades$$

CREATE PROCEDURE update_marks_grades()
BEGIN
    DECLARE done_student INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(50);

    DECLARE student_cursor CURSOR FOR SELECT DISTINCT student_id FROM marks;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_student = TRUE;

    OPEN student_cursor;

    student_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done_student THEN LEAVE student_loop; END IF;

        -- Update grades based on rules
        UPDATE marks m
        JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
        LEFT JOIN student_attendance_summary sas ON sas.student_id = m.student_id AND sas.course_id = m.course_id
        SET m.grade = CASE
            WHEN sc.status = 'Suspended' THEN 'WH'
            WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'MC'
            WHEN sc.status='Proper' AND IFNULL(sas.attendance_percentage,100) < 80 THEN 'E*'
            WHEN m.ca_eligible = 'Not Eligible' AND ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ECA & ESA'
            WHEN m.ca_eligible = 'Not Eligible' THEN 'ECA'
            WHEN ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ESA'
            WHEN m.final_marks >= 85 THEN 'A+'
            WHEN m.final_marks >= 75 THEN 'A'
            WHEN m.final_marks >= 70 THEN 'A-'
            WHEN m.final_marks >= 65 THEN 'B+'
            WHEN m.final_marks >= 60 THEN 'B'
            WHEN m.final_marks >= 55 THEN 'B-'
            WHEN m.final_marks >= 50 THEN 'C+'
            WHEN m.final_marks >= 45 THEN 'C'
            WHEN m.final_marks >= 40 THEN 'C-'
            WHEN m.final_marks >= 35 THEN 'D'
            ELSE 'E'
        END
        WHERE m.student_id = s_id;

        -- Cap repeat grades to 'C'
        UPDATE marks m
        JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
        SET m.grade = CASE
            WHEN sc.status = 'Repeat' AND m.grade IN ('A+','A','A-','B+','B','B-','C+') THEN 'C'
            ELSE m.grade
        END
        WHERE m.student_id = s_id;

    END LOOP;

    CLOSE student_cursor;
END$$

DELIMITER ;

CALL update_marks_grades();


-- =============================================
-- Procedure 2: Calculate SGPA and CGPA
-- =============================================
DELIMITER $$

DROP PROCEDURE IF EXISTS calculate_final_result$$

CREATE PROCEDURE calculate_final_result()
BEGIN
    -- Clear previous results
    TRUNCATE TABLE result;

    -- Insert results per student
    INSERT INTO result(student_id, academic_year, sgpa, cgpa, total_credits)
    SELECT 
        s.user_id AS student_id,
        MAX(c.academic_year) AS academic_year,

        -- SGPA (latest academic year)
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM marks m2
                JOIN student_course sc2 
                    ON sc2.student_id = m2.student_id 
                   AND sc2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id
                  AND (m2.grade = 'MC' OR sc2.status = 'Suspended')
            ) THEN 'WH'
            ELSE ROUND(
                SUM(
                    c.credit * CASE m.grade
                        WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                        WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                        WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                        WHEN 'D' THEN 1.3 ELSE 0
                    END
                ) / NULLIF(SUM(c.credit), 0),
            2)
        END AS sgpa,

        -- CGPA (all completed courses)
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM marks m2
                JOIN student_course sc2 
                    ON sc2.student_id = m2.student_id 
                   AND sc2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id
                  AND (m2.grade = 'MC' OR sc2.status = 'Suspended')
            ) THEN 'WH'
            ELSE ROUND(
                SUM(
                    c.credit * CASE m.grade
                        WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                        WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                        WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                        WHEN 'D' THEN 1.3 ELSE 0
                    END
                ) / NULLIF(SUM(c.credit), 0),
            2)
        END AS cgpa,

        SUM(c.credit) AS total_credits
    FROM student s
    LEFT JOIN marks m ON m.student_id = s.user_id
    LEFT JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id;

END$$

DELIMITER ;


CALL calculate_final_result();




-- ========================================
-- Marks views(Resukts ,SGPA, CGPA)
-- ========================================

CREATE OR REPLACE VIEW student_results AS
SELECT
    t.user_id,
    t.reg_no,
    t.academic_year,
    t.semester,
    t.total_credits,

    -- SGPA
    CASE
        WHEN t.is_suspended = 1 THEN 'WH'        -- Suspended student
        WHEN t.has_mc = 1 THEN 'WH'             -- Any MC grade in semester
        ELSE CAST(t.sgpa AS CHAR)
    END AS sgpa,

    -- CGPA
    CASE
        WHEN t.is_suspended = 1 THEN 'WH'       -- Suspended semester shows WH
        WHEN t.has_mc = 1 THEN NULL             -- MC semester ignored
        ELSE CAST(
            ROUND(
                SUM(CASE WHEN t.is_suspended = 0 AND t.has_mc = 0 THEN t.sgpa * t.total_credits ELSE 0 END)
                OVER (
                    PARTITION BY t.user_id
                    ORDER BY t.academic_year, t.semester
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
                /
                NULLIF(
                    SUM(CASE WHEN t.is_suspended = 0 AND t.has_mc = 0 THEN t.total_credits ELSE 0 END)
                    OVER (
                        PARTITION BY t.user_id
                        ORDER BY t.academic_year, t.semester
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ), 0
                ),
            2
            ) AS CHAR
        )
    END AS cgpa

FROM (
    SELECT
        s.user_id,
        s.reg_no,
        c.academic_year,
        c.semester,
        SUM(c.credit) AS total_credits,

        -- Numeric SGPA calculation for non-suspended/non-MC
        ROUND(
            SUM(
                CASE
                    WHEN m.grade = 'A+' THEN 4.0
                    WHEN m.grade = 'A'  THEN 4.0
                    WHEN m.grade = 'A-' THEN 3.7
                    WHEN m.grade = 'B+' THEN 3.3
                    WHEN m.grade = 'B'  THEN 3.0
                    WHEN m.grade = 'B-' THEN 2.7
                    WHEN m.grade = 'C+' THEN 2.3
                    WHEN m.grade = 'C'  THEN 2.0
                    WHEN m.grade = 'C-' THEN 1.7
                    WHEN m.grade = 'D'  THEN 1.3
                    ELSE 0
                END * c.credit
            ) / SUM(c.credit),
            2
        ) AS sgpa,

        -- Suspended semester flag
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM student_course sc
                WHERE sc.student_id = s.user_id
                  AND sc.status = 'Suspended'
                  AND sc.course_id IN (
                      SELECT course_id FROM course
                      WHERE academic_year = c.academic_year AND semester = c.semester
                  )
            ) THEN 1
            ELSE 0
        END AS is_suspended,

        -- MC flag
        CASE
            WHEN SUM(CASE WHEN m.grade = 'MC' THEN 1 ELSE 0 END) > 0 THEN 1
            ELSE 0
        END AS has_mc

    FROM marks m
    JOIN student s ON s.user_id = m.student_id
    JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id, s.reg_no, c.academic_year, c.semester
) AS t

ORDER BY t.user_id, t.academic_year, t.semester;



-- Sem Pass or fail check
CREATE OR REPLACE VIEW semester_pass_fail AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    r.sgpa,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade IN ('MC','WH')
        ) THEN 'WH'
        WHEN r.sgpa >= 2 THEN 'Pass'
        ELSE 'Fail'
    END AS semester_result
FROM result r
JOIN student s ON s.user_id = r.student_id;


-- Class Check according to the current sem
CREATE OR REPLACE VIEW student_class AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade IN ('MC','WH')
        ) THEN 'WH'
        ELSE CAST(r.cgpa AS CHAR)
    END AS cgpa,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade IN ('MC','WH')
        ) THEN 'WH'
        WHEN r.cgpa >= 3.7 THEN 'First Class'
        WHEN r.cgpa >= 3.3 THEN 'Second Class (Upper)'
        WHEN r.cgpa >= 3.0 THEN 'Second Class (Lower)'
        WHEN r.cgpa >= 2.0 THEN 'Pass'
        ELSE 'Fail'
    END AS class_status
FROM result r
JOIN student s ON s.user_id = r.student_id
WHERE (r.academic_year, r.semester) = (
    SELECT r2.academic_year, r2.semester
    FROM result r2
    WHERE r2.student_id = r.student_id
    ORDER BY r2.academic_year DESC, r2.semester DESC
    LIMIT 1
);

-- Cgpa Check every sem
CREATE OR REPLACE VIEW v_progressive_cgpa AS
SELECT
    r.student_id,
    s.reg_no,
    r.academic_year,
    r.semester,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade IN ('MC','WH')
        ) THEN 'WH'
        ELSE CAST(r.sgpa AS CHAR)
    END AS sgpa,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade IN ('MC','WH')
        ) THEN 'WH'
        ELSE CAST(
            ROUND((
                SELECT SUM(r2.sgpa) / COUNT(r2.sgpa)
                FROM result r2
                WHERE r2.student_id = r.student_id
                  AND (
                        r2.academic_year < r.academic_year
                        OR (r2.academic_year = r.academic_year AND r2.semester <= r.semester)
                      )
            ), 2) AS CHAR)
    END AS cgpa
FROM result r
JOIN student s ON s.user_id = r.student_id
ORDER BY r.student_id, r.academic_year, r.semester;


-- ==============================================================
-- batch_department_marks
-- ==============================================================

CREATE OR REPLACE VIEW batch_department_marks AS
SELECT 
    s.user_id,
    s.reg_no,
    s.batch,
    d.name AS department_name,
    m.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    m.ca_marks,
    m.final_marks,
    m.ca_eligible,
    m.final_eligible,
    m.grade,
    CASE 
        WHEN m.grade IN ('MC','WH') THEN 'WH'         -- Withheld due to Medical
        WHEN m.grade IN ('E', 'ECA & ESA','ECA','ESA','E*') THEN 'Fail'
        ELSE 'Pass'
    END AS status
FROM marks m
JOIN student s 
    ON s.user_id = m.student_id
JOIN course c 
    ON c.course_id = m.course_id
LEFT JOIN department d 
    ON s.department_id = d.department_id
ORDER BY s.batch, d.name, s.reg_no, c.academic_year, c.semester;


CREATE OR REPLACE VIEW batch_marks_summary AS
SELECT 
    m.course_id,
    c.name AS course_name,
    COUNT(*) AS total_students,
    SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END) AS ca_eligible_students,
    SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END) AS final_eligible_students,
    ROUND(AVG(m.ca_marks),2) AS avg_ca_marks,
    ROUND(AVG(m.final_marks),2) AS avg_final_marks,
    ROUND((SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS ca_eligible_percentage,
    ROUND((SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS final_eligible_percentage
FROM marks m
JOIN course c ON c.course_id = m.course_id
GROUP BY m.course_id;


CREATE OR REPLACE VIEW student_marks_summary AS
SELECT 
    m.student_id,
    s.reg_no,
    m.course_id,
    c.name AS course_name,
    m.ca_marks,
    m.final_marks,
    m.ca_eligible,
    m.final_eligible,
    m.grade
FROM marks m
JOIN student s ON s.user_id = m.student_id
JOIN course c ON c.course_id = m.course_id;

-- ==============================================
--   Student Overall Eligibility Views With Attendance and CA
-- ==============================================


-- 1) Student-level overall eligibility (reg_no comes from student)
CREATE OR REPLACE VIEW student_overall_eligibility AS
SELECT 
    m.student_id,
    s.reg_no,
    m.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    -- From attendance summary (may be NULL if no summary)
    COALESCE(sas.attendance_percentage, 0)AS attendance_percentage,
    COALESCE(sas.eligibility, 'Unknown')AS attendance_eligibility,

    -- From marks table
    m.ca_marks,
    m.ca_eligible,
    m.final_eligible,

    -- Overall Eligibility Logic (handles NULLs conservatively)
    CASE
        WHEN COALESCE(sas.eligibility, 'Unknown') = 'Not Eligible' THEN 'Not Eligible (Attendance < 80%)'
        WHEN COALESCE(m.ca_eligible, 'Not Eligible') = 'Not Eligible' THEN 'Not Eligible (CA Failed)'
        WHEN COALESCE(m.final_eligible, 'Not Eligible') = 'Not Eligible' THEN 'Not Eligible (Final Failed)'
        WHEN COALESCE(m.ca_eligible, '') = 'WH' OR COALESCE(m.final_eligible, '') = 'WH' THEN 'Withheld'
        WHEN COALESCE(m.ca_eligible, '') = 'MC' OR COALESCE(m.final_eligible, '') = 'MC' THEN 'Eligible with Medical'
        ELSE 'Fully Eligible'
    END AS overall_eligibility
FROM marks m
-- attendance summary may be missing for some students -> LEFT JOIN
LEFT JOIN student_attendance_summary sas
    ON sas.student_id = m.student_id
    AND sas.course_id = m.course_id
-- course info
JOIN course c
    ON c.course_id = m.course_id
-- student_course is useful if you want course-specific student status; keep if needed
LEFT JOIN student_course sc
    ON sc.student_id = m.student_id
    AND sc.course_id = m.course_id
-- reg_no is in student table
JOIN student s
    ON s.user_id = m.student_id
;

-- 2) Batch-level (aggregates student_overall_eligibility)
CREATE OR REPLACE VIEW batch_overall_eligibility AS
SELECT 
    soe.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    COUNT(*) AS total_students,
    SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) AS fully_eligible,
    SUM(CASE WHEN overall_eligibility LIKE 'Not Eligible%' THEN 1 ELSE 0 END) AS not_eligible,
    SUM(CASE WHEN overall_eligibility = 'Eligible with Medical' THEN 1 ELSE 0 END) AS medical_cases,
    SUM(CASE WHEN overall_eligibility = 'Withheld' THEN 1 ELSE 0 END) AS withheld_cases,

    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 0
           ELSE SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) / COUNT(*) * 100
      END
    , 2) AS eligible_percentage

FROM student_overall_eligibility soe
JOIN course c ON c.course_id = soe.course_id
GROUP BY soe.course_id, c.name, c.academic_year, c.semester;




--  Procedure: generate_student_academic_report

DELIMITER $$

CREATE PROCEDURE generate_student_academic_report(IN p_reg_no VARCHAR(15))
BEGIN
    DECLARE v_student_id VARCHAR(10);

    
    SELECT user_id INTO v_student_id
    FROM student
    WHERE reg_no = p_reg_no;

    
    IF v_student_id IS NULL THEN
        SELECT CONCAT('No student found with reg_no: ', p_reg_no) AS message;
    ELSE
        
        SELECT 
            s.reg_no,
            s.batch,
            s.department_id
        FROM student s
        WHERE s.user_id = v_student_id;

        
        SELECT 
            course_id,
            course_name,
            ca_marks,
            final_marks,
            ca_eligible,
            final_eligible,
            grade
        FROM student_marks_summary
        WHERE student_id = v_student_id;

        
        SELECT 
            academic_year,
            semester,
            semester_result
        FROM semester_pass_fail
        WHERE reg_no = p_reg_no;

        
        SELECT 
            academic_year,
            semester,
            cgpa,
            class_status
        FROM student_class
        WHERE reg_no = p_reg_no;
    END IF;

END$$

DELIMITER ;




CALL generate_student_academic_report('TG/2023/1704');
--give one student marks  CALL get_student_course_marks('U013', 'ICT1222');



DELIMITER $$

CREATE PROCEDURE get_student_course_marks (
    IN p_reg_no VARCHAR(20),
    IN p_course_id VARCHAR(20)
)
BEGIN
    SELECT 
        quiz1_marks + quiz2_marks + quiz3_marks AS `TOTAL QUIZ MARKS`,
        assessment_marks AS `ASSESSMENT_MARKS`,
        mid_marks,
        final_theory + final_practical AS `FINAL EXAM MARKS`
    FROM marks
    WHERE student_id = p_reg_no
      AND course_id = p_course_id;
END $$

DELIMITER ;
CALL get_student_course_marks('U013', 'ICT1222');




--  check one student eligibility CALL get_student_eligibility('U013', 'ICT1222');
DELIMITER $$

DROP PROCEDURE IF EXISTS get_student_eligibility$$


CREATE PROCEDURE get_student_eligibility(
    IN p_user_id VARCHAR(20),
    IN p_course_id VARCHAR(20)
)
BEGIN
    SELECT a_d.session_type AS `PRACTICAL/THEORY`,a_d.eligibility AS `ELIGIBILITY FOR THE EXAM`
    FROM attendance_detailed AS a_d
    WHERE a_d.student_id = p_user_id
      AND a_d.course_id = p_course_id;
END $$


DELIMITER ;
CALL get_student_eligibility('U013', 'ICT1222');

----  one course check final marks and eligibility  CALL get_batch_marks_summary_by_course(''Database Management Systems'');
DELIMITER $$

CREATE PROCEDURE  get_batch_marks_summary_by_course (
    IN p_course_name VARCHAR(100)
)
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.semester,

        COUNT(*) AS total_students,
        SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) AS fully_eligible,
        SUM(CASE WHEN overall_eligibility LIKE 'Not Eligible%' THEN 1 ELSE 0 END) AS not_eligible,
        SUM(CASE WHEN overall_eligibility = 'Eligible with Medical' THEN 1 ELSE 0 END) AS medical_cases,
        SUM(CASE WHEN overall_eligibility = 'Withheld' THEN 1 ELSE 0 END) AS withheld_cases,

        ROUND(SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS eligible_percentage

    FROM student_overall_eligibility soe
    JOIN course c ON c.course_id = soe.course_id
    WHERE c.name = p_course_name
    GROUP BY c.course_id, c.academic_year, c.semester;
END $$
DELIMITER ;
CALL get_batch_marks_summary_by_course('Database Management Systems');




-- Cgpa Check every sem
DELIMITER $$

DROP PROCEDURE IF EXISTS get_progressive_cgpa$$

CREATE PROCEDURE get_progressive_cgpa(IN p_student_id VARCHAR(10))
BEGIN
    SELECT
        r.student_id,
        s.reg_no,
        r.academic_year,
        r.semester,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = r.student_id
                  AND c.academic_year = r.academic_year
                  AND c.semester = r.semester
                  AND m.grade IN ('MC','WH')
            ) THEN 'WH'
            ELSE CAST(r.sgpa AS CHAR)
        END AS sgpa,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = r.student_id
                  AND c.academic_year = r.academic_year
                  AND c.semester = r.semester
                  AND m.grade IN ('MC','WH')
            ) THEN 'WH'
            ELSE CAST(
                ROUND((
                    SELECT SUM(r2.sgpa) / COUNT(r2.sgpa)
                    FROM result r2
                    WHERE r2.student_id = r.student_id
                      AND (
                            r2.academic_year < r.academic_year
                            OR (r2.academic_year = r.academic_year AND r2.semester <= r.semester)
                          )
                ), 2) AS CHAR)
        END AS cgpa
    FROM result r
    JOIN student s ON s.user_id = r.student_id
    WHERE (p_student_id IS NULL OR r.student_id = p_student_id)
    ORDER BY r.student_id, r.academic_year, r.semester;
END$$

DELIMITER ;


CALL get_progressive_cgpa('U013');



-- batch_department_marks

DELIMITER $$

DROP PROCEDURE IF EXISTS get_batch_department_marks$$

CREATE PROCEDURE get_batch_department_marks(IN p_batch VARCHAR(10))
BEGIN
    SELECT 
        s.user_id,
        s.reg_no,
        s.batch,
        d.name AS department_name,
        m.course_id,
        c.name AS course_name,
        c.academic_year,
        c.semester,
        m.ca_marks,
        m.final_marks,
        m.ca_eligible,
        m.final_eligible,
        m.grade,
        CASE 
            WHEN m.grade = 'MC' THEN 'WH'
            WHEN m.grade IN ('E', 'ECA & ESA','ECA','ESA','E*') THEN 'Fail'
            ELSE 'Pass'
        END AS status
    FROM marks m
    JOIN student s 
        ON s.user_id = m.student_id
    JOIN course c 
        ON c.course_id = m.course_id
    LEFT JOIN department d 
        ON s.department_id = d.department_id
    WHERE (p_batch IS NULL OR s.batch = p_batch)
    ORDER BY s.batch, d.name, s.reg_no, c.academic_year, c.semester;
END$$

DELIMITER ;

CALL get_batch_department_marks('2023');






-- Drop procedure if it exists
DROP PROCEDURE IF EXISTS get_student_overall_eligibility;

DELIMITER $$

CREATE PROCEDURE get_student_overall_eligibility()
BEGIN
    SELECT 
        m.student_id,
        s.reg_no,
        m.course_id,
        c.name AS course_name,
        c.academic_year,
        c.semester,

        -- From attendance summary (may be NULL if no summary)
        COALESCE(sas.attendance_percentage, 0) AS attendance_percentage,
        COALESCE(sas.eligibility, 'Unknown') AS attendance_eligibility,

        -- From marks table
        m.ca_marks,
        m.ca_eligible,
        m.final_eligible,

        -- Overall Eligibility Logic
        CASE
            WHEN COALESCE(sas.eligibility, 'Unknown') = 'Not Eligible' 
                THEN 'Not Eligible (Attendance < 80%)'
            WHEN COALESCE(m.ca_eligible, 'Not Eligible') = 'Not Eligible' 
                THEN 'Not Eligible (CA Failed)'
            WHEN COALESCE(m.final_eligible, 'Not Eligible') = 'Not Eligible' 
                THEN 'Not Eligible (Final Failed)'
            WHEN COALESCE(m.ca_eligible, '') = 'WH' OR COALESCE(m.final_eligible, '') = 'WH' 
                THEN 'Withheld'
            WHEN COALESCE(m.ca_eligible, '') = 'MC' OR COALESCE(m.final_eligible, '') = 'MC' 
                THEN 'Eligible with Medical'
            ELSE 'Fully Eligible'
        END AS overall_eligibility
    FROM marks m
    LEFT JOIN student_attendance_summary sas
        ON sas.student_id = m.student_id
        AND sas.course_id = m.course_id
    JOIN course c
        ON c.course_id = m.course_id
    LEFT JOIN student_course sc
        ON sc.student_id = m.student_id
        AND sc.course_id = m.course_id
    JOIN student s
        ON s.user_id = m.student_id;
END$$

DELIMITER ;


CALL get_student_overall_eligibility();




-- Procedure to create final_student_report view
DELIMITER $$

DROP PROCEDURE IF EXISTS create_final_student_report_view$$

CREATE PROCEDURE create_final_student_report_view()
BEGIN
    DECLARE sql_query TEXT;
    DECLARE course_list TEXT;

    -- Generate dynamic MAX(CASE ...) for each course
    SELECT GROUP_CONCAT(
        CONCAT(
            'MAX(CASE WHEN course_id = ''', course_id, ''' THEN grade END) AS `', course_id, '`'
        )
        ORDER BY course_id
        SEPARATOR ', '
    ) INTO course_list
    FROM (SELECT DISTINCT course_id FROM student_marks_summary) AS courses;

    -- Build the full dynamic CREATE VIEW query
    SET @sql_query = CONCAT(
        'CREATE OR REPLACE VIEW final_student_report AS ',
        'SELECT s.reg_no AS Index_no, u.name AS Student_name, ',
        course_list, ', ',
        'MAX(r.sgpa) AS sgpa, MAX(r.cgpa) AS cgpa ',
        'FROM student_marks_summary m ',
        'JOIN student s ON s.user_id = m.student_id ',
        'JOIN `users` u ON u.user_id = s.user_id ',
        'LEFT JOIN result r ON r.student_id = s.user_id ',
        'GROUP BY s.reg_no, u.name ',
        'ORDER BY s.reg_no'
    );

    -- Prepare and execute the dynamic CREATE VIEW
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END$$

DELIMITER ;

-- Call the procedure to create the view
CALL create_final_student_report_view();

-- After calling, you can just do:
 -- SELECT * FROM final_student_report;




























