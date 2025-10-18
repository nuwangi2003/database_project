DELIMITER $$

CREATE TRIGGER trg_final_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    -- If student is suspended → final_marks = 0
    IF (SELECT status FROM student WHERE user_id = NEW.student_id) = 'Suspended' THEN
        SET NEW.final_marks = 0;
    ELSE
        SET NEW.final_marks = NEW.ca_marks + NEW.final_theory + NEW.final_practical;
    END IF;
END$$

DELIMITER ;

