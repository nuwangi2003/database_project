-- ==============================
-- 1️⃣ Attendance Triggers
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
-- 2️⃣ CA Marks Calculation
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
    SET NEW.ca_marks = ROUND((best_two_sum/2*0.10)
                      + IFNULL(NEW.assessment_marks,0)*0.15
                      + IFNULL(NEW.mid_marks,0)*0.15,2);
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
                      + IFNULL(NEW.assessment_marks,0)*0.15
                      + IFNULL(NEW.mid_marks,0)*0.15,2);
END$$

DELIMITER ;



-- Eligibility Triggers

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


DELIMITER $$

DROP PROCEDURE IF EXISTS calculate_results$$

CREATE PROCEDURE calculate_results()
BEGIN
    -- Outer / student-level declarations (must be at the top)
    DECLARE done_student INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(50);
    DECLARE done_sem INT DEFAULT FALSE;
    DECLARE a_year INT;
    DECLARE sem VARCHAR(10);

    DECLARE student_cursor CURSOR FOR SELECT DISTINCT student_id FROM marks;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_student = TRUE;

    OPEN student_cursor;

    student_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done_student THEN LEAVE student_loop; END IF;

        -- Reset semester-done flag for this student
        SET done_sem = FALSE;

        -- Start an inner block so we can declare the sem_cursor and its handler here
        BEGIN
            -- Declarations for this inner block must be here (before statements)
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
                IF done_sem THEN LEAVE sem_loop; END IF;

                -- Update grades
                UPDATE marks m
                JOIN course c ON c.course_id = m.course_id
                JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                LEFT JOIN student_attendance_summary sas ON sas.student_id = m.student_id AND sas.course_id = m.course_id
                SET m.grade = CASE
                    WHEN sc.status = 'Suspended' THEN 'WH'
                    WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'MC'
                    WHEN m.ca_eligible = 'Not Eligible' AND ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ECA & ESA'
                    WHEN m.ca_eligible = 'Not Eligible' THEN 'ECA'
                    WHEN ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ESA'
                    WHEN sc.status='Proper' AND IFNULL(sas.attendance_percentage,100) < 80 THEN 'E*'
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

                -- Cap repeat students' grades
                UPDATE marks m
                JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                JOIN course c ON c.course_id = m.course_id
                SET m.grade = CASE
                    WHEN sc.status = 'Repeat' AND m.grade IN ('A+','A','A-','B+','B','B-','C+') THEN 'C'
                    ELSE m.grade END
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem;

                -- Calculate SGPA for this student/year/semester (exclude non-numeric grade types)
                SET @total_points = 0;
                SET @total_credits = 0;

                SELECT
                    IFNULL(SUM(c.credit *
                        CASE m.grade
                            WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                            WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                            WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                            WHEN 'D' THEN 1.3 ELSE 0 END),0),
                    IFNULL(SUM(c.credit),0)
                INTO @total_points, @total_credits
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                WHERE m.student_id = s_id
                  AND c.academic_year = a_year
                  AND c.semester = sem
                  AND m.grade NOT IN ('ECA','ESA','ECA & ESA','E*','MC','WH');

                -- If student has any Suspended status anywhere, store WH for this semester result
                IF EXISTS (SELECT 1 FROM student_course WHERE student_id = s_id AND status='Suspended') THEN
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id,a_year,sem,'WH',0)
                    ON DUPLICATE KEY UPDATE sgpa='WH',total_credits=0;
                ELSEIF @total_credits>0 THEN
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id,a_year,sem,ROUND(@total_points/@total_credits,2),@total_credits)
                    ON DUPLICATE KEY UPDATE sgpa=ROUND(@total_points/@total_credits,2),total_credits=@total_credits;
                ELSE
                    INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
                    VALUES (s_id,a_year,sem,NULL,0)
                    ON DUPLICATE KEY UPDATE sgpa=NULL,total_credits=0;
                END IF;

            END LOOP; -- sem_loop

            CLOSE sem_cursor;
        END; -- inner block

        -- reset done_sem just in case (it will be reset at top of next student)
        SET done_sem = FALSE;

    END LOOP; -- student_loop

    CLOSE student_cursor;

    -- CGPA update: compute weighted average only from numeric SGPA entries (skip 'WH' and NULL)
    UPDATE result r
    JOIN (
        SELECT student_id,
               CASE
                   WHEN SUM(CASE WHEN sgpa IS NOT NULL AND sgpa NOT IN ('WH') THEN total_credits ELSE 0 END) = 0
                       THEN 'WH'
                   ELSE ROUND(
                       SUM(
                         CASE WHEN sgpa IS NOT NULL AND sgpa NOT IN ('WH')
                              THEN CAST(sgpa AS DECIMAL(6,2)) * total_credits
                              ELSE 0 END
                       ) / SUM(CASE WHEN sgpa IS NOT NULL AND sgpa NOT IN ('WH') THEN total_credits ELSE 0 END),2)
               END AS calc_cgpa
        FROM result
        GROUP BY student_id
    ) t ON r.student_id = t.student_id
    SET r.cgpa = t.calc_cgpa;
END$$

DELIMITER ;
