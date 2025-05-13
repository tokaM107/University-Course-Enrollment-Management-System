-- Create database
-- CREATE DATABASE UniversityManagementSystem;
-- GO
-- USE UniversityManagementSystem;
-- GO

-- Departments table
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_DepartmentName UNIQUE (DepartmentName)
);

-- Users table (for authentication and authorization)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Student', 'Instructor', 'Admin')),
    LastLogin DATETIME,
    IsActive BIT DEFAULT 1,
    CONSTRAINT UQ_Username UNIQUE (Username),
    CONSTRAINT UQ_Email UNIQUE (Email)
);


-- Students table
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    Level INT NOT NULL,
    creditHours INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    DepartmentID INT NOT NULL,
    EnrollmentDate DATE NOT NULL,
    ExpectedGraduationDate DATE,
    CurrentStatus NVARCHAR(20) DEFAULT 'Active' CHECK (CurrentStatus IN ('Active', 'On Leave', 'Graduated', 'Withdrawn')),
    CONSTRAINT FK_Students_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_Students_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Instructors table
CREATE TABLE Instructors (
    InstructorID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    Address NVARCHAR(200),
    Phone NVARCHAR(20),
    DepartmentID INT NOT NULL,
    HireDate DATE NOT NULL,
    Title NVARCHAR(50) CHECK (Title IN ('Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer')),
    Salary DECIMAL(15,2),
    CONSTRAINT FK_Instructors_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_Instructors_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Courses table
CREATE TABLE Courses (
    CourseID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    DepartmentID INT NOT NULL,
    Credits TINYINT NOT NULL CHECK (Credits > 0 AND Credits <= 3),
    Level TINYINT CHECK (Level BETWEEN 1 AND 4),
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Courses_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

-- CoursePrerequisites table
CREATE TABLE CoursePrerequisites (
    CourseID INT NOT NULL,
    PrerequisiteCourseID INT NOT NULL,
    MinimumGrade CHAR(1) CHECK (MinimumGrade IN ('A', 'B', 'C', 'D')),
    IsMandatory BIT DEFAULT 1,
    PRIMARY KEY (CourseID, PrerequisiteCourseID),
    CONSTRAINT FK_CoursePrerequisites_Course FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    CONSTRAINT FK_CoursePrerequisites_Prerequisite FOREIGN KEY (PrerequisiteCourseID) REFERENCES Courses(CourseID),
    CONSTRAINT CHK_NotSelfPrerequisite CHECK (CourseID <> PrerequisiteCourseID)
);

-- CourseOfferings table
CREATE TABLE CourseOfferings (
    OfferingID INT PRIMARY KEY IDENTITY(1,1),
    CourseID INT NOT NULL,
    InstructorID INT,
    Semester CHAR(5) NOT NULL CHECK (Semester LIKE '[FWS]____'), -- Format: F2023, S2024, W2024
    Year INT NOT NULL,
    Room NVARCHAR(50),
    Schedule NVARCHAR(100), -- e.g., "Mon/Wed 10:00-11:30"
    MaxEnrollment INT,
    CurrentEnrollment INT DEFAULT 0,
    IsCancelled BIT DEFAULT 0,
    CONSTRAINT FK_CourseOfferings_Courses FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    CONSTRAINT FK_CourseOfferings_Instructors FOREIGN KEY (InstructorID) REFERENCES Instructors(InstructorID)
);

-- Enrollments table
CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    OfferingID INT NOT NULL,
    EnrollmentDate DATE NOT NULL DEFAULT GETDATE(),
    Grade CHAR(1) CHECK (Grade IN ('A', 'B', 'C', 'D', 'F', 'I', 'W') OR Grade IS NULL),
    Status NVARCHAR(20) DEFAULT 'Enrolled' CHECK (Status IN ('Enrolled', 'Dropped', 'Completed', 'Withdrawn')),
    CONSTRAINT FK_Enrollments_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Enrollments_CourseOfferings FOREIGN KEY (OfferingID) REFERENCES CourseOfferings(OfferingID),
    CONSTRAINT UQ_StudentOffering UNIQUE (StudentID, OfferingID)
);

-- Indexes for performance
CREATE INDEX IX_Students_DepartmentID ON Students(DepartmentID);
CREATE INDEX IX_Instructors_DepartmentID ON Instructors(DepartmentID);
CREATE INDEX IX_Courses_DepartmentID ON Courses(DepartmentID);
CREATE INDEX IX_CourseOfferings_CourseID ON CourseOfferings(CourseID);
CREATE INDEX IX_CourseOfferings_InstructorID ON CourseOfferings(InstructorID);
CREATE INDEX IX_Enrollments_StudentID ON Enrollments(StudentID);
CREATE INDEX IX_Enrollments_OfferingID ON Enrollments(OfferingID);



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