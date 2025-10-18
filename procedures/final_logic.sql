------------------------
-- 1. Attendance Triggers
------------------------
DELIMITER $$

-- INSERT Trigger
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

    -- Default hours attended
    SET NEW.hours_attended = 0;

    -- Handle attendance
    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            -- Check medical approval
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

-- UPDATE Trigger
CREATE TRIGGER trg_attendance_before_update
BEFORE UPDATE ON attendance
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

    -- Default hours attended
    SET NEW.hours_attended = 0;

    -- Handle attendance
    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            -- Check medical approval
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

    -- Sum of best two quizzes
    SET best_two_sum = NEW.quiz1_marks + NEW.quiz2_marks + NEW.quiz3_marks
                     - LEAST(NEW.quiz1_marks, NEW.quiz2_marks, NEW.quiz3_marks);

    -- Calculate CA Marks
    SET NEW.ca_marks = best_two_sum + NEW.assessment_marks + NEW.mid_marks;
END$$

DELIMITER ;

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
    DECLARE ca_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;

    -- Get student status and attendance percentage
    SELECT status, attendance_percentage 
    INTO student_status, attendance_pct
    FROM student 
    WHERE user_id = NEW.student_id;

    -- Check medical for CA
    SELECT COUNT(*) INTO ca_med
    FROM medical 
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'CA'
      AND status = 'Approved';

    -- Check medical for Final exams
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
        SET NEW.ca_eligible = 'MC';
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
        SET NEW.final_eligible = 'E*';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    ------------------------
    -- Calculate Final Marks
    ------------------------
    IF NEW.ca_eligible IN ('Eligible','MC') AND NEW.final_eligible IN ('Eligible','MC') THEN
        SET NEW.final_marks = NEW.ca_marks + NEW.final_theory + NEW.final_practical;
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

    -- Cursor to iterate students
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

                -- Step 1: Update CA and Final Marks via triggers
                -- Marks table will be auto-updated using triggers

                -- Step 2: Assign grades based on final_marks
                UPDATE marks
                SET grade = CASE
                    WHEN final_marks < 40 THEN 'E'
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

                -- Step 3: Calculate SGPA
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
                        WHEN 'D'  THEN 1.3
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

                -- Step 4: Insert / Update Result table
                INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                VALUES (s_id, a_year, sem, IF(@total_credits=0,0,@total_credit_points/@total_credits), @total_credits)
                ON DUPLICATE KEY UPDATE
                    sgpa = IF(@total_credits=0,0,@total_credit_points/@total_credits),
                    total_credits = @total_credits;

                SET sem = IF(sem='1','2','1'); -- Next semester
            END WHILE;

            SET a_year = a_year + 1;
        END WHILE;
    END LOOP;

    CLOSE student_cursor;

    -- Step 5: Calculate CGPA for all students
    UPDATE result r
    JOIN (
        SELECT student_id, SUM(sgpa*total_credits)/SUM(total_credits) AS cgpa_calc
        FROM result
        GROUP BY student_id
    ) t ON r.student_id = t.student_id
    SET r.cgpa = t.cgpa_calc;

END$$

DELIMITER ;

