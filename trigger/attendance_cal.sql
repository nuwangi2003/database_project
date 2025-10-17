-- Trigger to calculate hours_attended
-- when insert the data
DELIMITER $$

-- Trigger to calculate hours_attended for new attendance
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);

    -- Get the hours of the session
    SELECT session_hours INTO sessionHours
    FROM session
    WHERE session_id = NEW.session_id;

    -- If student is present, they get full session hours
    -- If absent but medical = TRUE, also count full session hours
    IF NEW.status = 'Present' THEN
        SET NEW.hours_attended = sessionHours;
    ELSEIF NEW.status = 'Absent' AND NEW.medical = TRUE THEN
        SET NEW.hours_attended = sessionHours;
    ELSE
        SET NEW.hours_attended = 0;
    END IF;
END$$

DELIMITER ;

--when update the data
DELIMITER $$

CREATE TRIGGER trg_attendance_before_update
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);

    SELECT session_hours INTO sessionHours
    FROM session
    WHERE session_id = NEW.session_id;

    IF NEW.status = 'Present' THEN
        SET NEW.hours_attended = sessionHours;
    ELSEIF NEW.status = 'Absent' AND NEW.medical = TRUE THEN
        SET NEW.hours_attended = sessionHours;
    ELSE
        SET NEW.hours_attended = 0;
    END IF;
END$$

DELIMITER ;


--- Detailed student attened view
-- need to note here guys JOIN and INNER JOIN are equal
CREATE VIEW attendance_detailed AS
SELECT 
    st.user_id,
    st.reg_no,
    c.course_id,
    c.name AS course_name,
    c.total_hours,
    se.type,
    GROUP_CONCAT(se.session_date ORDER BY se.session_date) AS session_dates,
    SUM(a.hours_attended) AS attended_hours,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100, 2) AS attendance_percentage,
    CASE 
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id, se.type;


-- Combined Attendance Per Student Per Course
CREATE VIEW attendance_combined AS
SELECT 
    st.user_id,
    st.reg_no,
    c.course_id,
    c.name AS course_name,
    c.total_hours,
    SUM(a.hours_attended) AS total_attended_hours,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100, 2) AS attendance_percentage,
    CASE 
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id;



-- batch summery per curse
CREATE VIEW batch_attendance_summary AS
SELECT
    c.course_id,
    c.name AS course_name,
    ROUND(AVG(attendance_percentage), 2) AS avg_attendance_percentage,
    SUM(CASE WHEN attendance_percentage >= 80 THEN 1 ELSE 0 END) AS eligible_students,
    COUNT(*) AS total_students,
    CONCAT(ROUND((SUM(CASE WHEN attendance_percentage >= 80 THEN 1 ELSE 0 END)/COUNT(*))*100,2), '%') AS eligible_percentage
FROM attendance_combined vc
JOIN course c ON c.course_id = vc.course_id
GROUP BY c.course_id;




