CREATE OR REPLACE VIEW student_results AS
SELECT 
    s.user_id,
    s.reg_no,
    m.academic_year,
    m.semester,
    SUM(c.credit) AS total_credits,
    ROUND(
        SUM(
            CASE 
                WHEN m.grade IN ('A+','A') THEN 4
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2
                WHEN m.grade = 'C-' THEN 1.7
                ELSE 0   -- Fails: 'E', 'ECA & ESA'
            END * c.credit
        ) / SUM(c.credit), 2
    ) AS sgpa,
    ROUND(
        SUM(
            CASE 
                WHEN m.grade IN ('A+','A') THEN 4
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2
                WHEN m.grade = 'C-' THEN 1.7
                ELSE 0
            END * c.credit
        ) / SUM(c.credit) OVER (PARTITION BY s.user_id), 2
    ) AS cgpa
FROM marks m
JOIN student s ON s.user_id = m.student_id
JOIN course c ON c.course_id = m.course_id
GROUP BY s.user_id, m.academic_year, m.semester;
