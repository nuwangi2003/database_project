CREATE OR REPLACE VIEW student_overall_marks AS
SELECT 
    s.user_id,
    s.reg_no,
    SUM(c.credit) AS total_credits,
    ROUND(
        SUM(
            CASE 
                WHEN m.grade = 'A+' THEN 4
                WHEN m.grade = 'A'  THEN 4
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2
                ELSE 0
            END * c.credit
        ) / SUM(c.credit), 2
    ) AS sgpa,
    ROUND(
        SUM(
            CASE 
                WHEN m.grade = 'A+' THEN 4
                WHEN m.grade = 'A'  THEN 4
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2
                ELSE 0
            END * c.credit
        ) / SUM(c.credit), 2
    ) AS cgpa
FROM marks m
JOIN student s ON s.user_id = m.student_id
JOIN course c ON c.course_id = m.course_id
GROUP BY s.user_id;

