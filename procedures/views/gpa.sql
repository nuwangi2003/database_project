CREATE OR REPLACE VIEW student_results AS
SELECT 
    s.user_id,
    s.reg_no,
    c.academic_year,
    c.semester,
    SUM(c.credit) AS total_credits,
    ROUND(
        SUM(
            CASE 
                -- A+ to C- normal grades
                WHEN m.grade = 'A+' THEN 4.0
                WHEN m.grade = 'A'  THEN 4.0
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3.0
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2.0
                WHEN m.grade = 'C-' THEN 1.7
                WHEN m.grade= 'D' THEN 1.3
                -- Failing courses (E, ECA & ESA)
                WHEN m.grade = 'E' OR m.grade = 'ECA & ESA' THEN 0
                ELSE 0
            END * c.credit
        ) / SUM(c.credit), 2
    ) AS sgpa,
    ROUND(
        SUM(
            CASE 
                WHEN m.grade = 'A+' THEN 4.0
                WHEN m.grade = 'A'  THEN 4.0
                WHEN m.grade = 'A-' THEN 3.7
                WHEN m.grade = 'B+' THEN 3.3
                WHEN m.grade = 'B'  THEN 3.0
                WHEN m.grade = 'B-' THEN 2.7
                WHEN m.grade = 'C+' THEN 2.3
                WHEN m.grade = 'C'  THEN 2.0
                WHEN m.grade = 'C-' THEN 1.7
                WHEN m.grade = 'D' THEN 1.3
                WHEN m.grade = 'E' OR m.grade = 'ECA & ESA' THEN 0
                ELSE 0
            END * c.credit
        ) OVER (PARTITION BY s.user_id) / 
        SUM(c.credit) OVER (PARTITION BY s.user_id), 2
    ) AS cgpa
FROM marks m
JOIN student s ON s.user_id = m.student_id
JOIN course c ON c.course_id = m.course_id
GROUP BY s.user_id, c.academic_year, c.semester;




-- Sem Pass or fail check
CREATE OR REPLACE VIEW semester_pass_fail AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    r.sgpa,
    CASE
        WHEN r.sgpa >= 2 THEN 'Pass'
        ELSE 'Fail'
    END AS semester_result
FROM result r
JOIN student s ON s.user_id = r.student_id;

-- Class Check according to the current sem
CREATE OR REPLACE VIEW student_class AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    r.cgpa,
    CASE
        WHEN r.cgpa >= 3.7 THEN 'First Class'
        WHEN r.cgpa >= 3.3 THEN 'Second Class (Upper)'
        WHEN r.cgpa >= 3.0 THEN 'Second Class (Lower)'
        WHEN r.cgpa >= 2.0 THEN 'Pass'
        ELSE 'Fail'
    END AS class_status
FROM result r
JOIN student s ON s.user_id = r.student_id
WHERE (r.academic_year, r.semester) = (
    SELECT r2.academic_year, r2.semester
    FROM result r2
    WHERE r2.student_id = r.student_id
    ORDER BY r2.academic_year DESC, r2.semester DESC
    LIMIT 1
);

-- Cgpa Check every sem
CREATE OR REPLACE VIEW v_progressive_cgpa AS
SELECT 
    r.student_id,
    s.reg_no,
    r.academic_year,
    r.semester,
    r.sgpa,
    ROUND((
        SELECT SUM(r2.sgpa) / COUNT(r2.sgpa)
        FROM result r2
        WHERE r2.student_id = r.student_id
          AND (
                r2.academic_year < r.academic_year 
                OR (r2.academic_year = r.academic_year AND r2.semester <= r.semester)
              )
    ), 2) AS cgpa
FROM result r
JOIN student s ON s.user_id = r.student_id
ORDER BY r.student_id, r.academic_year, r.semester;



