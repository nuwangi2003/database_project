# 🎓 University Management Database Project

This project is a University Management System database designed using **MySQL**. It models real-world university entities such as students, lecturers, courses, marks, attendance, and results. The goal is to manage university academic and administrative data efficiently with proper relationships, constraints, and normalization.

---

## 🏗️ Project Overview

This database schema models the essential roles and activities within a university. It supports:

- **User role management** (students, lecturers, technical officers, deans)
- **Course and enrollment management**
- **Attendance and marks tracking**
- **Results and GPA calculations**
- **Handling multi-valued staff attributes** (e.g., multiple phone numbers)

---

## 🗃️ Database Schema

### **Database Name**
`db_project`

### **Main Tables and Descriptions**

| Table                    | Description                                                            |
|--------------------------|------------------------------------------------------------------------|
| `users`                  | Basic user details and department info                                 |
| `student`                | Student-specific info (registration number, status)                    |
| `lecture`                | Lecturer info with specialization                                      |
| `dean`                   | A lecturer appointed as a dean for a specific term                     |
| `tech_officer`           | Technical officers linked to users                                     |
| `tech_office_phone_no`   | Multiple phone numbers for each technical officer                      |
| `course`                 | Course details (name, credit)                                          |
| `marks`                  | Quiz and final exam marks                                              |
| `course_marks`           | Links marks with specific courses                                      |
| `student_marks`          | Links students with marks and grades                                   |
| `attendance`             | Attendance records per course per student                              |
| `result`                 | GPA and SGPA for each student                                          |
| `student_course`         | Many-to-many relationship between students and courses                 |

---

## 🔗 Relationships Summary

| Relationship                                   | Type | Description                                            |
|-------------------------------------------------|------|--------------------------------------------------------|
| users → student, lecture, tech_officer          | 1:1  | Each user can be a specific type                       |
| lecture → dean                                  | 1:1  | A lecturer can be a dean                               |
| users ↔ course (via student_course)             | M:N  | Students can take many courses                         |
| users ↔ course (via attendance)                 | M:N  | Tracks attendance per course                           |
| course ↔ marks (via course_marks)               | M:N  | Each course can have multiple marks entries            |
| student ↔ marks (via student_marks)             | M:N  | Students have marks for each course                    |
| tech_officer ↔ tech_office_phone_no             | 1:M  | One officer can have multiple phone numbers            |

---

## ⚙️ How to Use

### **Step 1: Create Database**

```sql
CREATE DATABASE db_project;
USE db_project;
```

### **Step 2: Create Tables**

Copy and run the provided SQL script with all `CREATE TABLE` statements in MySQL Workbench or your terminal.

### **Step 3: Verify Tables**

```sql
SHOW TABLES;
```

### **Step 4: Visualize Relationships**

- **MySQL Workbench** (EER Diagram Tool)
- **draw.io** or **dbdiagram.io**

---

## 📊 Example Queries

**Insert a Student:**
```sql
INSERT INTO users VALUES ('U001', 'student@mail.com', 'pass123', 'ICT');
INSERT INTO student VALUES ('U001', 'R001', 'Active');
```

**Assign a Course:**
```sql
INSERT INTO course VALUES ('C001', 'Database Systems', 3);
INSERT INTO student_course VALUES ('U001', 'C001');
```

**Record Attendance:**
```sql
INSERT INTO attendance VALUES (1, 'U001', 'C001', '2025-10-13', 'Present', FALSE);
```

**Add Marks:**
```sql
INSERT INTO marks (quiz1_marks, final_theory, final_practical, final_marks)
VALUES (15.5, 45.0, 40.0, 100.0);
```

---

## 📚 EER Model Summary

- **Normalized to 3NF**
- **Proper foreign key usage** for referential integrity
- **Many-to-many relationships** handled via bridge tables
- **ENUM and BOOLEAN types** for logical constraints
- **Multi-valued attributes** managed with separate relation (phone numbers)

---

## 🧠 Learning Outcomes

By working with this project, you will learn:

- Database design and normalization
- Use of primary and foreign keys
- One-to-one, one-to-many, and many-to-many relationships
- Handling multi-valued attributes in relational models
- SQL schema creation and constraint management

---

## 🧩 Technologies Used

- **Database:** MySQL
- **Recommended Tools:** MySQL Workbench, phpMyAdmin
- **Query Language:** SQL

---

## 📄 License

This project is open-source and free to use for educational purposes.

---
