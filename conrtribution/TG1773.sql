1. CREATE table for student

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

