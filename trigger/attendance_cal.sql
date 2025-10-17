-- Trigger to calculate hours_attended
DELIMITER //
CREATE TRIGGER trg_set_attendance_hours
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sHours DECIMAL(4,2);
    SELECT session_hours INTO sHours
    FROM session
    WHERE session_id = NEW.session_id;
    
    IF NEW.status = 'Present' OR NEW.medical = TRUE THEN
        SET NEW.hours_attended = sHours;
    ELSE
        SET NEW.hours_attended = 0;
    END IF;
END //
DELIMITER ;

-- 14. Attendance Summary View
CREATE VIEW v_attendance_summary AS
SELECT 
    st.user_id,
    st.reg_no,
    c.course_id,
    c.name AS course_name,
    c.total_hours,
    SUM(a.hours_attended) AS attended_hours,
    ROUND((SUM(a.hours_attended) / c.total_hours) * 100,2) AS attendance_percentage,
    CASE 
        WHEN (SUM(a.hours_attended) / c.total_hours) >= 0.8 THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS eligibility
FROM attendance a
JOIN student st ON st.user_id = a.student_id
JOIN session se ON se.session_id = a.session_id
JOIN course c ON c.course_id = se.course_id
GROUP BY st.user_id, c.course_id;

