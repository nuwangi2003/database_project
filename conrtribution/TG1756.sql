1) Create Database -> 
	CREATE DATABASE db_project
	
2) Create User Table ->
	1.CREATE TABLE user(
	  	user_id VARCHAR(10) PRIMARY KEY,
	  	email VARCHAR(50) NOT NULL,
 	  	password VARCHAR(10) NOT NULL,
	  	department VARCHAR(15) NOT NULL);
	  
	 2.CREATE TABLE tech_office_phone_no(
    		user_id CHAR(3),
    		phone_number VARCHAR(10),
   		PRIMARY KEY (user_id, phone_number),         
    		FOREIGN KEY (user_id) REFERENCES users(user_id));
    		
    		
	3) CREATE TABLE course_marks(
		course_id VARCHAR(10),
		marks_id INT,
		PRIMARY KEY(course_id,marks_id),
		FOREIGN KEY (course_id) REFERENCES course(course_id),
		FOREIGN KEY (marks_id) REFERENCES marks(marks_id));
	
	4) CREATE TABLE student_marks(
		user_id VARCHAR(10),
		marks_id INT,
		grade CHAR(1),
		PRIMARY KEY (user_id,marks_id)
		FOREIGN KEY (user_id) REFERENCES student(user_id),
		FOREIGN KEY (marks_id) REFERENCES marks(marks_id));
		

