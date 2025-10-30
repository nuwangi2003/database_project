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

