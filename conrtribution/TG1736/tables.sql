TG/2023/1736

/*
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY,
    user_id VARCHAR(10),
    course_id VARCHAR(10),
    date DATE,
    status ENUM('Present', 'Absent'),
    medical BOOLEAN,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES course(course_id)
);


CREATE TABLE marks (
    marks_id INT AUTO_INCREMENT PRIMARY KEY,
    quiz1_marks DECIMAL(5,2),
    quiz2_marks DECIMAL(5,2),
    quiz3_marks DECIMAL(5,2),
    final_theory DECIMAL(5,2),
    final_practical DECIMAL(5,2),
    final_marks DECIMAL(5,2),
    
);


CREATE TABLE result (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    gpa DECIMAL(3,2),
    sgpa DECIMAL(3,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id), 
);

*/


-- Attendance Table (Updated for medical handling)

CREATE TABLE attendance (
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


-- Marks Table (Updated for eligibility and grades)

CREATE TABLE marks (
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
    ca_marks DECIMAL(5,2),                                                       -- new: calculated from best 2 quizzes + assessment + mid
    final_marks DECIMAL(5,2),                                                     -- total marks including CA + final exams
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


--  Result Table (SGPA & CGPA)

CREATE TABLE result (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL,
    academic_year INT CHECK (academic_year BETWEEN 1 AND 4),
    semester ENUM('1','2') NOT NULL,
    sgpa DECIMAL(3,2) ,
    cgpa DECIMAL(3,2) ,
    total_credits INT DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



