				--tech_officer

CREATE TABLE tech_officer(
	user_id INT PRIMARY KEY,
	bod DATE ,
	FOREIGN KEY(lec_id) REFERENCES user(user_id)
	
);

				--dean
CREATE TABLE dean(
	lecture_id INT PRIMARY KEY,
	term_start DATE,
	term_end DATE,
	FOREIGN KEY(Lecture_id) REFERENCES lecture(user_id)
	
);

				--cource
CREATE TABLE cource(
	course_id INT PRIMARY KEY,
	name VARCHAR(25),
	cradit CHAR(5),

);
