
USE UniversityCourseSystem;
GO

-- ========== 1. Create Indexes on Frequently Searched Columns ==========
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Students_Email' AND object_id = OBJECT_ID('Students'))
    CREATE NONCLUSTERED INDEX IX_Students_Email ON Students(Email);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Courses_CourseCode' AND object_id = OBJECT_ID('Courses'))
    CREATE NONCLUSTERED INDEX IX_Courses_CourseCode ON Courses(CourseCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Enrollments_StudentID' AND object_id = OBJECT_ID('Enrollments'))
    CREATE NONCLUSTERED INDEX IX_Enrollments_StudentID ON Enrollments(StudentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Enrollments_OfferingID' AND object_id = OBJECT_ID('Enrollments'))
    CREATE NONCLUSTERED INDEX IX_Enrollments_OfferingID ON Enrollments(OfferingID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Waitlists_OfferingStudent' AND object_id = OBJECT_ID('Waitlists'))
    CREATE NONCLUSTERED INDEX IX_Waitlists_OfferingStudent ON Waitlists(OfferingID, StudentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StudentStatus_StudentID' AND object_id = OBJECT_ID('StudentStatus'))
    CREATE NONCLUSTERED INDEX IX_StudentStatus_StudentID ON StudentStatus(StudentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CourseOfferings_Semester_Year' AND object_id = OBJECT_ID('CourseOfferings'))
    CREATE NONCLUSTERED INDEX IX_CourseOfferings_Semester_Year ON CourseOfferings(Semester, Year);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentTransactions_StudentID' AND object_id = OBJECT_ID('PaymentTransactions'))
    CREATE NONCLUSTERED INDEX IX_PaymentTransactions_StudentID ON PaymentTransactions(StudentID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CoursePrerequisites_CourseID' AND object_id = OBJECT_ID('CoursePrerequisites'))
    CREATE NONCLUSTERED INDEX IX_CoursePrerequisites_CourseID ON CoursePrerequisites(CourseID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Students_ProgramID' AND object_id = OBJECT_ID('Students'))
    CREATE NONCLUSTERED INDEX IX_Students_ProgramID ON Students(ProgramID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CourseOfferings_CourseID' AND object_id = OBJECT_ID('CourseOfferings'))
    CREATE NONCLUSTERED INDEX IX_CourseOfferings_CourseID ON CourseOfferings(CourseID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CourseOfferings_InstructorID' AND object_id = OBJECT_ID('CourseOfferings'))
    CREATE NONCLUSTERED INDEX IX_CourseOfferings_InstructorID ON CourseOfferings(InstructorID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Enrollments_Status' AND object_id = OBJECT_ID('Enrollments'))
    CREATE NONCLUSTERED INDEX IX_Enrollments_Status ON Enrollments(Status);
GO

-- ========== 2. User Roles and Permissions ==========
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StudentRole' AND type = 'R')
    CREATE ROLE StudentRole;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InstructorRole' AND type = 'R')
    CREATE ROLE InstructorRole;
GO



IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'RegistrarRole' AND type = 'R')
    CREATE ROLE RegistrarRole;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminRole' AND type = 'R')
    CREATE ROLE AdminRole;
GO

GRANT SELECT ON Courses TO StudentRole;
GRANT SELECT ON CourseOfferings TO StudentRole;
GRANT SELECT ON Enrollments TO StudentRole;
GRANT SELECT ON Students TO StudentRole;
GRANT SELECT, INSERT ON PaymentTransactions TO StudentRole;
GO

GRANT SELECT ON Courses TO InstructorRole;
GRANT SELECT ON CourseOfferings TO InstructorRole;
GRANT SELECT ON Enrollments TO InstructorRole;
GRANT SELECT ON Students TO InstructorRole;
GRANT UPDATE ON Enrollments (Grade, Status) TO InstructorRole;
GO

GRANT SELECT, INSERT, UPDATE ON Students TO RegistrarRole;
GRANT SELECT, INSERT, UPDATE ON Enrollments TO RegistrarRole;
GRANT SELECT, INSERT, UPDATE ON CourseOfferings TO RegistrarRole;
GRANT SELECT ON Courses TO RegistrarRole;
GRANT SELECT ON Departments TO RegistrarRole;
GRANT SELECT, INSERT, UPDATE ON PaymentTransactions TO RegistrarRole;
GRANT SELECT, INSERT, UPDATE ON StudentStatus TO RegistrarRole;
GRANT SELECT, INSERT ON GPAAuditLog TO RegistrarRole;
GO

GRANT CONTROL ON DATABASE::UniversityCourseSystem TO AdminRole;
GO

DENY SELECT ON Instructors TO StudentRole, InstructorRole, RegistrarRole;
DENY SELECT ON Students (GPA, DateOfBirth, Balance) TO StudentRole, InstructorRole;
REVOKE INSERT, UPDATE, DELETE ON Courses FROM StudentRole;
REVOKE INSERT, UPDATE, DELETE ON CourseOfferings FROM StudentRole;
REVOKE INSERT, UPDATE, DELETE ON Students FROM StudentRole;
REVOKE INSERT, UPDATE, DELETE ON StudentStatus FROM StudentRole;
REVOKE UPDATE ON Students FROM InstructorRole;
REVOKE UPDATE ON StudentStatus FROM InstructorRole;
GO

-- ========== 3. Row-Level Security ==========
IF OBJECT_ID('dbo.UserInstructorMapping', 'U') IS NULL
BEGIN
    CREATE TABLE UserInstructorMapping (
        InstructorID INT NOT NULL FOREIGN KEY REFERENCES Instructors(InstructorID) ON DELETE CASCADE,
        LoginName NVARCHAR(128) NOT NULL,
        PRIMARY KEY (LoginName)
    );
END;
GO

IF OBJECT_ID('dbo.UserStudentMapping', 'U') IS NULL
BEGIN
    CREATE TABLE UserStudentMapping (
        StudentID INT NOT NULL FOREIGN KEY REFERENCES Students(StudentID) ON DELETE CASCADE,
        LoginName NVARCHAR(128) NOT NULL,
        PRIMARY KEY (LoginName)
    );
END;
GO

IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'InstructorsSecurityPolicy')
    DROP SECURITY POLICY InstructorsSecurityPolicy;
GO

IF OBJECT_ID('dbo.fn_SecurityPredicate') IS NOT NULL
    DROP FUNCTION dbo.fn_SecurityPredicate;
GO

CREATE FUNCTION dbo.fn_SecurityPredicate(@InstructorID AS INT)
RETURNS TABLE WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS AccessResult
    WHERE EXISTS (
        SELECT 1 FROM dbo.UserInstructorMapping
        WHERE InstructorID = @InstructorID AND LoginName = SUSER_NAME()
    )
    OR IS_MEMBER('RegistrarRole') = 1
    OR IS_MEMBER('AdminRole') = 1
);
GO

CREATE SECURITY POLICY InstructorsSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicate(InstructorID) ON dbo.Instructors;
GO

IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'StudentsSecurityPolicy')
    DROP SECURITY POLICY StudentsSecurityPolicy;
GO

IF OBJECT_ID('dbo.fn_StudentSecurityPredicate') IS NOT NULL
    DROP FUNCTION dbo.fn_StudentSecurityPredicate;
GO

CREATE FUNCTION dbo.fn_StudentSecurityPredicate(@StudentID AS INT)
RETURNS TABLE WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS AccessResult
    WHERE EXISTS (
        SELECT 1 FROM dbo.UserStudentMapping
        WHERE StudentID = @StudentID AND LoginName = SUSER_NAME()
    )
    OR IS_MEMBER('RegistrarRole') = 1
    OR IS_MEMBER('AdminRole') = 1
);
GO

CREATE SECURITY POLICY StudentsSecurityPolicy
ADD FILTER PREDICATE dbo.fn_StudentSecurityPredicate(StudentID) ON dbo.Students;
GO

-- ========== 4. AuditLog and Sequence ==========
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditLog')
CREATE TABLE AuditLog (
    AuditID INT PRIMARY KEY,
    Action NVARCHAR(100),
    ActionDate DATETIME DEFAULT GETDATE(),
    UserName NVARCHAR(100)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'AuditSequence')
CREATE SEQUENCE AuditSequence
    START WITH 1 INCREMENT BY 1 MINVALUE 1 NO MAXVALUE CACHE 10;
GO

INSERT INTO AuditLog (AuditID, Action, UserName)
SELECT NEXT VALUE FOR AuditSequence, 'security setup', SUSER_NAME()
WHERE NOT EXISTS (SELECT 1 FROM AuditLog WHERE Action = 'security setup');
GO


-- ========== 5. Performance Comparison ==========
IF OBJECT_ID('tempdb..#PerformanceResults') IS NOT NULL
    DROP TABLE #PerformanceResults;
GO

CREATE TABLE #PerformanceResults (
    QueryName NVARCHAR(100),
    ExecutionTimeMS INT,
    IndexStatus NVARCHAR(50)
);
GO

-- Test 1: Search student by email (Without Index)
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Students_Email' AND object_id = OBJECT_ID('Students'))
    DROP INDEX IX_Students_Email ON Students;
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime1 DATETIME2(7) = SYSUTCDATETIME();
SELECT StudentID, FirstName, LastName
FROM Students
WHERE Email = 'john.doe@university.edu';
DECLARE @EndTime1 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('StudentByEmail', DATEDIFF(MILLISECOND, @StartTime1, @EndTime1), 'Without Index');
GO

-- With Index
CREATE NONCLUSTERED INDEX IX_Students_Email ON Students(Email);
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime2 DATETIME2(7) = SYSUTCDATETIME();
SELECT StudentID, FirstName, LastName
FROM Students
WHERE Email = 'john.doe@university.edu';
DECLARE @EndTime2 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('StudentByEmail', DATEDIFF(MILLISECOND, @StartTime2, @EndTime2), 'With Index');
GO

-- Test 2: Course by CourseCode
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Courses_CourseCode' AND object_id = OBJECT_ID('Courses'))
    DROP INDEX IX_Courses_CourseCode ON Courses;
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime3 DATETIME2(7) = SYSUTCDATETIME();
SELECT CourseID, CourseName
FROM Courses
WHERE CourseCode = 'CS101';
DECLARE @EndTime3 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('CourseByCourseCode', DATEDIFF(MILLISECOND, @StartTime3, @EndTime3), 'Without Index');
GO

CREATE NONCLUSTERED INDEX IX_Courses_CourseCode ON Courses(CourseCode);
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime4 DATETIME2(7) = SYSUTCDATETIME();
SELECT CourseID, CourseName
FROM Courses
WHERE CourseCode = 'CS101';
DECLARE @EndTime4 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('CourseByCourseCode', DATEDIFF(MILLISECOND, @StartTime4, @EndTime4), 'With Index');
GO

-- Test 3: Enrollment by StudentID
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Enrollments_StudentID' AND object_id = OBJECT_ID('Enrollments'))
    DROP INDEX IX_Enrollments_StudentID ON Enrollments;
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime5 DATETIME2(7) = SYSUTCDATETIME();
SELECT EnrollmentID, OfferingID, Grade
FROM Enrollments
WHERE StudentID = 1000;
DECLARE @EndTime5 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('EnrollmentByStudentID', DATEDIFF(MILLISECOND, @StartTime5, @EndTime5), 'Without Index');
GO

CREATE NONCLUSTERED INDEX IX_Enrollments_StudentID ON Enrollments(StudentID);
GO

DBCC FREEPROCCACHE;
GO

DECLARE @StartTime6 DATETIME2(7) = SYSUTCDATETIME();
SELECT EnrollmentID, OfferingID, Grade
FROM Enrollments
WHERE StudentID = 1000;



DECLARE @EndTime6 DATETIME2(7) = SYSUTCDATETIME();
INSERT INTO #PerformanceResults (QueryName, ExecutionTimeMS, IndexStatus)
VALUES ('EnrollmentByStudentID', DATEDIFF(MILLISECOND, @StartTime6, @EndTime6), 'With Index');
GO

-- Show Results
SELECT QueryName, ExecutionTimeMS, IndexStatus
FROM #PerformanceResults
ORDER BY QueryName, IndexStatus;
GO

DROP TABLE #PerformanceResults;
GO


