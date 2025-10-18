DELIMITER $$

-- Before INSERT on attendance
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    -- Get session hours
    SELECT session_hours INTO sessionHours
    FROM session
    WHERE session_id = NEW.session_id;

    -- Get student status
    SELECT status INTO student_status
    FROM student
    WHERE user_id = NEW.student_id;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s ON s.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.course_id = s.course_id
                  AND m.exam_type = 'Attendance'
                  AND m.date_submitted = s.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$

-- Before UPDATE on attendance
CREATE TRIGGER trg_attendance_before_update
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT session_hours INTO sessionHours
    FROM session
    WHERE session_id = NEW.session_id;

    SELECT status INTO student_status
    FROM student
    WHERE user_id = NEW.student_id;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s ON s.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.course_id = s.course_id
                  AND m.exam_type = 'Attendance'
                  AND m.date_submitted = s.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
