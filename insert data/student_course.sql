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
-- U023 repeats ICT1222 & ICT1242
('U023','ICT1222','Repeat'),('U023','ICT1233','Proper'),('U023','ICT1242','Repeat'),('U023','ICT1253','Proper'),('U023','TCS1212','Proper'),('U023','TMS1233','Proper'),
-- U024 repeats ICT1233 & TCS1212
('U024','ICT1222','Proper'),('U024','ICT1233','Repeat'),('U024','ICT1242','Proper'),('U024','ICT1253','Proper'),('U024','TCS1212','Repeat'),('U024','TMS1233','Proper'),
-- U025 repeats ICT1222 & ICT1253
('U025','ICT1222','Repeat'),('U025','ICT1233','Proper'),('U025','ICT1242','Proper'),('U025','ICT1253','Repeat'),('U025','TCS1212','Proper'),('U025','TMS1233','Proper'),
-- U026 repeats ICT1233 & ICT1253
('U026','ICT1222','Proper'),('U026','ICT1233','Repeat'),('U026','ICT1242','Proper'),('U026','ICT1253','Repeat'),('U026','TCS1212','Proper'),('U026','TMS1233','Proper');