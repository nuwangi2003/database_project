DELIMITER $$

-- BEFORE INSERT Trigger
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE sessionHours DECIMAL(4,2);
    DECLARE student_status ENUM('Proper','Repeat','Suspended');

    -- Get session hours and student status from student_course
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

-- BEFORE UPDATE Trigger
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

-- Ca Marks Trigger
DELIMITER $$

-- BEFORE INSERT
CREATE TRIGGER trg_ca_marks_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE a DOUBLE;
    DECLARE b DOUBLE;
    DECLARE c DOUBLE;
    DECLARE best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c); -- sum of best two
    SET NEW.ca_marks = ROUND((best_two_sum / 2 * 0.10)
                        + IFNULL(NEW.assessment_marks,0)*0.15
                        + IFNULL(NEW.mid_marks,0)*0.15,2);
END$$

-- BEFORE UPDATE
CREATE TRIGGER trg_ca_marks_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE a DOUBLE;
    DECLARE b DOUBLE;
    DECLARE c DOUBLE;
    DECLARE best_two_sum DOUBLE;

    SET a = IFNULL(NEW.quiz1_marks,0);
    SET b = IFNULL(NEW.quiz2_marks,0);
    SET c = IFNULL(NEW.quiz3_marks,0);

    SET best_two_sum = a + b + c - LEAST(a,b,c);
    SET NEW.ca_marks = ROUND((best_two_sum / 2 * 0.10)
                        + IFNULL(NEW.assessment_marks,0)*0.15
                        + IFNULL(NEW.mid_marks,0)*0.15,2);
END$$

DELIMITER ;

DELIMITER $$

-- BEFORE INSERT
CREATE TRIGGER trg_marks_eligibility_before_insert
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;

    -- Get student status
    SELECT IFNULL(sc.status,'Proper') INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    -- Attendance %
    SELECT IFNULL(attendance_percentage,0) INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    -- Approved medicals
    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Mid'
      AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Final'
      AND status = 'Approved';

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
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    --  Final marks = (final_theory + final_practical) * 0.6 + ca_marks
    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0) + IFNULL(NEW.final_practical,0)) * 0.6) + IFNULL(NEW.ca_marks,0), 2);
END$$


-- BEFORE UPDATE
CREATE TRIGGER trg_marks_eligibility_before_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
    DECLARE student_status ENUM('Proper','Repeat','Suspended');
    DECLARE attendance_pct DECIMAL(6,2);
    DECLARE mid_med INT DEFAULT 0;
    DECLARE final_med INT DEFAULT 0;

    SELECT IFNULL(sc.status,'Proper') INTO student_status
    FROM student_course sc
    WHERE sc.student_id = NEW.student_id AND sc.course_id = NEW.course_id
    LIMIT 1;

    SELECT IFNULL(attendance_percentage,0) INTO attendance_pct
    FROM student_attendance_summary
    WHERE student_id = NEW.student_id AND course_id = NEW.course_id
    LIMIT 1;

    SELECT COUNT(*) INTO mid_med
    FROM medical
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Mid'
      AND status = 'Approved';

    SELECT COUNT(*) INTO final_med
    FROM medical
    WHERE student_id = NEW.student_id
      AND course_id = NEW.course_id
      AND exam_type = 'Final'
      AND status = 'Approved';

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
    ELSEIF attendance_pct < 80 THEN
        SET NEW.final_eligible = 'E*';
    ELSEIF final_med > 0 THEN
        SET NEW.final_eligible = 'MC';
    ELSE
        SET NEW.final_eligible = 'Eligible';
    END IF;

    -- Final marks formula
    SET NEW.final_marks = ROUND(((IFNULL(NEW.final_theory,0) + IFNULL(NEW.final_practical,0)) * 0.6) + IFNULL(NEW.ca_marks,0), 2);
END$$

DELIMITER ;


DELIMITER $$

DROP PROCEDURE IF EXISTS calculate_results$$

CREATE PROCEDURE calculate_results()
BEGIN
    DECLARE done_student INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(50);

    -- Only iterate students who have marks (faster)
    DECLARE student_cursor CURSOR FOR SELECT DISTINCT student_id FROM marks;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_student = TRUE;

    OPEN student_cursor;

    student_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done_student THEN
            LEAVE student_loop;
        END IF;

        -- Per-student semester loop
        BEGIN
            DECLARE done_sem INT DEFAULT FALSE;
            DECLARE a_year INT;
            DECLARE sem VARCHAR(10);

            DECLARE sem_cursor CURSOR FOR
                SELECT DISTINCT c.academic_year, c.semester
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = s_id
                ORDER BY c.academic_year, c.semester;

            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_sem = TRUE;

            OPEN sem_cursor;

            sem_loop: LOOP
                FETCH sem_cursor INTO a_year, sem;
                IF done_sem THEN
                    LEAVE sem_loop;
                END IF;

                -- 1) Assign grades with attendance considered
                UPDATE marks m
                JOIN course c ON c.course_id = m.course_id
                LEFT JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                LEFT JOIN student_attendance_summary sas ON sas.student_id = m.student_id AND sas.course_id = m.course_id
                SET m.grade = CASE
                    WHEN IFNULL(sc.status,'Proper') = 'Suspended' THEN 'WH'
                    WHEN IFNULL(sas.attendance_percentage,0) < 80 THEN 'E*'
                    WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'MC'
                    WHEN IFNULL(m.ca_eligible,'') = 'Not Eligible'
                         AND ((IFNULL(m.final_theory,0) + IFNULL(m.final_practical,0)) * 0.6) < 35 THEN 'ECA & ESA'
                    WHEN IFNULL(m.ca_eligible,'') = 'Not Eligible' THEN 'ECA'
                    WHEN ((IFNULL(m.final_theory,0) + IFNULL(m.final_practical,0)) * 0.6) < 35 THEN 'ESA'
                    WHEN IFNULL(sc.status,'Proper') = 'Proper' AND m.final_marks IS NULL THEN 'E*'
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

                -- 2) Cap Repeat students (cap high grades down to 'C')
                UPDATE marks m
                JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                JOIN course c ON c.course_id = m.course_id
                SET m.grade = CASE
                    WHEN sc.status = 'Repeat' AND m.grade IN ('A+','A','A-','B+','B','B-','C+') THEN 'C'
                    ELSE m.grade
                END
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem;

                -- 3) SGPA calculation for this student, semester
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
                    ),0) AS total_credit_points,
                    IFNULL(SUM(c.credit),0) AS total_credits
                INTO @total_credit_points, @total_credits
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem
                  AND m.grade NOT IN ('ECA','ESA','ECA & ESA','E*','MC','WH');

                IF @total_credits > 0 THEN
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id, a_year, sem, ROUND(@total_credit_points/@total_credits,2), @total_credits)
                    ON DUPLICATE KEY UPDATE
                        sgpa = ROUND(@total_credit_points/@total_credits,2),
                        total_credits = @total_credits;
                ELSE
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id, a_year, sem, NULL, 0)
                    ON DUPLICATE KEY UPDATE
                        sgpa = NULL,
                        total_credits = 0;
                END IF;

            END LOOP sem_loop;

            CLOSE sem_cursor;
        END;
    END LOOP student_loop;

    CLOSE student_cursor;

    -- 4) CGPA calculation (weighted average of semester SGPAs by credits)
    UPDATE result r
    JOIN (
        SELECT student_id,
               ROUND(SUM(sgpa * total_credits) / NULLIF(SUM(total_credits),0), 2) AS calc_cgpa
        FROM result
        WHERE sgpa IS NOT NULL
        GROUP BY student_id
    ) t ON r.student_id = t.student_id
    SET r.cgpa = t.calc_cgpa;

END$$

DELIMITER ;
