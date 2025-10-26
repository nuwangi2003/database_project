
# 🎓University Academic Management System

A comprehensive MySQL-based database system designed to manage university academic and administrative operations, including user roles, departments, students, lecturers, courses, attendance, marks, medicals, and results. The system ensures data consistency, referential integrity, and 3NF normalization, providing a robust foundation for backend development, analytics, and university automation.

## 📖 Project Overview

This database manages key university processes, supporting:

- **User Role Management**: Admin, Dean, Lecturer, Technical Officer, Student
- **Department, Course, and Enrollment Management**: Organize academic structure
- **Continuous Assessment (CA) and Final Mark Calculations**: Automated grading logic
- **Medical Handling**: Manages medical submissions for exams and attendance
- **Attendance Tracking**: Monitors eligibility based on attendance
- **Result, GPA, and CGPA Computation**: Tracks academic performance
- **Clean Entity Relationships**: Uses cascading foreign keys for integrity

## 🗃️ Database Schema

**Database Name**: `db_project`

### 📑 Main Tables

| Table                | Description                                                                 |
|----------------------|-----------------------------------------------------------------------------|
| `users`              | Stores all system users with roles (Admin, Dean, Lecturer, Tech Officer, Student) |
| `department`         | Faculty departments and their names                                         |
| `student`            | Student details, registration number, status, and linked department         |
| `lecture`            | Lecturer details including specialization and designation                   |
| `dean`               | Dean information (linked to a lecturer) with term duration                  |
| `tech_officer`       | Technical officers linked to the users table                                |
| `course`             | Course information including credits, semester, and hours                   |
| `session`            | Defines theory and practical sessions for each course                       |
| `attendance`         | Tracks attendance per session, supports medical-based absences              |
| `marks`              | Stores quiz, assessment, mid, and final marks with eligibility and grades   |
| `medical`            | Handles medical submissions for CA, Mid, Final, and Attendance              |
| `result`             | Records GPA, SGPA, and CGPA with total credits per semester/year            |
| `student_course`     | Many-to-many relationship between students and courses                      |
| `lecture_course`     | Many-to-many relationship between lecturers and courses                     |
| `lecture_department` | Many-to-many relationship between lecturers and departments                 |
| `department_course`  | Many-to-many relationship between departments and courses                   |

### 🔗 Relationship Summary

- **1:1 Relationships**:
  - `users` → `student`, `lecture`, `tech_officer`
  - `lecture` → `dean`
- **Many-to-Many Relationships** (via junction tables):
  - `student` ↔ `course` (via `student_course`)
  - `lecture` ↔ `course` (via `lecture_course`)
  - `department` ↔ `course` (via `department_course`)
  - `lecture` ↔ `department` (via `lecture_department`)
- **One-to-Many Relationships**:
  - `student` ↔ `attendance`
  - `student` ↔ `marks`

## ⚙️ Mark Calculation Logic

### Continuous Assessment (CA) (40% of total)
- **Best two quizzes**: Average of top 2 quiz marks × 0.1
- **Assessment marks**: (0–100) × 0.15
- **Mid exam**: (0–100) × 0.15
- **Total CA weight**: Scaled to 40 marks

### Final Exam (60% of total)
- **Final Theory + Practical**: (Average) × 0.6
- **Total Final weight**: Scaled to 60 marks

### Total Marks
- **Formula**: `(CA × 0.4) + (Final × 0.6)`

### Eligibility & Grade Rules
- **CA < 20**: Fails CA (ECA status)
- **Final < 30**: Fails Final (ESA status)
- **Both passed**: Grade calculated normally
- **Medical approved**: Student can repeat and earn full marks
- **Absent without medical**: Can repeat, but maximum grade is C

### 🧮 Example Calculation

| Component              | Marks                 | Weighted                     |
|-----------------------|-----------------------|------------------------------|
| Best 2 Quizzes        | (80, 70) → 75        | 75 × 0.1 = 7.5               |
| Assessment            | 85                   | 85 × 0.15 = 12.75             |
| Mid Exam              | 80                   | 80 × 0.15 = 12               |
| **CA Total (out of 40)** | —                   | 32                           |
| Final Theory + Practical | (0 + 60) = 55   | 55 × 0.6 = 33                |
| **Final Total (out of 60)** | —                | 33                           |
| **Total Marks**        | **CA + Final = 65** | **Grade = B+**            |
#### in that case that subeject is either practicum or theory that's why one part become 0
#### if there is both then maximum marks theory and practical should be 50 then can get accurate answer
## 🧰 How to Use

### Step 1: Create Database
```sql
CREATE DATABASE IF NOT EXISTS db_project;
USE db_project;
```

### Step 2: Create Tables
Run the provided SQL script containing all `CREATE TABLE` statements to set up the schema.

### Step 3: Insert Sample Data
Populate the database with sample data for users, students, courses, and marks. Example:

```sql
-- Insert a User and Student
INSERT INTO users VALUES ('U001', 'John Doe', 'john@uni.com', 'pass123', 'Student');
INSERT INTO student VALUES ('U001', 'R001', '2025ICT01', 'D001');

-- Add a Course
INSERT INTO course VALUES ('C001', 'Database Systems', 3, 2, '2', 60.00, 3.00);

-- Enroll a Student
INSERT INTO student_course VALUES ('U001', 'C001','Proper');

-- Record Attendance
INSERT INTO attendance (student_id, session_id, status) VALUES ('U001', 1, 'Present');

-- Add Marks
INSERT INTO marks (
    student_id, course_id, quiz1_marks, quiz2_marks, quiz3_marks,
    assessment_marks, mid_marks, final_theory, final_practical
) VALUES (
    'U001', 'C001', 80, 70, 90, 85, 75, 32, 40
);
```

## 📚 EER Model Summary
- Normalized to **Third Normal Form (3NF)**
- Uses **Primary & Foreign Keys** for relationships
- Implements **ENUM, BOOLEAN, and CHECK constraints** for data integrity
- Supports **cascading updates/deletes** for referential integrity
- Handles complex **many-to-many mappings**

## 🧠 Learning Outcomes
By building this project, you will learn:
- Advanced database design and normalization
- Entity-Relationship (ER) modeling and diagram creation
- Using FOREIGN KEY and ENUM constraints
- Designing academic systems with real-world logic
- Handling medical, eligibility, and grading workflows
- SQL query optimization and data integrity principles

## 🧩 Technologies Used
- **Database**: MySQL
- **Tools**: MySQL Workbench, phpMyAdmin, draw.io
- **Language**: MYYSQL

## 🚀 Getting Started
1. Clone or download the project repository.
2. Set up a MySQL server and create the database using the provided script.
3. Run the `CREATE TABLE` statements to build the schema.
4. Insert sample data to test functionality.
5. Use MySQL Workbench or dbdiagram.io to visualize the EER diagram.
6. Run example queries to explore the system’s capabilities.

## 📝 Notes
- Ensure MySQL server is running and accessible.
- The database is designed for scalability and can be extended with additional features like reporting or user authentication.





