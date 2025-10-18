-- ============================================
-- Detailed Attendance per Student per Course (Theory / Practical)
-- ============================================
CREATE OR REPLACE VIEW attendance_detailed AS
SELECT 
    st.user_id,
    st.reg_no,
    st.status AS student_status,
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    se.type AS session_type, -- Theory / Practical
    GROUP_CONCAT(DISTINCT se.session_date ORDER BY se.session_date) AS session_dates,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = TRUE THEN 1 ELSE 0 END) AS sessions_medical,
    SUM(a.hours_attended) AS attended_hours,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100, 2) AS attendance_percentage,
    CASE
        WHEN st.status = 'Suspended' THEN 'Not Eligible'
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id, se.type;


-- ============================================
-- Combined Attendance per Student per Course (Theory + Practical)
-- ============================================
CREATE OR REPLACE VIEW attendance_combined AS
SELECT 
    st.user_id,
    st.reg_no,
    st.status AS student_status,
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = TRUE THEN 1 ELSE 0 END) AS sessions_medical,
    SUM(a.hours_attended) AS total_attended_hours,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100, 2) AS attendance_percentage,
    CASE
        WHEN st.status = 'Suspended' THEN 'Not Eligible'
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id;


-- ============================================
-- Batch Attendance Summary (All Students in a Course)
-- ============================================
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
    SUM(CASE WHEN ac.sessions_medical > 0 THEN 1 ELSE 0 END) AS students_with_medical
FROM attendance_combined ac
JOIN course c ON c.course_id = ac.course_id
GROUP BY c.course_id, c.academic_year, c.semester;


-- ============================================
-- Individual Student Summary (All Courses)
-- ============================================
CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT
    st.user_id,
    st.reg_no,
    st.status AS student_status,
    c.course_id,
    c.name AS course_name,
    c.academic_year,
    c.semester,
    SUM(a.hours_attended) AS total_attended_hours,
    SUM(CASE WHEN a.medical = TRUE THEN a.hours_attended ELSE 0 END) AS medical_hours,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS sessions_present,
    SUM(CASE WHEN a.status = 'Absent' AND a.medical = TRUE THEN 1 ELSE 0 END) AS sessions_medical,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100, 2) AS attendance_percentage,
    ROUND((SUM(CASE WHEN a.medical = TRUE THEN a.hours_attended ELSE 0 END) / c.total_hours) * 100, 2) AS medical_percentage,
    CASE
        WHEN st.status = 'Suspended' THEN 'Not Eligible'
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id;


-- ============================================
-- Individual Student for Specific Course
-- ============================================
-- Instead of dynamic values in a view, filter when querying:
-- SELECT * FROM student_course_attendance WHERE reg_no='ST1234' AND course_id='C001';
CREATE OR REPLACE VIEW student_course_attendance AS
SELECT *
FROM student_attendance_summary;


-- ============================================
-- Student Attendance Split (Theory / Practical)
-- ============================================
CREATE OR REPLACE VIEW student_attendance_split AS
SELECT
    st.user_id,
    st.reg_no,
    c.course_id,
    c.name AS course_name,
    se.type AS session_type,
    COUNT(a.attendance_id) AS total_sessions,
    SUM(a.hours_attended) AS attended_hours,
    SUM(CASE WHEN a.medical = TRUE THEN a.hours_attended ELSE 0 END) AS medical_hours,
    ROUND((SUM(a.hours_attended)/c.total_hours)*100,2) AS attendance_percentage,
    CASE
        WHEN st.status = 'Suspended' THEN 'Not Eligible'
        WHEN (SUM(a.hours_attended)/c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id, se.type;
