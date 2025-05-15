-- Database Creation
CREATE DATABASE UniversityCourseSystem;
GO

USE UniversityCourseSystem;
GO

-- Table Creation
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL,
    Building NVARCHAR(50),
    Budget DECIMAL(18,2)
);

CREATE TABLE AcademicPrograms (
    ProgramID INT PRIMARY KEY IDENTITY(1,1),
    ProgramName NVARCHAR(100) NOT NULL,
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE SET NULL,
    TotalCredits INT NOT NULL CHECK (TotalCredits > 0)
);

CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1000,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    DateOfBirth DATE,
    EnrollmentDate DATE DEFAULT GETDATE(),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE SET NULL,
    ProgramID INT FOREIGN KEY REFERENCES AcademicPrograms(ProgramID) ON DELETE SET NULL,
    GPA DECIMAL(3,2),
    Balance DECIMAL(10,2) DEFAULT 0 CHECK (Balance >= 0),
    LoginName AS 'StudentUser' + CAST(StudentID AS NVARCHAR),
    CONSTRAINT CHK_GPA CHECK (GPA <= 4.00)
);

CREATE TABLE StudentStatus (
    StatusID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE,
    Status NVARCHAR(50) NOT NULL CHECK (Status IN ('Active', 'Probation', 'Graduated', 'Suspended', 'Honors')),
    StartDate DATE NOT NULL,
    EndDate DATE
);

CREATE TABLE Instructors (
    InstructorID INT PRIMARY KEY IDENTITY(2000,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE SET NULL,
    HireDate DATE,
    Salary DECIMAL(18,2)
);

CREATE TABLE Courses (
    CourseID INT PRIMARY KEY IDENTITY(3000,1),
    CourseCode NVARCHAR(20) UNIQUE NOT NULL,
    CourseName NVARCHAR(100) NOT NULL,
    Credits INT NOT NULL CHECK (Credits > 0),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID) ON DELETE SET NULL,
    Description NVARCHAR(500)
);

CREATE TABLE CoursePrerequisites (
    PrerequisiteID INT PRIMARY KEY IDENTITY(1,1),
    CourseID INT FOREIGN KEY REFERENCES Courses(CourseID) ON DELETE CASCADE,
    PrerequisiteCourseID INT FOREIGN KEY REFERENCES Courses(CourseID), 
    CONSTRAINT CHK_DifferentCourses CHECK (CourseID != PrerequisiteCourseID)
);


CREATE TABLE Classrooms (
    ClassroomID INT PRIMARY KEY IDENTITY(1,1),
    Building NVARCHAR(50),
    RoomNumber NVARCHAR(20),
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

CREATE TABLE CourseOfferings (
    OfferingID INT PRIMARY KEY IDENTITY(4000,1),
    CourseID INT FOREIGN KEY REFERENCES Courses(CourseID) ON DELETE CASCADE,
    InstructorID INT FOREIGN KEY REFERENCES Instructors(InstructorID) ON DELETE SET NULL,
    ClassroomID INT FOREIGN KEY REFERENCES Classrooms(ClassroomID) ON DELETE SET NULL,
    Semester NVARCHAR(20) NOT NULL CHECK (Semester IN ('Fall', 'Spring', 'Summer')),
    Year INT NOT NULL CHECK (Year >= 2000),
    Schedule NVARCHAR(100),
    MaxCapacity INT CHECK (MaxCapacity > 0),
    CurrentEnrollment INT DEFAULT 0 CHECK (CurrentEnrollment >= 0),
    
);

CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY IDENTITY(5000,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE,
    OfferingID INT FOREIGN KEY REFERENCES CourseOfferings(OfferingID) ON DELETE CASCADE,
    EnrollmentDate DATE DEFAULT GETDATE(),
    Grade DECIMAL(3,2),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Completed', 'Dropped')),
    CONSTRAINT UC_Enrollment UNIQUE (StudentID, OfferingID),
    CONSTRAINT CHK_Grade CHECK (Grade <= 4.00)
);

CREATE TABLE Waitlists (
    WaitlistID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE,
    OfferingID INT FOREIGN KEY REFERENCES CourseOfferings(OfferingID) ON DELETE CASCADE,
    WaitlistDate DATETIME DEFAULT GETDATE(),
    Position INT NOT NULL CHECK (Position > 0)
);

CREATE TABLE StudentNameChangeLog (
    LogID INT PRIMARY KEY IDENTITY(6000,1),
    StudentID INT NOT NULL,
    OldFirstName NVARCHAR(50),
    OldLastName NVARCHAR(50),
    NewFirstName NVARCHAR(50),
    NewLastName NVARCHAR(50),
    ChangeDate DATETIME DEFAULT GETDATE(),
    ChangedBy NVARCHAR(100)
);

CREATE TABLE PaymentTransactions (
    TransactionID INT PRIMARY KEY IDENTITY(7000,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE,
    Amount DECIMAL(10,2) CHECK (Amount > 0),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Completed', 'Failed'))
);

CREATE TABLE PaymentAuditLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TransactionID INT FOREIGN KEY REFERENCES PaymentTransactions(TransactionID) ON DELETE CASCADE,
    OldStatus NVARCHAR(20),
    NewStatus NVARCHAR(20),
    ChangeDate DATETIME DEFAULT GETDATE(),
    ChangedBy NVARCHAR(100)
);

CREATE TABLE EnrollmentAuditLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    EnrollmentID INT FOREIGN KEY REFERENCES Enrollments(EnrollmentID) ON DELETE CASCADE,
    CourseCode NVARCHAR(20),
    OldStatus NVARCHAR(20),
    NewStatus NVARCHAR(20),
    ChangeDate DATETIME DEFAULT GETDATE(),
    ChangedBy NVARCHAR(100)
);

CREATE TABLE GPAAuditLog (
    LogID INT PRIMARY KEY IDENTITY(8000,1),
    StudentID INT,
    OldGPA DECIMAL(3,2),
    NewGPA DECIMAL(3,2),
    ChangeDate DATETIME DEFAULT GETDATE(),
    ChangedBy NVARCHAR(100)
);

CREATE TABLE TuitionRates (
    RateID INT PRIMARY KEY IDENTITY(1,1),
    AcademicYear INT NOT NULL,
    PerCreditRate DECIMAL(10,2) NOT NULL,
    FlatRate DECIMAL(10,2),
    EffectiveDate DATE NOT NULL
);

CREATE TABLE AuditLog (
    AuditID INT PRIMARY KEY,
    Action NVARCHAR(100),
    ActionDate DATETIME DEFAULT GETDATE(),
    UserName NVARCHAR(100)
);

CREATE TABLE AuditLogArchive (
    AuditID INT PRIMARY KEY,
    Action NVARCHAR(100),
    ActionDate DATETIME,
    UserName NVARCHAR(100)
);

CREATE TABLE SecurityAuditLog (
    SecurityLogID INT PRIMARY KEY IDENTITY(1,1),
    Action NVARCHAR(100),
    ActionDate DATETIME DEFAULT GETDATE(),
    UserName NVARCHAR(100),
    AffectedRole NVARCHAR(128)
);

CREATE TABLE UserStudentMapping (
    LoginName NVARCHAR(128) PRIMARY KEY,

    StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE
);

CREATE TABLE UserInstructorMapping (
    LoginName NVARCHAR(128) PRIMARY KEY,
    InstructorID INT NOT NULL FOREIGN KEY REFERENCES Instructors(InstructorID) ON DELETE CASCADE
);
GO

IF OBJECT_ID('AuditSequence', 'SO') IS NOT NULL
    DROP SEQUENCE AuditSequence;
GO

CREATE SEQUENCE AuditSequence
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO MAXVALUE
    CACHE 10;
GO

