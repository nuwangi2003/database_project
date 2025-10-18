CREATE OR REPLACE VIEW batch_marks_summary AS
SELECT 
    m.course_id,
    c.name AS course_name,
    COUNT(*) AS total_students,
    SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END) AS ca_eligible_students,
    SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END) AS final_eligible_students,
    ROUND(AVG(m.ca_marks),2) AS avg_ca_marks,
    ROUND(AVG(m.final_marks),2) AS avg_final_marks,
    ROUND((SUM(CASE WHEN m.ca_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS ca_eligible_percentage,
    ROUND((SUM(CASE WHEN m.final_eligible = 'Eligible' THEN 1 ELSE 0 END)/COUNT(*))*100,2) AS final_eligible_percentage
FROM marks m
JOIN course c ON c.course_id = m.course_id
GROUP BY m.course_id;
