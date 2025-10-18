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
