-- data creation

-- Insert into Departments
INSERT INTO Departments (DepartmentName) VALUES 
('data Science'),
('cyber'),
('media'),
('healthcare'),
('ai');

INSERT INTO Users (Username, PasswordHash, Email, Role, LastLogin, IsActive) VALUES
('admin1', 'hash1', 'admin1@univ.edu', 'Admin', GETDATE(), 1),        -- UserID 1
('prof1', 'hash2', 'prof1@univ.edu', 'Instructor', GETDATE(), 1),     -- UserID 2
('prof2', 'hash3', 'prof2@univ.edu', 'Instructor', GETDATE(), 1),     -- UserID 3
('student1', 'hash4', 'student1@univ.edu', 'Student', GETDATE(), 1),  -- UserID 4
('student2', 'hash5', 'student2@univ.edu', 'Student', GETDATE(), 1),  -- UserID 5
('student3', 'hash6', 'student3@univ.edu', 'Student', GETDATE(), 1),  -- UserID 6
('student4', 'hash7', 'student4@univ.edu', 'Student', GETDATE(), 1),  -- UserID 7
('student5', 'hash8', 'student5@univ.edu', 'Student', GETDATE(), 1),  -- UserID 8
('prof3', 'hash9', 'prof3@univ.edu', 'Instructor', GETDATE(), 1),     -- UserID 9
('prof4', 'hash10', 'prof4@univ.edu', 'Instructor', GETDATE(), 1),    -- UserID 10
('prof5', 'hash11', 'prof5@univ.edu', 'Instructor', GETDATE(), 1);    


-- Insert into Students
INSERT INTO Students (UserID, Level, creditHours, FirstName, LastName, DateOfBirth, Gender, Address, Phone, DepartmentID, EnrollmentDate, ExpectedGraduationDate, CurrentStatus) VALUES
(4, 3, 90, 'Toka', 'Mohamed', '2000-05-15', 'M', 'Alexandria', '000', 1, '2020-09-01', '2024-05-15', 'Active'),
(5, 4, 80, 'Rowan', 'Fayez', '2001-02-20', 'F', 'Alexandria', '000', 2, '2021-09-01', '2025-05-15', 'Active'),
(6, 2, 50, 'Esraa', 'Mostafa', '1999-11-10', 'F', 'Alexandria', '000', 1, '2019-09-01', '2023-05-15', 'Active'),
(7, 3, 70, 'Sarah', 'Sameh', '2000-07-25', 'F', 'Alexandria', '000', 3, '2020-09-01', '2024-05-15', 'On Leave'),
(8, 1, 80, 'Mariam', 'Ahmed', '2001-03-30', 'F', 'Alexandria', '000', 4, '2021-09-01', '2025-05-15', 'Active');

-- Insert into Instructors
INSERT INTO Instructors (UserID, FirstName, LastName, DateOfBirth, Gender, Address, Phone, DepartmentID, HireDate, Title, Salary) VALUES
(2, 'Ahmed', 'Amr', '1975-04-12', 'M', 'Alexandria', '000', 1, '2010-08-15', 'Professor', 85000),
(3, 'Sarah', 'Mohamed', '1980-09-22', 'F', 'Alexandria', '000', 2, '2015-01-10', 'Associate Professor', 75000),
(9, 'Magda', 'Mohamed', '1982-11-05', 'F', 'Alexandria', '000', 1, '2018-03-20', 'Assistant Professor', 65000),
(10, 'Yasser', 'Ahmed', '1978-06-18', 'M', 'Alexandria', '000', 3, '2012-09-01', 'Professor', 90000),
(11, 'Marwan', 'Ahmed', '1985-02-28', 'M', 'Alexandria', '000', 4, '2019-07-15', 'Lecturer', 55000);

-- Insert into Courses
INSERT INTO Courses (Title, Description, DepartmentID, Credits, Level, IsActive) VALUES
('Introduction to Programming', 'Basic programming concepts', 1, 3, 1, 1),
('Calculus I', 'Differential calculus', 2, 3, 1, 1),
('Database Systems', 'Relational database design', 1, 3, 2, 1),
('Data visualization', 'introduction to data analysis', 4, 3, 1, 1),
('System analysis', 'system design', 3, 3, 3, 1);

-- Insert into CoursePrerequisites
INSERT INTO CoursePrerequisites (CourseID, PrerequisiteCourseID, MinimumGrade, IsMandatory) VALUES
(3, 1, 'C', 1),  -- Database Systems requires Intro to Programming
(5, 2, 'C', 0),  -- System analysis recommends Calculus I
(5, 4, 'C', 0),  -- System analysis recommends Data visualization (example)
(4, 2, 'C', 1),  -- Data visualization requires Calculus I (example)
(3, 2, 'C', 1);  -- Database Systems requires Calculus I

-- Insert into CourseOfferings
INSERT INTO CourseOfferings (CourseID, InstructorID, Semester, Year, Room, Schedule, MaxEnrollment, CurrentEnrollment, IsCancelled) VALUES
(1, 1, 'F2023', 2023, 'CS101', 'Mon/Wed 10:00-11:30', 30, 25, 0),
(2, 2, 'F2023', 2023, 'MATH201', 'Tue/Thu 13:00-14:30', 25, 20, 0),
(3, 3, 'S2024', 2024, 'CS301', 'Mon/Wed 14:00-15:30', 20, 18, 0),
(4, 4, 'F2023', 2023, 'DV101', 'Tue/Thu 10:00-11:30', 25, 22, 0),
(5, 5, 'S2024', 2024, 'SYS401', 'Mon/Wed/Fri 09:00-10:00', 15, 12, 0);

-- Insert into Enrollments
INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Grade, Status) VALUES
(1, 1, '2023-08-15', 'A', 'Completed'),
(1, 2, '2023-08-15', 'B', 'Completed'),
(2, 1, '2023-08-16', 'C', 'Completed'),
(2, 3, '2024-01-10', NULL, 'Enrolled'),
(3, 4, '2023-08-17', 'A', 'Completed'),
(3, 5, '2024-01-11', NULL, 'Enrolled'),
(4, 2, '2023-08-18', 'B', 'Completed'),
(4, 4, '2023-08-18', 'A', 'Completed'),
(5, 1, '2023-08-19', 'C', 'Completed'),
(5, 3, '2024-01-12', NULL, 'Enrolled');