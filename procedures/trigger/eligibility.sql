DELIMITER $$

CREATE TRIGGER trg_marks_eligibility
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(5,2) DEFAULT 0;
    DECLARE ca_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;

    -- Get student status and attendance percentage
    SELECT status, attendance_percentage 
    INTO student_status, attendance_pct
    FROM student 
    WHERE user_id = NEW.student_id;

    -- Check if student missed CA components and submitted medical
    SELECT COUNT(*) INTO ca_med
    FROM medical 
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'CA'
      AND status = 'Approved';

    -- Check if student missed Final exams and submitted medical
    SELECT COUNT(*) INTO final_med
    FROM medical 
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Final'
      AND status = 'Approved';

    ------------------------
    -- CA Eligibility
    ------------------------
    IF student_status = 'Suspended' THEN
        SET NEW.ca_eligible = 'WH';
    ELSEIF (NEW.quiz1_marks IS NULL OR NEW.quiz2_marks IS NULL OR NEW.quiz3_marks IS NULL
            OR NEW.assessment_marks IS NULL OR NEW.mid_marks IS NULL) AND ca_med = 0 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSEIF ca_med > 0 THEN
        SET NEW.ca_eligible = 'MC'; -- Medical concession
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    ------------------------
    -- Final Exam Eligibility (CA + ESA + Attendance)
    ------------------------
    IF student_status = 'Suspended' THEN
        SET NEW.final_eligible = 'WH';
    ELSEIF (NEW.final_theory IS NULL OR NEW.final_practical IS NULL) AND final_med = 0 THEN
        SET NEW.final_eligible = 'Not Eligible';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*'; -- Not eligible due to attendance < 80%
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    ------------------------
    -- Calculate Final Marks if eligible
    ------------------------
    IF NEW.ca_eligible IN ('Eligible','MC') AND NEW.final_eligible IN ('Eligible','MC') THEN
        SET NEW.final_marks = NEW.ca_marks + NEW.final_theory + NEW.final_practical;
    ELSE
        SET NEW.final_marks = 0;
    END IF;

END$$

DELIMITER ;
