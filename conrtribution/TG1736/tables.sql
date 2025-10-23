TG/2023/1736

//Attendence Table

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






//Marks Table

CREATE TABLE marks (
    marks_id INT AUTO_INCREMENT PRIMARY KEY,
    quiz1_marks DECIMAL(5,2),
    quiz2_marks DECIMAL(5,2),
    quiz3_marks DECIMAL(5,2),
    final_theory DECIMAL(5,2),
    final_practical DECIMAL(5,2),
    final_marks DECIMAL(5,2),
    
);



//Result Table

CREATE TABLE result (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    gpa DECIMAL(3,2),
    sgpa DECIMAL(3,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id), 
);




