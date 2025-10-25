-- ==============================================================
-- View Name   : batch_department_marks
-- Description  : Displays each student's marks with batch,
--                department, course details, and pass/fail/withheld status.
-- ==============================================================

CREATE OR REPLACE VIEW batch_department_marks AS
SELECT 
    s.user_id,
    s.reg_no,
    s.batch,
    d.name AS department_name,
    m.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    m.ca_marks,
    m.final_marks,
    m.ca_eligible,
    m.final_eligible,
    m.grade,
    CASE 
        WHEN m.grade = 'MC' THEN 'WH'         -- Withheld due to Medical
        WHEN m.grade IN ('E', 'ECA & ESA','ECA','ESA') THEN 'Fail'
        ELSE 'Pass'
    END AS status
FROM marks m
JOIN student s 
    ON s.user_id = m.student_id
JOIN course c 
    ON c.course_id = m.course_id
LEFT JOIN department d 
    ON s.department_id = d.department_id
ORDER BY s.batch, d.name, s.reg_no, c.academic_year, c.semester;
