DELIMITER $$

CREATE PROCEDURE calculate_results()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(10);
    
    -- Cursor to iterate all students
    DECLARE student_cursor CURSOR FOR SELECT user_id FROM student;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN student_cursor;

    read_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Loop through all academic years and semesters student is registered
        DECLARE sem_done INT DEFAULT FALSE;
        DECLARE a_year INT;
        DECLARE sem ENUM('1','2');
        DECLARE sem_cursor CURSOR FOR
            SELECT DISTINCT c.academic_year, c.semester
            FROM student_course sc
            JOIN course c ON sc.course_id = c.course_id
            WHERE sc.student_id = s_id
            ORDER BY c.academic_year, c.semester;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET sem_done = TRUE;

        OPEN sem_cursor;
        sem_loop: LOOP
            FETCH sem_cursor INTO a_year, sem;
            IF sem_done THEN
                LEAVE sem_loop;
            END IF;

            -- Step 1: Update CA Marks for each course
            UPDATE marks
            SET ca_marks = 
                (quiz1_marks + quiz2_marks + quiz3_marks - LEAST(quiz1_marks, quiz2_marks, quiz3_marks))
                + assessment_marks + mid_marks
            WHERE student_id = s_id
              AND course_id IN (SELECT course_id 
                                FROM student_course 
                                WHERE student_id = s_id
                                  AND course_id IN 
                                    (SELECT course_id FROM course WHERE academic_year = a_year AND semester = sem));

            -- Step 2: Update final marks
            UPDATE marks
            SET final_marks = ca_marks + final_theory + final_practical
            WHERE student_id = s_id
              AND course_id IN (SELECT course_id 
                                FROM student_course 
                                WHERE student_id = s_id
                                  AND course_id IN 
                                    (SELECT course_id FROM course WHERE academic_year = a_year AND semester = sem));

            -- Step 3: Update grade and eligibility
            UPDATE marks m
            JOIN course c ON m.course_id = c.course_id
            JOIN student st ON m.student_id = st.user_id
            SET m.grade = CASE
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
            END,
            m.ca_eligible = CASE
                WHEN st.status = 'Suspended' THEN 'WH'
                WHEN m.quiz1_marks IS NULL OR m.quiz2_marks IS NULL OR m.quiz3_marks IS NULL
                     OR m.assessment_marks IS NULL OR m.mid_marks IS NULL THEN 'MC'
                ELSE 'Eligible'
            END,
            m.final_eligible = CASE
                WHEN st.status = 'Suspended' THEN 'WH'
                WHEN m.final_theory IS NULL OR m.final_practical IS NULL THEN 'MC'
                ELSE 'Eligible'
            END
            WHERE m.student_id = s_id
              AND c.academic_year = a_year
              AND c.semester = sem;

            -- Step 4: Calculate SGPA
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
                        END) 
            INTO @total_credit_points
            FROM marks m
            JOIN course c ON m.course_id = c.course_id
            WHERE m.student_id = s_id
              AND c.academic_year = a_year
              AND c.semester = sem;

            SELECT SUM(c.credit) INTO @total_credits
            FROM marks m
            JOIN course c ON m.course_id = c.course_id
            WHERE m.student_id = s_id
              AND c.academic_year = a_year
              AND c.semester = sem;

            -- Step 5: Insert/update result table
            INSERT INTO result(student_id, academic_year, semester, sgpa, total_credits)
            VALUES(s_id, a_year, sem, IF(@total_credits=0,0,@total_credit_points/@total_credits), @total_credits)
            ON DUPLICATE KEY UPDATE
                sgpa = IF(@total_credits=0,0,@total_credit_points/@total_credits),
                total_credits = @total_credits;

        END LOOP sem_loop;

        CLOSE sem_cursor;

        -- Step 6: Calculate CGPA for the student
        UPDATE result r
        JOIN (
            SELECT student_id, SUM(sgpa*total_credits)/SUM(total_credits) AS cgpa_calc
            FROM result
            WHERE student_id = s_id
            GROUP BY student_id
        ) t ON r.student_id = t.student_id
        SET r.cgpa = t.cgpa_calc;

    END LOOP read_loop;

    CLOSE student_cursor;
END$$

DELIMITER ;
