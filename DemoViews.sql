use UniversityCourseSystem

UPDATE CourseOfferings
SET Price = CASE OfferingID
    WHEN 4004 THEN 500.00  -- Example for existing OfferingID 4004
    WHEN 4005 THEN 800.00  -- Example for another offering
    WHEN 4006 THEN 900.00  -- Example for another offering
    WHEN 4007 THEN 200.00  -- Example for another offering
    ELSE 500.00  -- Default price if not specified
END
WHERE OfferingID IN (4004, 4005, 4006, 4007);  -- Adjust OfferingIDs as needed


CREATE TABLE Admins (
    AdminID INT PRIMARY KEY,
    AdminName NVARCHAR(50) -- Optional, for reference
);
INSERT INTO Admins (AdminID, AdminName) VALUES (1, 'AdminUser');

--final Procedure 
CREATE OR ALTER PROCEDURE sp_CreateAndEnrollStudent
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @InitialBalance DECIMAL(10, 2),
    @OfferingID INT,
    @Email NVARCHAR(255) = NULL,
    @DateOfBirth DATE = NULL,
    @DepartmentID INT = NULL,
    @ProgramID INT = NULL,
    @StudentID INT = NULL  -- New parameter for existing student enrollment
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewStudentID INT;
        DECLARE @CurrentBalance DECIMAL(10, 2);
        DECLARE @Price DECIMAL(10, 2);

        -- If StudentID is provided, use existing student; otherwise, create new
        IF @StudentID IS NOT NULL
        BEGIN
            SET @NewStudentID = @StudentID;
            SELECT @CurrentBalance = Balance
            FROM Students
            WHERE StudentID = @StudentID;

            IF @CurrentBalance IS NULL
                THROW 50010, 'Student not found or balance unavailable.', 1;
        END
        ELSE
        BEGIN
            -- If no email provided, generate default email
            IF @Email IS NULL
                SET @Email = LOWER(@FirstName + '.' + @LastName + '@example.com');

            PRINT 'Inserting student with InitialBalance: ' + CAST(@InitialBalance AS NVARCHAR(20));
            -- Insert new student
            INSERT INTO Students (
                FirstName, LastName, Balance, Email, DateOfBirth,
                EnrollmentDate, DepartmentID, ProgramID
            )
            VALUES (
                @FirstName, @LastName, @InitialBalance, @Email, @DateOfBirth,
                GETDATE(), @DepartmentID, @ProgramID
            );

            SET @NewStudentID = SCOPE_IDENTITY();
            SET @CurrentBalance = @InitialBalance;
        END

        -- Validate course offering
        SELECT 
            @Price = Price
        FROM CourseOfferings
        WHERE OfferingID = @OfferingID;

        IF @Price IS NULL
            THROW 50002, 'Course price is not set or OfferingID invalid.', 1;

        PRINT 'Balance check: CurrentBalance = ' + CAST(@CurrentBalance AS NVARCHAR(20)) + ', Price = ' + CAST(@Price AS NVARCHAR(20));
        -- Check balance
        IF @CurrentBalance < @Price
        BEGIN
            DECLARE @Msg NVARCHAR(200);
            SET @Msg = 'Insufficient balance. Required: ' + CAST(@Price AS NVARCHAR) + ', Available: ' + CAST(@CurrentBalance AS NVARCHAR);
            THROW 50004, @Msg, 1;
        END

        -- Prevent duplicate enrollment
        IF EXISTS (
            SELECT 1 FROM Enrollments 
            WHERE StudentID = @NewStudentID AND OfferingID = @OfferingID
        )
            THROW 50005, 'Already enrolled in this course.', 1;

        PRINT 'Updating balance: New Balance = ' + CAST(@CurrentBalance - @Price AS NVARCHAR(20));
        -- Update balance
        UPDATE Students
        SET Balance = Balance - @Price
        WHERE StudentID = @NewStudentID;

        IF @@ROWCOUNT = 0
            THROW 50006, 'Balance update failed.', 1;

        -- Insert enrollment
        INSERT INTO Enrollments (
            StudentID, OfferingID, EnrollmentDate, Status
        )
        VALUES (
            @NewStudentID, @OfferingID, GETDATE(), 'Active'
        );

        IF @@ROWCOUNT = 0
            THROW 50007, 'Enrollment insert failed.', 1;

        -- Update course offering enrollment
        UPDATE CourseOfferings
        SET CurrentEnrollment = CurrentEnrollment + 1
        WHERE OfferingID = @OfferingID;

        IF @@ROWCOUNT = 0
            THROW 50008, 'Course enrollment update failed.', 1;

        -- Commit transaction
        COMMIT;

        -- Return final success output
        SELECT 
            'Student created and enrolled successfully' AS Message,
            @NewStudentID AS StudentID,
            @OfferingID AS EnrolledOfferingID,
            (SELECT Balance FROM Students WHERE StudentID = @NewStudentID) AS RemainingBalance,
            (SELECT CurrentEnrollment FROM CourseOfferings WHERE OfferingID = @OfferingID) AS UpdatedEnrollment;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error occurred: ' + @Err;
        THROW 50009, @Err, 1;
    END CATCH
END;
GO

EXEC sp_help 'Enrollments';
ALTER TABLE Enrollments
DROP CONSTRAINT CHK_Grade;

ALTER TABLE Enrollments
DROP COLUMN Grade;

  --final inshallah view
CREATE OR ALTER VIEW vw_StudentProgress
AS
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    COUNT(e.EnrollmentID) AS TotalCourses
FROM Students s
LEFT JOIN Enrollments e ON s.StudentID = e.StudentID
GROUP BY s.StudentID, s.FirstName, s.LastName;
GO



CREATE VIEW vw_RealTimeEnrollments AS
SELECT 
    s.StudentID, s.FirstName, s.LastName, s.Balance,
    co.OfferingID, co.CourseID, co.Price, co.CurrentEnrollment,
    e.EnrollmentID, e.EnrollmentDate
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
JOIN CourseOfferings co ON e.OfferingID = co.OfferingID;

SELECT * FROM Enrollments WHERE StudentID = 1066;
SELECT CurrentEnrollment FROM CourseOfferings WHERE OfferingID = 4003;
