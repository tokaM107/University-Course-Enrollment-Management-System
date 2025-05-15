-- Sample Data
INSERT INTO Departments (DepartmentName, Building, Budget) VALUES
('Computer Science', 'Engineering', 1000000.00),
('Mathematics', 'Science', 750000.00),
('Physics', 'Science', 800000.00),
('English', 'Humanities', 500000.00);
GO

INSERT INTO AcademicPrograms (ProgramName, DepartmentID, TotalCredits) VALUES
('BS Computer Science', 1, 120),
('BA Mathematics', 2, 120),
('BS Physics', 3, 124),
('BA English', 4, 120);
GO

INSERT INTO Students (FirstName, LastName, Email, DateOfBirth, EnrollmentDate, DepartmentID, ProgramID, GPA, Balance) VALUES
('John', 'Doe', 'john.doe@university.edu', '2000-05-15', '2023-09-01', 1, 1, 3.75, 1500.00),
('Jane', 'Smith', 'jane.smith@university.edu', '1999-08-22', '2023-09-01', 2, 2, 3.90, 0.00),
('Michael', 'Johnson', 'michael.j@university.edu', '2001-02-10', '2024-01-15', 1, 1, 3.45, 2000.00),
('Emily', 'Davis', 'emily.davis@university.edu', '2000-11-30', '2023-09-01', 3, 3, NULL, 500.00),
('Alex', 'Brown', 'alex.brown@university.edu', '2002-03-05', '2024-01-15', 4, 4, 3.20, 0.00);
GO

INSERT INTO StudentStatus (StudentID, Status, StartDate) VALUES
(1000, 'Active', '2023-09-01'),
(1001, 'Honors', '2023-09-01'),
(1002, 'Active', '2024-01-15'),
(1003, 'Active', '2023-09-01'),
(1004, 'Active', '2024-01-15');
GO

INSERT INTO Instructors (FirstName, LastName, Email, DepartmentID, HireDate, Salary) VALUES
('Robert', 'Wilson', 'r.wilson@university.edu', 1, '2010-07-15', 85000.00),
('Sarah', 'Williams', 's.williams@university.edu', 2, '2015-03-10', 75000.00),
('David', 'Lee', 'david.lee@university.edu', 3, '2018-09-01', 78000.00),
('Laura', 'Clark', 'laura.clark@university.edu', 4, '2012-01-20', 72000.00);
GO

INSERT INTO Courses (CourseCode, CourseName, Credits, DepartmentID, Description) VALUES
('CS101', 'Introduction to Programming', 4, 1, 'Basic programming concepts using Python'),
('MATH201', 'Calculus II', 3, 2, 'Advanced calculus topics including integration'),
('PHYS101', 'Mechanics', 4, 3, 'Fundamentals of classical mechanics'),
('ENG201', 'British Literature', 3, 4, 'Study of British literary works'),
('CS202', 'Data Structures', 4, 1, 'Advanced data structures and algorithms');
GO

INSERT INTO CoursePrerequisites (CourseID, PrerequisiteCourseID) VALUES
(3004, 3000); -- CS202 requires CS101
GO

INSERT INTO Classrooms (Building, RoomNumber, Capacity) VALUES
('Engineering', 'ENG-101', 30),
('Science', 'SCI-205', 25),
('Science', 'SCI-101', 20),
('Humanities', 'HUM-301', 35),
('Engineering', 'ENG-102', 30);
GO

INSERT INTO CourseOfferings (CourseID, InstructorID, ClassroomID, Semester, Year, Schedule, MaxCapacity, CurrentEnrollment) VALUES
(3000, 2000, 1, 'Fall', 2023, 'MWF 10:00-11:00', 30, 3),
(3001, 2001, 2, 'Fall', 2023, 'TTh 13:00-14:30', 25, 2),
(3002, 2002, 3, 'Spring', 2024, 'MWF 09:00-10:00', 20, 0),
(3003, 2003, 4, 'Fall', 2023, 'TTh 11:00-12:30', 35, 1),
(3004, 2000, 5, 'Spring', 2024, 'MWF 11:00-12:00', 30, 0);
GO

INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate, Grade, Status) VALUES
(1000, 4000, '2023-09-10', 3.80, 'Completed'),
(1001, 4001, '2023-09-10', 4.00, 'Completed'),
(1001, 4002, '2023-09-10', NULL, 'Active'),
(1002, 4000, '2023-09-10', 3.50, 'Completed'),
(1003, 4003, '2023-09-10', NULL, 'Active'),
(1004, 4001, '2023-09-10', 3.20, 'Completed');
GO

INSERT INTO PaymentTransactions (StudentID, Amount, TransactionDate, Status) VALUES
(1000, 1000.00, '2023-09-15', 'Completed'),
(1000, 500.00, '2023-10-01', 'Pending'),
(1001, 1200.00, '2023-09-20', 'Completed'),
(1002, 800.00, '2024-01-20', 'Completed'),
(1003, 300.00, '2023-09-25', 'Pending');
GO

INSERT INTO GPAAuditLog (StudentID, OldGPA, NewGPA, ChangeDate, ChangedBy) VALUES
(1000, NULL, 3.75, '2023-09-15', 'Registrar'),
(1001, NULL, 3.90, '2023-09-15', 'Registrar'),
(1002, NULL, 3.45, '2024-01-20', 'Registrar'),
(1004, NULL, 3.20, '2024-01-20', 'Registrar');
GO

INSERT INTO TuitionRates (AcademicYear, PerCreditRate, FlatRate, EffectiveDate) VALUES
(2023, 500.00, 15000.00, '2023-07-01'),
(2024, 525.00, 15750.00, '2024-07-01');
GO

INSERT INTO AuditLog (AuditID, Action, UserName)
VALUES (NEXT VALUE FOR AuditSequence, 'Database initialized', SUSER_NAME());
GO

INSERT INTO UserStudentMapping (LoginName, StudentID) VALUES
('StudentUser1000', 1000),
('StudentUser1001', 1001),
('StudentUser1002', 1002),
('StudentUser1003', 1003),
('StudentUser1004', 1004);
GO

INSERT INTO UserInstructorMapping (LoginName, InstructorID) VALUES
('InstructorUser2000', 2000),
('InstructorUser2001', 2001),
('InstructorUser2002', 2002),
('InstructorUser2003', 2003);
GO

