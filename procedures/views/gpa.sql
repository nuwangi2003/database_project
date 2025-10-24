
CREATE OR REPLACE VIEW student_results AS
SELECT 
    t.user_id,
    t.reg_no,
    t.academic_year,
    t.semester,
    t.total_credits,
    
    -- Check if the student has an 'MC' grade in this semester
    CASE 
        WHEN t.has_medical = 1 THEN 'WH'
        ELSE CAST(t.sgpa AS CHAR)
    END AS sgpa,

    CASE 
        WHEN t.has_medical = 1 THEN 'WH'
        ELSE CAST(
            ROUND(
                SUM(t.sgpa * t.total_credits) OVER (
                    PARTITION BY t.user_id 
                    ORDER BY t.academic_year, t.semester
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) / 
                SUM(t.total_credits) OVER (
                    PARTITION BY t.user_id 
                    ORDER BY t.academic_year, t.semester
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ), 
                2
            ) AS CHAR
        )
    END AS cgpa

FROM (
    SELECT 
        s.user_id,
        s.reg_no,
        c.academic_year,
        c.semester,
        SUM(c.credit) AS total_credits,

        -- Calculate numeric SGPA
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
                    WHEN m.grade = 'D'  THEN 1.3
                    WHEN m.grade IN ('E','ECA & ESA') THEN 0
                    WHEN m.grade = 'MC' THEN 0
                    ELSE 0
                END * c.credit
            ) / SUM(c.credit), 
            2
        ) AS sgpa,

        -- Flag to indicate if student has any 'MC' grade in this semester
        CASE 
            WHEN SUM(CASE WHEN m.grade = 'MC' THEN 1 ELSE 0 END) > 0 THEN 1
            ELSE 0
        END AS has_medical

    FROM marks m
    JOIN student s ON s.user_id = m.student_id
    JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id, s.reg_no, c.academic_year, c.semester
) AS t

ORDER BY t.user_id, t.academic_year, t.semester;



-- Sem Pass or fail check
CREATE OR REPLACE VIEW semester_pass_fail AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade = 'MC'
        ) THEN 'WH'
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
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade = 'MC'
        ) THEN 'WH'
        ELSE CAST(r.cgpa AS CHAR)
    END AS cgpa,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade = 'MC'
        ) THEN 'WH'
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
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade = 'MC'
        ) THEN 'WH'
        ELSE CAST(r.sgpa AS CHAR)
    END AS sgpa,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM marks m
            JOIN course c ON c.course_id = m.course_id
            WHERE m.student_id = r.student_id
              AND c.academic_year = r.academic_year
              AND c.semester = r.semester
              AND m.grade = 'MC'
        ) THEN 'WH'
        ELSE CAST(
            ROUND((
                SELECT SUM(r2.sgpa) / COUNT(r2.sgpa)
                FROM result r2
                WHERE r2.student_id = r.student_id
                  AND (
                        r2.academic_year < r.academic_year 
                        OR (r2.academic_year = r.academic_year AND r2.semester <= r.semester)
                      )
            ), 2) AS CHAR)
    END AS cgpa
FROM result r
JOIN student s ON s.user_id = r.student_id
ORDER BY r.student_id, r.academic_year, r.semester;




