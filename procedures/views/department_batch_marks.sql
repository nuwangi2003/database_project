CREATE OR REPLACE VIEW batch_department_marks AS
SELECT 
    s.user_id,
    s.reg_no,
    s.batch,
    d.name AS department_name,
    m.course_id,
    c.name AS course_name,
    m.ca_marks,
    m.final_marks,
    m.ca_eligible,
    m.final_eligible,
    m.grade
FROM marks m
JOIN student s ON s.user_id = m.student_id
JOIN course c ON c.course_id = m.course_id
JOIN department d ON s.department_id = d.department_id;
