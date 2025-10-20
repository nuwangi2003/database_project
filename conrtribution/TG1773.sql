/*1. CREATE table for student

CREATE TABLE student(
    user_id CHAR(3) PRIMARY KEY,
    reg_no char(15) NOT NULL,
    satus VARCHAR(15)
);



2. CREATE table for lecture

CREATE TABLE lecture(
    lecture_id VARCHAR(10) NOT NULL,
    specilization VARCHAR(20),
    PRIMARY KEY(lecture_id),
    FORIEGN KEY (lecture_id) REFERENCES user(user_id)
);

3. CREATE table for student course

    CREATE TABLE student_course(
        course_id VARCHAR(10) NOT NULL,
        user_id CHAR() NOT NULL
    );
*/


-- 1. Student Table

CREATE TABLE student (
    user_id VARCHAR(10) PRIMARY KEY,
    reg_no VARCHAR(15) UNIQUE NOT NULL,
    batch VARCHAR(10),
    status ENUM('Proper', 'Repeat', 'Suspended') DEFAULT 'Proper',
    department_id VARCHAR(10),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


-- 2. Lecturer Table
CREATE TABLE lecture (
    user_id VARCHAR(10) PRIMARY KEY,
    specialization VARCHAR(50),
    designation VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--3.Student_course
CREATE TABLE student_course (
    student_id VARCHAR(10),
    course_id VARCHAR(10),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES student(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
