CREATE OR REPLACE VIEW student_course_marks AS
SELECT *
FROM student_marks_summary
WHERE reg_no = 'STUDENT_REG_NO'    -- replace when querying
  AND course_id = 'COURSE_ID';     -- replace when querying

