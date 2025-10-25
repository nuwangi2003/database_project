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
    COALESCE(sas.attendance_percentage, 0)        AS attendance_percentage,
    COALESCE(sas.eligibility, 'Unknown')         AS attendance_eligibility,

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
GROUP BY soe.course_id, c.name, c.academic_year, c.semester
;
