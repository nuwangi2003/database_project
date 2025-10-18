DELIMITER $$

CREATE TRIGGER trg_ca_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE best_two_sum DECIMAL(5,2);

    -- Get sum of best 2 quizzes
    SET best_two_sum = NEW.quiz1_marks + NEW.quiz2_marks + NEW.quiz3_marks
                     - LEAST(NEW.quiz1_marks, NEW.quiz2_marks, NEW.quiz3_marks);

    -- Calculate CA Marks: best 2 quizzes + assessment + mid
    SET NEW.ca_marks = best_two_sum + NEW.assessment_marks + NEW.mid_marks;
END$$

DELIMITER ;

