
-- Batch Attendance Summary (All Students in a Course)

CREATE OR REPLACE VIEW batch_attendance_summary AS
SELECT
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    ROUND(AVG(ac.attendance_percentage), 2) AS avg_attendance_percentage,
    SUM(CASE WHEN ac.attendance_percentage >= 80 AND ac.student_status <> 'Suspended' THEN 1 ELSE 0 END) AS eligible_students,
    COUNT(*) AS total_students,
    CONCAT(
        ROUND(
            (SUM(CASE WHEN ac.attendance_percentage >= 80 AND ac.student_status <> 'Suspended' THEN 1 ELSE 0 END)/COUNT(*))*100, 2
        ), '%'
    ) AS eligible_percentage,
    SUM(CASE WHEN ac.medical_hours > 0 THEN 1 ELSE 0 END) AS students_with_medical
FROM attendance_combined ac
JOIN course c ON c.course_id = ac.course_id
GROUP BY c.course_id, c.academic_year, c.semester;
 

 
--  Batch-level (aggregates student_overall_eligibility) CA+ ATTENCE
CREATE OR REPLACE VIEW batch_overall_eligibility AS
SELECT 
    soe.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    COUNT(*) AS total_students,
    SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) AS fully_eligible,
    SUM(CASE WHEN overall_eligibility LIKE 'Not Eligible%' THEN 1 ELSE 0 END) AS not_eligible,
    SUM(CASE WHEN overall_eligibility = 'Eligible with Medical' THEN 1 ELSE 0 END) AS medical_cases,
    SUM(CASE WHEN overall_eligibility = 'Withheld' THEN 1 ELSE 0 END) AS withheld_cases,

    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 0
           ELSE SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) / COUNT(*) * 100
      END
    , 2) AS eligible_percentage

FROM student_overall_eligibility soe
JOIN course c ON c.course_id = soe.course_id
GROUP BY soe.course_id, c.name, c.academic_year, c.semester
;
-----student_results

CREATE OR REPLACE VIEW student_results AS
SELECT
    t.user_id,
    t.reg_no,
    t.academic_year,
    t.semester,
    t.total_credits,

    -- SGPA
    CASE
        WHEN t.is_suspended = 1 THEN 'WH'        -- Suspended student
        WHEN t.has_mc = 1 THEN 'WH'             -- Any MC grade in semester
        ELSE CAST(t.sgpa AS CHAR)
    END AS sgpa,

    -- CGPA
    CASE
        WHEN t.is_suspended = 1 THEN 'WH'       -- Suspended semester shows WH
        WHEN t.has_mc = 1 THEN NULL             -- MC semester ignored
        ELSE CAST(
            ROUND(
                SUM(CASE WHEN t.is_suspended = 0 AND t.has_mc = 0 THEN t.sgpa * t.total_credits ELSE 0 END)
                OVER (
                    PARTITION BY t.user_id
                    ORDER BY t.academic_year, t.semester
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
                /
                NULLIF(
                    SUM(CASE WHEN t.is_suspended = 0 AND t.has_mc = 0 THEN t.total_credits ELSE 0 END)
                    OVER (
                        PARTITION BY t.user_id
                        ORDER BY t.academic_year, t.semester
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ), 0
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

        -- Numeric SGPA calculation for non-suspended/non-MC
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
                    ELSE 0
                END * c.credit
            ) / SUM(c.credit),
            2
        ) AS sgpa,

        -- Suspended semester flag
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM student_course sc
                WHERE sc.student_id = s.user_id
                  AND sc.status = 'Suspended'
                  AND sc.course_id IN (
                      SELECT course_id FROM course
                      WHERE academic_year = c.academic_year AND semester = c.semester
                  )
            ) THEN 1
            ELSE 0
        END AS is_suspended,

        -- MC flag
        CASE
            WHEN SUM(CASE WHEN m.grade = 'MC' THEN 1 ELSE 0 END) > 0 THEN 1
            ELSE 0
        END AS has_mc

    FROM marks m
    JOIN student s ON s.user_id = m.student_id
    JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id, s.reg_no, c.academic_year, c.semester
) AS t

ORDER BY t.user_id, t.academic_year, t.semester;



CREATE OR REPLACE VIEW batch_marks_summary AS
SELECT 
    m.course_id,
    c.name AS course_name,
    COUNT(*) AS total_students,
    SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END) AS ca_eligible_students,
    SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END) AS final_eligible_students,
    ROUND(AVG(m.ca_marks),2) AS avg_ca_marks,
    ROUND(AVG(m.final_marks),2) AS avg_final_marks,
    ROUND((SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS ca_eligible_percentage,
    ROUND((SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS final_eligible_percentage
FROM marks m
JOIN course c ON c.course_id = m.course_id
GROUP BY m.course_id;


