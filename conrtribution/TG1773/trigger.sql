------------------------
-- 3. Marks Eligibility & Final Marks Trigger
------------------------
DELIMITER $$

CREATE TRIGGER trg_marks_eligibility
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(5,2) DEFAULT 0;
    DECLARE mid_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;
    DECLARE final_total DECIMAL(5,2);

    -- Fetch student status
    SELECT status 
    INTO student_status
    FROM student 
    WHERE user_id = NEW.student_id;

    -- Fetch dynamic attendance percentage from view
    SELECT attendance_percentage
    INTO attendance_pct
    FROM student_attendance_summary
    WHERE user_id = NEW.student_id
      AND course_id = NEW.course_id;

    -- Check medical for CA
    SELECT COUNT(*) INTO mid_med
    FROM medical 
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Mid'
      AND status = 'Approved';

    -- Check medical for Final
    SELECT COUNT(*) INTO final_med
    FROM medical 
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Final'
      AND status = 'Approved';

    -- CA eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF (NEW.quiz1_marks IS NULL OR NEW.quiz2_marks IS NULL OR NEW.quiz3_marks IS NULL
            OR NEW.assessment_marks IS NULL OR NEW.mid_marks IS NULL) AND mid_med = 0 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSEIF mid_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -- Final eligibility
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF (NEW.final_theory IS NULL OR NEW.final_practical IS NULL) AND final_med = 0 THEN
        SET NEW.final_eligible = 'Not Eligible';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    -- Final marks = (final_theory + final_practical) × 0.6
    SET final_total = (IFNULL(NEW.final_theory,0) + IFNULL(NEW.final_practical,0)) * 0.6;

    -- Combine CA + Final
    IF NEW.ca_eligible IN ('Eligible','MC') AND NEW.final_eligible IN ('Eligible','MC') THEN
        SET NEW.final_marks = ROUND(NEW.ca_marks + final_total, 2);
    ELSE
        SET NEW.final_marks = 0;
    END IF;
END$$

DELIMITER ;