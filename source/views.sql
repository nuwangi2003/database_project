
-- ================================
 --   Attendance Views
-- ================================
-- Detailed Attendance per Student per Course (Theory / Practical)

CREATE OR REPLACE VIEW attendance_detailed AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    se.type AS session_type,
    GROUP_CONCAT(DISTINCT se.session_date ORDER BY se.session_date) AS session_dates,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,
   
    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours) * 100,
        100), 2
    ) AS attendance_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours)
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id, se.type;



-- Combined Attendance per Student per Course

CREATE OR REPLACE VIEW attendance_combined AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,

    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / c.total_hours * 100,
        100), 2
    ) AS attendance_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / c.total_hours
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility

FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id;



-- Individual Student Attendance Summary

CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT
    sc.student_id,
    s.reg_no,
    sc.status AS student_status,
    se.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) AS attended_hours,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END) AS medical_hours,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN 1 ELSE 0 END) AS sessions_medical,

    ROUND(
        LEAST(
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours) * 100,
        100), 2
    ) AS attendance_percentage,

    ROUND(
        (SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END)
        / SUM(se.session_hours) * 100), 2
    ) AS medical_percentage,

    CASE
        WHEN sc.status = 'Suspended' THEN 'Not Eligible'
        WHEN (
            (SUM(CASE WHEN a.status = 'Present' THEN se.session_hours ELSE 0 END) +
             SUM(CASE WHEN a.status = 'Absent' AND a.medical = 1 THEN se.session_hours ELSE 0 END))
            / SUM(se.session_hours)
        ) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
GROUP BY sc.student_id, se.course_id;



-- Individual Session Attendance Details

CREATE OR REPLACE VIEW student_attendance_details AS
SELECT
    s.reg_no,
    a.student_id,
    se.course_id,
    c.name AS course_name,
    se.session_date,
    se.type AS session_type,
    CASE
        WHEN m.exam_type = 'Attendance'
             AND m.status = 'Approved'
             AND m.course_id = se.course_id
             AND m.date_submitted = se.session_date THEN 'MC'
        WHEN a.status = 'Present' THEN 'Present'
        WHEN a.status = 'Absent' THEN 'Absent'
        ELSE 'Not Recorded'
    END AS attendance_status
FROM attendance a
JOIN session se ON se.session_id = a.session_id
JOIN student_course sc ON sc.student_id = a.student_id AND sc.course_id = se.course_id
JOIN student s ON s.user_id = sc.student_id
JOIN course c ON c.course_id = se.course_id
LEFT JOIN medical m
    ON m.student_id = a.student_id
   AND m.exam_type = 'Attendance'
   AND m.status = 'Approved'
   AND m.course_id = se.course_id            
   AND m.date_submitted = se.session_date    
ORDER BY s.reg_no, se.course_id, se.session_date;



-- ========================================
-- Marks views(Resukts ,SGPA, CGPA)
-- ========================================

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



-- Sem Pass or fail check
CREATE OR REPLACE VIEW semester_pass_fail AS
SELECT
    s.reg_no,
    r.academic_year,
    r.semester,
    r.sgpa
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

-- ==============================================
--   Student Overall Eligibility Views With Attendance and CA
-- ==============================================


-- 1) Student-level overall eligibility (reg_no comes from student)
CREATE OR REPLACE VIEW student_overall_eligibility AS
SELECT 
    m.student_id,
    s.reg_no,
    m.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    -- From attendance summary (may be NULL if no summary)
    COALESCE(sas.attendance_percentage, 0)AS attendance_percentage,
    COALESCE(sas.eligibility, 'Unknown')AS attendance_eligibility,

    -- From marks table
    m.ca_marks,
    m.ca_eligible,
    m.final_eligible,

    -- Overall Eligibility Logic (handles NULLs conservatively)
    CASE
        WHEN COALESCE(sas.eligibility, 'Unknown') = 'Not Eligible' THEN 'Not Eligible (Attendance < 80%)'
        WHEN COALESCE(m.ca_eligible, 'Not Eligible') = 'Not Eligible' THEN 'Not Eligible (CA Failed)'
        WHEN COALESCE(m.final_eligible, 'Not Eligible') = 'Not Eligible' THEN 'Not Eligible (Final Failed)'
        WHEN COALESCE(m.ca_eligible, '') = 'WH' OR COALESCE(m.final_eligible, '') = 'WH' THEN 'Withheld'
        WHEN COALESCE(m.ca_eligible, '') = 'MC' OR COALESCE(m.final_eligible, '') = 'MC' THEN 'Eligible with Medical'
        ELSE 'Fully Eligible'
    END AS overall_eligibility
FROM marks m
-- attendance summary may be missing for some students -> LEFT JOIN
LEFT JOIN student_attendance_summary sas
    ON sas.student_id = m.student_id
    AND sas.course_id = m.course_id
-- course info
JOIN course c
    ON c.course_id = m.course_id
-- student_course is useful if you want course-specific student status; keep if needed
LEFT JOIN student_course sc
    ON sc.student_id = m.student_id
    AND sc.course_id = m.course_id
-- reg_no is in student table
JOIN student s
    ON s.user_id = m.student_id
;

-- 2) Batch-level (aggregates student_overall_eligibility)
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
GROUP BY soe.course_id, c.name, c.academic_year, c.semester;










