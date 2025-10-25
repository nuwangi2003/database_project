-- ==============================
-- Attendance Triggers
-- ==============================
DELIMITER $$

CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT s.session_hours, sc.status
    INTO sessionHours, student_status
    FROM session s
    JOIN student_course sc
        ON sc.student_id = NEW.student_id AND sc.course_id = s.course_id
    WHERE s.session_id = NEW.session_id
    LIMIT 1;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s2 ON s2.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.exam_type = 'Attendance'
                  AND m.course_id = s2.course_id
                  AND m.date_submitted = s2.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$


CREATE TRIGGER trg_attendance_before_update
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT s.session_hours, sc.status
    INTO sessionHours, student_status
    FROM session s
    JOIN student_course sc
        ON sc.student_id = NEW.student_id AND sc.course_id = s.course_id
    WHERE s.session_id = NEW.session_id
    LIMIT 1;

    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            IF EXISTS (
                SELECT 1
                FROM medical m
                JOIN session s2 ON s2.session_id = NEW.session_id
                WHERE m.student_id = NEW.student_id
                  AND m.exam_type = 'Attendance'
                  AND m.course_id = s2.course_id
                  AND m.date_submitted = s2.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;


-- ==============================
-- CA Marks Calculation
-- ==============================
DELIMITER $$

CREATE TRIGGER trg_ca_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE a,b,c,best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c);
    SET NEW.ca_marks = ROUND((best_two_sum/2*0.10)+ IFNULL(NEW.assessment_marks,0)*0.15+ IFNULL(NEW.mid_marks,0)*0.15,2);
END$$


CREATE TRIGGER trg_ca_marks_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE a,b,c,best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c);
    SET NEW.ca_marks = ROUND((best_two_sum/2*0.10)
+ IFNULL(NEW.assessment_marks,0)*0.15+ IFNULL(NEW.mid_marks,0)*0.15,2);
END$$

DELIMITER ;


-- ==================================================
-- Final(CA,Final,Attendence) Eligibility Triggers
-- ==================================================


DELIMITER $$

CREATE TRIGGER trg_marks_eligibility_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med, final_med INT DEFAULT 0;

    SELECT sc.status INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    SELECT attendance_percentage INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id AND exam_type = 'Mid' AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    AND exam_type = 'Final' AND status = 'Approved';

    -- CA eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF mid_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSEIF IFNULL(NEW.ca_marks,0) < 20 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -- Final eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF student_status = 'Repeat' THEN
        SET NEW.final_eligible = 'Eligible'; -- Attendance not considered for repeat
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    -- Final marks
    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)+ IFNULL(NEW.ca_marks,0),2);
END$$


CREATE TRIGGER trg_marks_eligibility_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med, final_med INT DEFAULT 0;

    SELECT sc.status INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    SELECT attendance_percentage INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    AND exam_type = 'Mid' AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id AND exam_type = 'Final' AND status = 'Approved';

    -- CA eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF mid_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSEIF IFNULL(NEW.ca_marks,0) < 20 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -- Final eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF student_status = 'Repeat' THEN
        SET NEW.final_eligible = 'Eligible'; -- Attendance ignored
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)+ IFNULL(NEW.ca_marks,0),2);
END$$

DELIMITER ;