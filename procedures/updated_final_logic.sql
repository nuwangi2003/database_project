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

    -- Get session hours and student status
    SELECT s.session_hours, st.status 
    INTO sessionHours, student_status
    FROM session s
    JOIN student st ON st.user_id = NEW.student_id
    WHERE s.session_id = NEW.session_id;

    -- Default hours
    SET NEW.hours_attended = 0;

    IF student_status != 'Suspended' THEN
        IF NEW.status = 'Present' THEN
            SET NEW.hours_attended = sessionHours;
        ELSEIF NEW.status = 'Absent' THEN
            -- Approved medical attendance
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

    SELECT s.session_hours, st.status 
    INTO sessionHours, student_status
    FROM session s
    JOIN student st ON st.user_id = NEW.student_id
    WHERE s.session_id = NEW.session_id;

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
    DECLARE quiz_avg DECIMAL(5,2);
    DECLARE assessment_contrib DECIMAL(5,2);
    DECLARE mid_contrib DECIMAL(5,2);

    -- Best two quizzes
    SET best_two_sum = NEW.quiz1_marks + NEW.quiz2_marks + NEW.quiz3_marks
                     - LEAST(NEW.quiz1_marks, NEW.quiz2_marks, NEW.quiz3_marks);

    -- Quiz contribution (10%)
    SET quiz_avg = (best_two_sum / 2) * 0.1;

    -- Assessment and mid
    SET assessment_contrib = NEW.assessment_marks * 0.15;
    SET mid_contrib = NEW.mid_marks * 0.15;

    SET NEW.ca_marks = ROUND(quiz_avg + assessment_contrib + mid_contrib, 2);
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

------------------------
-- 4. Calculate Results Procedure
------------------------
DELIMITER $$

CREATE PROCEDURE calculate_results()
BEGIN
    DECLARE done_student INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(10);

    -- Outer cursor: all students
    DECLARE student_cursor CURSOR FOR SELECT user_id FROM student;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_student = TRUE;

    OPEN student_cursor;

    student_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done_student THEN
            LEAVE student_loop;
        END IF;

        -- Inner block for per-student semester cursor
        BEGIN
            DECLARE done_sem INT DEFAULT FALSE;
            DECLARE a_year INT;
            DECLARE sem VARCHAR(4);

            DECLARE sem_cursor CURSOR FOR
                SELECT DISTINCT c.academic_year, c.semester
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = s_id
                ORDER BY c.academic_year, c.semester;

            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_sem = TRUE;

            SET done_sem = FALSE;
            OPEN sem_cursor;

            sem_loop: LOOP
                FETCH sem_cursor INTO a_year, sem;
                IF done_sem THEN
                    LEAVE sem_loop;
                END IF;

                -- Update grades
                UPDATE marks m
                JOIN course c ON m.course_id = c.course_id
                SET m.grade = CASE
                    WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'MC'
                    WHEN m.ca_eligible = 'Not Eligible' AND m.final_eligible = 'Not Eligible' THEN 'ECA & ESA'
                    WHEN m.ca_eligible = 'Not Eligible' THEN 'ECA'
                    WHEN m.final_eligible = 'Not Eligible' THEN 'ESA'
                    WHEN m.final_marks < 35 THEN 'E'
                    WHEN m.final_marks >= 85 THEN 'A+'
                    WHEN m.final_marks >= 75 THEN 'A'
                    WHEN m.final_marks >= 70 THEN 'A-'
                    WHEN m.final_marks >= 65 THEN 'B+'
                    WHEN m.final_marks >= 60 THEN 'B'
                    WHEN m.final_marks >= 55 THEN 'B-'
                    WHEN m.final_marks >= 50 THEN 'C+'
                    WHEN m.final_marks >= 45 THEN 'C'
                    WHEN m.final_marks >= 40 THEN 'C-'
                    WHEN m.final_marks >= 35 THEN 'D'
                    ELSE 'E'
                END
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem;

                -- Calculate SGPA
                SET @total_credit_points = 0;
                SET @total_credits = 0;

                SELECT 
                    IFNULL(SUM(c.credit *
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
                    ), 0),
                    IFNULL(SUM(c.credit), 0)
                INTO @total_credit_points, @total_credits
                FROM marks m
                JOIN course c ON m.course_id = c.course_id
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem;

                IF @total_credits > 0 THEN
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id, a_year, sem, ROUND(@total_credit_points / @total_credits, 2), @total_credits)
                    ON DUPLICATE KEY UPDATE
                        sgpa = ROUND(@total_credit_points / @total_credits, 2),
                        total_credits = @total_credits;
                END IF;

            END LOOP sem_loop;

            CLOSE sem_cursor;
        END; -- inner block

    END LOOP student_loop;

    CLOSE student_cursor;

    -- Calculate CGPA
    UPDATE result r
    JOIN (
        SELECT student_id,
               SUM(sgpa * total_credits) / NULLIF(SUM(total_credits),0) AS cgpa_calc
        FROM result
        GROUP BY student_id
    ) t ON r.student_id = t.student_id
    SET r.cgpa = ROUND(t.cgpa_calc, 2)
    WHERE t.cgpa_calc IS NOT NULL;

END$$

DELIMITER ;















