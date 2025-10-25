
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




 --Batch-Level Eligibility (for Whole Course)
CREATE OR REPLACE VIEW batch_overall_eligibility AS
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

FROM student_overall_eligibility soe
JOIN course c ON c.course_id = soe.course_id
GROUP BY c.course_id, c.academic_year, c.semester;

-----student_results

CREATE OR REPLACE VIEW student_results AS
SELECT 
    t.user_id,
    t.reg_no,
    t.academic_year,
    t.semester,
    t.total_credits,
    t.sgpa,
    ROUND(
        SUM(t.sgpa * t.total_credits) OVER (PARTITION BY t.user_id 
                                            ORDER BY t.academic_year, t.semester
                                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / 
        SUM(t.total_credits) OVER (PARTITION BY t.user_id 
                                   ORDER BY t.academic_year, t.semester
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 
        2
    ) AS cgpa
FROM (
    SELECT 
        s.user_id,
        s.reg_no,
        c.academic_year,
        c.semester,
        SUM(c.credit) AS total_credits,
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
                    ELSE 0
                END * c.credit
            ) / SUM(c.credit), 
            2
        ) AS sgpa
    FROM marks m
    JOIN student s ON s.user_id = m.student_id
    JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id, s.reg_no, c.academic_year, c.semester
) AS t
ORDER BY t.user_id, t.academic_year, t.semester;