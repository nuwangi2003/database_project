
-- 1. Combine Both at the Student Level
CREATE OR REPLACE VIEW v_student_overall_eligibility AS
SELECT 
    st.user_id,
    st.reg_no,
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    -- From attendance summary
    sas.attendance_percentage,
    sas.eligibility AS attendance_eligibility,

    -- From marks table
    m.ca_marks,
    m.ca_eligible,
    m.final_eligible,

    -- Overall Eligibility Logic
    CASE
        WHEN sas.eligibility = 'Not Eligible' THEN 'Not Eligible (Attendance < 80%)'
        WHEN m.ca_eligible = 'Not Eligible' THEN 'Not Eligible (CA Failed)'
        WHEN m.final_eligible = 'Not Eligible' THEN 'Not Eligible (Final Failed)'
        WHEN m.ca_eligible = 'WH' OR m.final_eligible = 'WH' THEN 'Withheld'
        WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'Eligible with Medical'
        ELSE 'Fully Eligible'
    END AS overall_eligibility

FROM student_attendance_summary sas
JOIN marks m ON sas.user_id = m.student_id AND sas.course_id = m.course_id
JOIN course c ON c.course_id = m.course_id
JOIN student st ON st.user_id = m.student_id;



-- 2. Batch-Level Eligibility (for Whole Course)
CREATE OR REPLACE VIEW v_batch_overall_eligibility AS
SELECT 
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,

    COUNT(*) AS total_students,
    SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) AS fully_eligible,
    SUM(CASE WHEN overall_eligibility LIKE 'Not Eligible%' THEN 1 ELSE 0 END) AS not_eligible,
    SUM(CASE WHEN overall_eligibility = 'Eligible with Medical' THEN 1 ELSE 0 END) AS medical_cases,
    SUM(CASE WHEN overall_eligibility = 'Withheld' THEN 1 ELSE 0 END) AS withheld_cases,

    ROUND(SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS eligible_percentage

FROM v_student_overall_eligibility soe
JOIN course c ON c.course_id = soe.course_id
GROUP BY c.course_id, c.academic_year, c.semester;


