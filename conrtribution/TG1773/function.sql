

--give one student marks  CALL get_student_course_marks('U013', 'ICT1222');


DELIMITER $$

CREATE PROCEDURE get_student_course_marks (
    IN p_reg_no VARCHAR(20),
    IN p_course_id VARCHAR(20)
)
BEGIN
    SELECT 
        quiz1_marks + quiz2_marks + quiz3_marks AS `TOTAL QUIZ MARKS`,
        assessment_marks,
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
    WHERE a_d.user_id = p_user_id
      AND a_d.course_id = p_course_id;
END $$


DELIMITER ;


----  one course check final marks and eligibility  CALL get_batch_marks_summary_by_course(''Database Management Systems'');


DELIMITER $$

CREATE PROCEDURE get_batch_overall_eligibility_by_course (
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

    FROM v_student_overall_eligibility soe
    JOIN course c ON c.course_id = soe.course_id
    WHERE c.name = p_course_name
    GROUP BY c.course_id, c.academic_year, c.semester;
END $$

DELIMITER ;
