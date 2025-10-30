
--- =============================================
-- Procedure 1: Update marks with grades
-- =============================================
DELIMITER $$

DROP PROCEDURE IF EXISTS update_marks_grades$$

CREATE PROCEDURE update_marks_grades()
BEGIN
    DECLARE done_student INT DEFAULT FALSE;
    DECLARE s_id VARCHAR(50);

    DECLARE student_cursor CURSOR FOR SELECT DISTINCT student_id FROM marks;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_student = TRUE;

    OPEN student_cursor;

    student_loop: LOOP
        FETCH student_cursor INTO s_id;
        IF done_student THEN LEAVE student_loop; END IF;

        -- Update grades based on rules
        UPDATE marks m
        JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
        LEFT JOIN student_attendance_summary sas ON sas.student_id = m.student_id AND sas.course_id = m.course_id
        SET m.grade = CASE
            WHEN sc.status = 'Suspended' THEN 'WH'
            WHEN m.ca_eligible = 'MC' OR m.final_eligible = 'MC' THEN 'MC'
            WHEN sc.status='Proper' AND IFNULL(sas.attendance_percentage,100) < 80 THEN 'E*'
            WHEN m.ca_eligible = 'Not Eligible' AND ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ECA & ESA'
            WHEN m.ca_eligible = 'Not Eligible' THEN 'ECA'
            WHEN ((IFNULL(m.final_theory,0)+IFNULL(m.final_practical,0))*0.6) < 35 THEN 'ESA'
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
        WHERE m.student_id = s_id;

        -- Cap repeat grades to 'C'
        UPDATE marks m
        JOIN student_course sc ON sc.student_id = m.student_id AND sc.course_id = m.course_id
        SET m.grade = CASE
            WHEN sc.status = 'Repeat' AND m.grade IN ('A+','A','A-','B+','B','B-','C+') THEN 'C'
            ELSE m.grade
        END
        WHERE m.student_id = s_id;

    END LOOP;

    CLOSE student_cursor;
END$$

DELIMITER ;

CALL update_marks_grades();


-- =============================================
-- Procedure 2: Calculate SGPA and CGPA
-- =============================================
DELIMITER $$

DROP PROCEDURE IF EXISTS calculate_final_result$$

CREATE PROCEDURE calculate_final_result()
BEGIN
    -- Clear previous results
    TRUNCATE TABLE result;

    -- Insert results per student
    INSERT INTO result(student_id, academic_year, sgpa, cgpa, total_credits)
    SELECT 
        s.user_id AS student_id,
        MAX(c.academic_year) AS academic_year,

        -- SGPA (latest academic year)
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM marks m2
                JOIN student_course sc2 
                    ON sc2.student_id = m2.student_id 
                   AND sc2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id
                  AND (m2.grade = 'MC' OR sc2.status = 'Suspended')
            ) THEN 'WH'
            ELSE ROUND(
                SUM(
                    c.credit * CASE m.grade
                        WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                        WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                        WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                        WHEN 'D' THEN 1.3 ELSE 0
                    END
                ) / NULLIF(SUM(c.credit), 0),
            2)
        END AS sgpa,

        -- CGPA (all completed courses)
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM marks m2
                JOIN student_course sc2 
                    ON sc2.student_id = m2.student_id 
                   AND sc2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id
                  AND (m2.grade = 'MC' OR sc2.status = 'Suspended')
            ) THEN 'WH'
            ELSE ROUND(
                SUM(
                    c.credit * CASE m.grade
                        WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                        WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                        WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                        WHEN 'D' THEN 1.3 ELSE 0
                    END
                ) / NULLIF(SUM(c.credit), 0),
            2)
        END AS cgpa,

        SUM(c.credit) AS total_credits
    FROM student s
    LEFT JOIN marks m ON m.student_id = s.user_id
    LEFT JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id;

END$$

DELIMITER ;


CALL calculate_final_result();


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




CALL generate_student_academic_report('TG/2023/1704');
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
DELIMITER ;
CALL get_batch_marks_summary_by_course('Database Management Systems');






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
                  AND m.grade IN ('MC','WH')
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
                  AND m.grade IN ('MC','WH')
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


CALL get_progressive_cgpa('U013');



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

CALL get_batch_department_marks('2023');






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


CALL get_student_overall_eligibility();




-- Procedure to create final_student_report view
DELIMITER $$

DROP PROCEDURE IF EXISTS create_final_student_report_view$$

CREATE PROCEDURE create_final_student_report_view()
BEGIN
    DECLARE sql_query TEXT;
    DECLARE course_list TEXT;

    -- Generate dynamic MAX(CASE ...) for each course
    SELECT GROUP_CONCAT(
        CONCAT(
            'MAX(CASE WHEN course_id = ''', course_id, ''' THEN grade END) AS `', course_id, '`'
        )
        ORDER BY course_id
        SEPARATOR ', '
    ) INTO course_list
    FROM (SELECT DISTINCT course_id FROM student_marks_summary) AS courses;

    -- Build the full dynamic CREATE VIEW query
    SET @sql_query = CONCAT(
        'CREATE OR REPLACE VIEW final_student_report AS ',
        'SELECT s.reg_no AS Index_no, u.name AS Student_name, ',
        course_list, ', ',
        'MAX(r.sgpa) AS sgpa, MAX(r.cgpa) AS cgpa ',
        'FROM student_marks_summary m ',
        'JOIN student s ON s.user_id = m.student_id ',
        'JOIN `users` u ON u.user_id = s.user_id ',
        'LEFT JOIN result r ON r.student_id = s.user_id ',
        'GROUP BY s.reg_no, u.name ',
        'ORDER BY s.reg_no'
    );

    -- Prepare and execute the dynamic CREATE VIEW
    PREPARE stmt FROM @sql_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END$$

DELIMITER ;

-- Call the procedure to create the view
CALL create_final_student_report_view();

--After calling, you can just do:
SELECT * FROM final_student_report;




