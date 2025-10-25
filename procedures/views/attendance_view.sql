
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

CREATE OR REPLACE VIEW v_student_attendance_details AS
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