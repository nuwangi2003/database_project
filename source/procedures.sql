
-- Procedure: calculate_results

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







-- Procedure: generate_student_academic_report

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
 


 								-- Cgpa Check every sem
DELIMITER $$

DROP PROCEDURE IF EXISTS get_progressive_cgpa$$

CREATE PROCEDURE get_progressive_cgpa(IN p_student_id VARCHAR(10))
BEGIN
    SELECT
        r.student_id,
        s.reg_no,
        r.academic_year,
        r.semester,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = r.student_id
                  AND c.academic_year = r.academic_year
                  AND c.semester = r.semester
                  AND m.grade = 'MC'
            ) THEN 'WH'
            ELSE CAST(r.sgpa AS CHAR)
        END AS sgpa,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM marks m
                JOIN course c ON c.course_id = m.course_id
                WHERE m.student_id = r.student_id
                  AND c.academic_year = r.academic_year
                  AND c.semester = r.semester
                  AND m.grade = 'MC'
            ) THEN 'WH'
            ELSE CAST(
                ROUND((
                    SELECT SUM(r2.sgpa) / COUNT(r2.sgpa)
                    FROM result r2
                    WHERE r2.student_id = r.student_id
                      AND (
                            r2.academic_year < r.academic_year
                            OR (r2.academic_year = r.academic_year AND r2.semester <= r.semester)
                          )
                ), 2) AS CHAR)
        END AS cgpa
    FROM result r
    JOIN student s ON s.user_id = r.student_id
    WHERE (p_student_id IS NULL OR r.student_id = p_student_id)
    ORDER BY r.student_id, r.academic_year, r.semester;
END$$

DELIMITER ;


								-- batch_department_marks

DELIMITER $$

DROP PROCEDURE IF EXISTS get_batch_department_marks$$

CREATE PROCEDURE get_batch_department_marks(IN p_batch VARCHAR(10))
BEGIN
    SELECT 
        s.user_id,
        s.reg_no,
        s.batch,
        d.name AS department_name,
        m.course_id,
        c.name AS course_name,
        c.academic_year,
        c.semester,
        m.ca_marks,
        m.final_marks,
        m.ca_eligible,
        m.final_eligible,
        m.grade,
        CASE 
            WHEN m.grade = 'MC' THEN 'WH'
            WHEN m.grade IN ('E', 'ECA & ESA','ECA','ESA') THEN 'Fail'
            ELSE 'Pass'
        END AS status
    FROM marks m
    JOIN student s 
        ON s.user_id = m.student_id
    JOIN course c 
        ON c.course_id = m.course_id
    LEFT JOIN department d 
        ON s.department_id = d.department_id
    WHERE (p_batch IS NULL OR s.batch = p_batch)
    ORDER BY s.batch, d.name, s.reg_no, c.academic_year, c.semester;
END$$

DELIMITER ;


								v_student_overall_eligibility

								--- 1) Student-level overall eligibility (reg_no comes from student)
-- Drop procedure if it exists
DROP PROCEDURE IF EXISTS get_student_overall_eligibility;

DELIMITER $$

CREATE PROCEDURE get_student_overall_eligibility()
BEGIN
    SELECT 
        m.student_id,
        s.reg_no,
        m.course_id,
        c.name AS course_name,
        c.academic_year,
        c.semester,

        -- From attendance summary (may be NULL if no summary)
        COALESCE(sas.attendance_percentage, 0) AS attendance_percentage,
        COALESCE(sas.eligibility, 'Unknown') AS attendance_eligibility,

        -- From marks table
        m.ca_marks,
        m.ca_eligible,
        m.final_eligible,

        -- Overall Eligibility Logic
        CASE
            WHEN COALESCE(sas.eligibility, 'Unknown') = 'Not Eligible' 
                THEN 'Not Eligible (Attendance < 80%)'
            WHEN COALESCE(m.ca_eligible, 'Not Eligible') = 'Not Eligible' 
                THEN 'Not Eligible (CA Failed)'
            WHEN COALESCE(m.final_eligible, 'Not Eligible') = 'Not Eligible' 
                THEN 'Not Eligible (Final Failed)'
            WHEN COALESCE(m.ca_eligible, '') = 'WH' OR COALESCE(m.final_eligible, '') = 'WH' 
                THEN 'Withheld'
            WHEN COALESCE(m.ca_eligible, '') = 'MC' OR COALESCE(m.final_eligible, '') = 'MC' 
                THEN 'Eligible with Medical'
            ELSE 'Fully Eligible'
        END AS overall_eligibility
    FROM marks m
    LEFT JOIN student_attendance_summary sas
        ON sas.student_id = m.student_id
        AND sas.course_id = m.course_id
    JOIN course c
        ON c.course_id = m.course_id
    LEFT JOIN student_course sc
        ON sc.student_id = m.student_id
        AND sc.course_id = m.course_id
    JOIN student s
        ON s.user_id = m.student_id;
END$$

DELIMITER ;

=======



--give one student marks  CALL get_student_course_marks('U013', 'ICT1222');


DELIMITER $$

CREATE PROCEDURE get_student_course_marks (
    IN p_reg_no VARCHAR(20),
    IN p_course_id VARCHAR(20)
)
BEGIN
    SELECT 
        quiz1_marks + quiz2_marks + quiz3_marks AS `TOTAL QUIZ MARKS`,
        assessment_marks AS `ASSESSMENT_MARKS`,
        mid_marks,
        final_theory + final_practical AS `FINAL EXAM MARKS`
    FROM marks
    WHERE student_id = p_reg_no
      AND course_id = p_course_id;
END $$

DELIMITER ;



--  check one student eligibility CALL get_student_eligibility('U013', 'ICT1222');



DELIMITER $$

DROP PROCEDURE IF EXISTS get_student_eligibility$$


CREATE PROCEDURE get_student_eligibility(
    IN p_user_id VARCHAR(20),
    IN p_course_id VARCHAR(20)
)
BEGIN
    SELECT a_d.session_type AS `PRACTICAL/THEORY`,a_d.eligibility AS `ELIGIBILITY FOR THE EXAM`
    FROM attendance_detailed AS a_d
    WHERE a_d.student_id = p_user_id
      AND a_d.course_id = p_course_id;
END $$


DELIMITER ;


----  one course check final marks and eligibility  CALL get_batch_marks_summary_by_course(''Database Management Systems'');


DELIMITER $$

CREATE PROCEDURE  get_batch_marks_summary_by_course (
    IN p_course_name VARCHAR(100)
)
BEGIN
    SELECT 
        c.course_id,
        c.name AS course_name,
        c.academic_year,
        c.semester,

        COUNT(*) AS total_students,
        SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) AS fully_eligible,
        SUM(CASE WHEN overall_eligibility LIKE 'Not Eligible%' THEN 1 ELSE 0 END) AS not_eligible,
        SUM(CASE WHEN overall_eligibility = 'Eligible with Medical' THEN 1 ELSE 0 END) AS medical_cases,
        SUM(CASE WHEN overall_eligibility = 'Withheld' THEN 1 ELSE 0 END) AS withheld_cases,

        ROUND(SUM(CASE WHEN overall_eligibility = 'Fully Eligible' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS eligible_percentage

    FROM student_overall_eligibility soe
    JOIN course c ON c.course_id = soe.course_id
    WHERE c.name = p_course_name
    GROUP BY c.course_id, c.academic_year, c.semester;
END $$



