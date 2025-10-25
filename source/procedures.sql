-- ============================
-- Procedure: calculate_results
-- ============================
DELIMITER $$


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
                    WHEN m.ca_eligible = 'Not Eligible' AND ((IFNULL(m.final_theory,0)
                    +IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ECA & ESA'
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
                WHERE m.student_id = s_id AND c.academic_year = a_year AND c.semester = sem;

                -- Cap repeat students' grades
                UPDATE marks m
                JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
                JOIN course c ON c.course_id = m.course_id
                SET m.grade = CASE
                    WHEN sc.status = 'Repeat' AND m.grade IN ('A+','A','A-','B+','B','B-','C+') THEN 'C'
                    ELSE m.grade END
                WHERE m.student_id = s_id AND c.academic_year = a_year AND c.semester = sem;

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






-- =================================
-- Procedure: generate_student_academic_report
-- =================================
DELIMITER $$

CREATE PROCEDURE generate_student_academic_report(IN p_reg_no VARCHAR(15))
BEGIN
    DECLARE v_student_id VARCHAR(10);

    
    SELECT user_id INTO v_student_id
    FROM student
    WHERE reg_no = p_reg_no;

    
    IF v_student_id IS NULL THEN
        SELECT CONCAT('No student found with reg_no: ', p_reg_no) AS message;
    ELSE
        
        SELECT 
            s.reg_no,
            s.batch,
            s.department_id
        FROM student s
        WHERE s.user_id = v_student_id;

        
        SELECT 
            course_id,
            course_name,
            ca_marks,
            final_marks,
            ca_eligible,
            final_eligible,
            grade
        FROM student_marks_summary
        WHERE student_id = v_student_id;

        
        SELECT 
            academic_year,
            semester,
            semester_result
        FROM semester_pass_fail
        WHERE reg_no = p_reg_no;

        
        SELECT 
            academic_year,
            semester,
            cgpa,
            class_status
        FROM student_class
        WHERE reg_no = p_reg_no;
    END IF;

END$$

DELIMITER ;




CALL generate_full_student_report('TG/2023/1704');
