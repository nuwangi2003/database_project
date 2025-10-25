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
