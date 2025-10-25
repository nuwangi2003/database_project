-- Batch-wise attendance summary for a specific course
SELECT 
    ad.reg_no,
    ad.course_id,
    ad.course_name,
    ad.academic_year,
    ad.semester,
    ad.session_type,
    ad.session_dates,
    ad.attendance_percentage,
    ad.eligibility
FROM attendance_detailed ad
WHERE ad.course_id = 'ICT1222'   
ORDER BY ad.reg_no;

-- Attendance summary for all subjects in a given semester/batch
SELECT
    ac.reg_no,
    ac.course_id,
    ac.course_name,
    ac.academic_year,
    ac.semester,
    ac.attendance_percentage,
    ac.eligibility
FROM attendance_combined ac
WHERE ac.academic_year = '2025'   
  AND ac.semester = '1'           
ORDER BY ac.reg_no, ac.course_id;



-- Individual student summary across all courses
SELECT
    sas.reg_no,
    sas.course_id,
    sas.course_name,
    sas.academic_year,
    sas.semester,
    sas.attendance_percentage,
    sas.medical_percentage,
    sas.eligibility
FROM student_attendance_summary sas
WHERE sas.reg_no = 'TG/2023/1701'  
ORDER BY sas.course_id;


-- Individual student's attendance details for one course
SELECT
    sad.reg_no,
    sad.course_id,
    sad.course_name,
    sad.session_date,
    sad.session_type,
    sad.attendance_status
FROM student_attendance_details sad
WHERE sad.reg_no = 'U013'       
  AND sad.course_id = 'ICT1222'  
ORDER BY sad.session_date;




--Check theory only, practical only, or combined attendance
--Theory only
SELECT 
    ad.reg_no,
    ad.course_id,
    ad.course_name,
    ad.session_type,
    ad.attendance_percentage,
    ad.eligibility
FROM attendance_detailed ad
WHERE ad.course_id = 'ICT1222'
  AND ad.session_type = 'Theory'
ORDER BY ad.reg_no;

-- Practical only
SELECT 
    ad.reg_no,
    ad.course_id,
    ad.course_name,
    ad.session_type,
    ad.attendance_percentage,
    ad.eligibility
FROM attendance_detailed ad
WHERE ad.course_id = 'ICT1222'
  AND ad.session_type = 'Practical'
ORDER BY ad.reg_no;

-- Combined theory + practical
SELECT 
    ac.reg_no,
    ac.course_id,
    ac.course_name,
    ac.attendance_percentage,
    ac.eligibility
FROM attendance_combined ac
WHERE ac.course_id = 'ICT1222'
ORDER BY ac.reg_no;


