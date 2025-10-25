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
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
          AND exam_type = 'Mid' AND status = 'Approved';

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
    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)
                      + IFNULL(NEW.ca_marks,0),2);
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
        SET NEW.final_eligible = 'Eligible'; -- Attendance ignored
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0)+IFNULL(NEW.final_practical,0))*0.6)
                      + IFNULL(NEW.ca_marks,0),2);
END$$
DELIMITER ;