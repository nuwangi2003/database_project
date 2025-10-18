------------------------
-- 1. Attendance Triggers
------------------------
DELIMITER $$

CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    SELECT session_hours INTO sessionHours
    FROM session WHERE session_id = NEW.session_id;

    SELECT status INTO student_status
    FROM student WHERE user_id = NEW.student_id;

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
                  AND m.exam_type = 'Attendance'
                  AND m.course_id = s.course_id
                  AND m.date_submitted = s.session_date
                  AND m.status = 'Approved'
            ) THEN
                SET NEW.hours_attended = sessionHours;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

------------------------
-- 2. CA Marks Trigger
------------------------
DELIMITER $$

CREATE TRIGGER trg_ca_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE best_two_sum DECIMAL(5,2);
    DECLARE quiz_component DECIMAL(5,2);

    -- Get sum of best two quizzes
    SET best_two_sum = NEW.quiz1_marks + NEW.quiz2_marks + NEW.quiz3_marks
                     - LEAST(NEW.quiz1_marks, NEW.quiz2_marks, NEW.quiz3_marks);

    -- Average of best two then scaled by 0.1
    SET quiz_component = (best_two_sum / 2) * 0.1;

    -- Calculate full CA
    SET NEW.ca_marks = quiz_component + (NEW.assessment_marks * 0.15) + (NEW.mid_marks * 0.15);
END$$

DELIMITER ;

------------------------
-- 3. Eligibility & Final Marks Trigger
------------------------
DELIMITER $$

CREATE TRIGGER trg_marks_eligibility
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE attendance_pct DECIMAL(5,2) DEFAULT 0;
    DECLARE ca_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;
    DECLARE final_total DECIMAL(5,2) DEFAULT 0;

    -- Attendance %
    SELECT attendance_percentage INTO attendance_pct
    FROM student WHERE user_id = NEW.student_id;

    -- Check medicals
    SELECT COUNT(*) INTO ca_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
      AND exam_type = 'CA' AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
      AND exam_type = 'Final' AND status = 'Approved';

    -----------------------
    -- CA Eligibility
    -----------------------
    IF NEW.ca_marks < 20 AND ca_med = 0 THEN
        SET NEW.ca_eligible = 'Not Eligible';
    ELSEIF ca_med > 0 THEN
        SET NEW.ca_eligible = 'MC';
    ELSE
        SET NEW.ca_eligible = 'Eligible';
    END IF;

    -----------------------
    -- Final Eligibility
    -----------------------
    SET final_total = (NEW.final_theory + NEW.final_practical) * 0.6;

    IF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_total < 30 AND final_med = 0 THEN
        SET NEW.final_eligible = 'Not Eligible';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    -----------------------
    -- Calculate Final Marks
    -----------------------
    IF NEW.ca_eligible IN ('Eligible','MC') AND NEW.final_eligible IN ('Eligible','MC') THEN
        SET NEW.final_marks = NEW.ca_marks + final_total;
    ELSE
        SET NEW.final_marks = 0;
    END IF;
END$$

DELIMITER ;

------------------------
-- 4. Calculate Results Procedure
------------------------
DELIMITER $$

CREATE PROCEDURE calculate_results()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(10);
    DECLARE a_year INT;
    DECLARE sem ENUM('1','2');

    DECLARE student_cursor CURSOR FOR SELECT user_id FROM student;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN student_cursor;

    read_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET a_year = 1;
        WHILE a_year <= 4 DO
            SET sem = '1';
            WHILE sem <= '2' DO
                -- Step 1: Update Grades
                UPDATE marks
                SET grade = CASE
                    WHEN final_marks < 40 THEN 'E'
                    WHEN ca_eligible = 'Not Eligible' THEN 'ECA'
                    WHEN final_eligible = 'Not Eligible' THEN 'ESA'
                    WHEN final_marks >= 85 THEN 'A+'
                    WHEN final_marks >= 75 THEN 'A'
                    WHEN final_marks >= 70 THEN 'A-'
                    WHEN final_marks >= 65 THEN 'B+'
                    WHEN final_marks >= 60 THEN 'B'
                    WHEN final_marks >= 55 THEN 'B-'
                    WHEN final_marks >= 50 THEN 'C+'
                    WHEN final_marks >= 45 THEN 'C'
                    WHEN final_marks >= 40 THEN 'C-'
                    ELSE 'E'
                END
                WHERE student_id = s_id;

                -- Step 2: SGPA Calculation
                SET @total_credit_points := 0;
                SET @total_credits := 0;

                SELECT SUM(c.credit *
                    CASE m.grade
                        WHEN 'A+' THEN 4.0
                        WHEN 'A'  THEN 4.0
                        WHEN 'A-' THEN 3.7
                        WHEN 'B+' THEN 3.3
                        WHEN 'B'  THEN 3.0
                        WHEN 'B-' THEN 2.7
                        WHEN 'C+' THEN 2.3
                        WHEN 'C'  THEN 2.0
                        WHEN 'C-' THEN 1.7
                        ELSE 0
                    END
                ) INTO @total_credit_points
                FROM marks m
                JOIN course c ON m.course_id = c.course_id
                WHERE m.student_id = s_id AND c.academic_year = a_year AND c.semester = sem;

                SELECT SUM(c.credit) INTO @total_credits
                FROM marks m
                JOIN course c ON m.course_id = c.course_id
                WHERE m.student_id = s_id AND c.academic_year = a_year AND c.semester = sem;

                -- Step 3: Update Result
                INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                VALUES (s_id, a_year, sem, IF(@total_credits=0,0,@total_credit_points/@total_credits), @total_credits)
                ON DUPLICATE KEY UPDATE
                    sgpa = IF(@total_credits=0,0,@total_credit_points/@total_credits),
                    total_credits = @total_credits;

                SET sem = IF(sem='1','2','1');
            END WHILE;

            SET a_year = a_year + 1;
        END WHILE;
    END LOOP;

    CLOSE student_cursor;

    -- Step 4: CGPA Calculation
    UPDATE result r
    JOIN (
        SELECT student_id, SUM(sgpa*total_credits)/SUM(total_credits) AS cgpa_calc
        FROM result
        GROUP BY student_id
    ) t ON r.student_id = t.student_id
    SET r.cgpa = t.cgpa_calc;
END$$

DELIMITER ;

