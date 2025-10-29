-- =============================================
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
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM marks m2
                JOIN student_course sc2 ON sc2.student_id = m2.student_id AND sc2.course_id = m2.course_id
                JOIN course c2 ON c2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id 
                  AND (m2.grade='MC' OR sc2.status='Suspended')
            )
            THEN 'WH'
            ELSE ROUND(
                SUM(c.credit * CASE m.grade
                    WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                    WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                    WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                    WHEN 'D' THEN 1.3 ELSE 0 END
                ) / 
                SUM(CASE WHEN m.grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D') THEN c.credit ELSE 0 END)
            ,2)
        END AS sgpa,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM marks m2
                JOIN student_course sc2 ON sc2.student_id = m2.student_id AND sc2.course_id = m2.course_id
                JOIN course c2 ON c2.course_id = m2.course_id
                WHERE m2.student_id = s.user_id 
                  AND (m2.grade='MC' OR sc2.status='Suspended')
            )
            THEN 'WH'
            ELSE ROUND(
                SUM(c.credit * CASE m.grade
                    WHEN 'A+' THEN 4.0 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.7
                    WHEN 'B+' THEN 3.3 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.7
                    WHEN 'C+' THEN 2.3 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.7
                    WHEN 'D' THEN 1.3 ELSE 0 END
                ) / 
                SUM(CASE WHEN m.grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D') THEN c.credit ELSE 0 END)
            ,2)
        END AS cgpa,
        SUM(c.credit) AS total_credits
    FROM student s
    LEFT JOIN marks m ON m.student_id = s.user_id
    LEFT JOIN course c ON c.course_id = m.course_id
    GROUP BY s.user_id;

END$$

DELIMITER ;


-- Final student report view creation procedure
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

-- After calling, you can just do:
-- SELECT * FROM final_student_report;

