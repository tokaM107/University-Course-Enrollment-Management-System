---------- 1)Function to get course name by course ID ----------

CREATE FUNCTION dbo.GetCourseNameByID (@CourseID INT)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @Title NVARCHAR(100);
    
    SELECT @Title = Title 
    FROM Courses 
    WHERE CourseID = @CourseID;
    
    RETURN ISNULL(@Title, 'Course not found');
END;
GO

-- Example usage:
SELECT dbo.GetCourseNameByID(3) AS Course;
GO


---------- 2)Stored procedure to enroll a student in a course ----------

CREATE PROCEDURE dbo.EnrollStudentInCourse
    @StudentID INT,
    @OfferingID INT,
    @EnrollmentDate DATE = NULL,
    @ResultMessage NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate student exists
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            SET @ResultMessage = 'Error: Student not found';
            RETURN -1;
        END
        
        -- Validate course offering exists
        IF NOT EXISTS (SELECT 1 FROM CourseOfferings WHERE OfferingID = @OfferingID)
        BEGIN
            SET @ResultMessage = 'Error: Course offering not found';
            RETURN -2;
        END
        
        -- Check if already enrolled
        IF EXISTS (SELECT 1 FROM Enrollments WHERE StudentID = @StudentID AND OfferingID = @OfferingID)
        BEGIN
            SET @ResultMessage = 'Error: Student already enrolled in this course';
            RETURN -3;
        END
        
        -- Check capacity
        DECLARE @CurrentEnrollment INT, @MaxEnrollment INT;
        
        SELECT @CurrentEnrollment = COUNT(*) 
        FROM Enrollments 
        WHERE OfferingID = @OfferingID;
        
        SELECT @MaxEnrollment = MaxEnrollment 
        FROM CourseOfferings 
        WHERE OfferingID = @OfferingID;
        
        IF @CurrentEnrollment >= @MaxEnrollment
        BEGIN
            SET @ResultMessage = 'Error: Course is at maximum capacity';
            RETURN -4;
        END
        
        -- Check prerequisites
        DECLARE @CourseID INT;
        SELECT @CourseID = CourseID FROM CourseOfferings WHERE OfferingID = @OfferingID;
        
        IF EXISTS (
            SELECT 1 FROM CoursePrerequisites p
            WHERE p.CourseID = @CourseID
            AND NOT EXISTS (
                SELECT 1 FROM Enrollments e
                JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
                WHERE e.StudentID = @StudentID
                AND co.CourseID = p.CourseID
                AND (p.MinimumGrade IS NULL OR e.Grade >= p.MinimumGrade)
            )
        )
        BEGIN
            SET @ResultMessage = 'Error: Student does not meet prerequisites for this course';
            RETURN -5;
        END
        
        -- Set default enrollment date
        IF @EnrollmentDate IS NULL
            SET @EnrollmentDate = GETDATE();
        
        -- Enroll the student
        INSERT INTO Enrollments (StudentID, OfferingID, EnrollmentDate)
        VALUES (@StudentID, @OfferingID, @EnrollmentDate);
        
        SET @ResultMessage = 'Student successfully enrolled in the course';
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @ResultMessage = 'Error: ' + ERROR_MESSAGE();
        RETURN -99;
    END CATCH
END;
GO

-- Example usage:
DECLARE @ResultMessage NVARCHAR(200);
DECLARE @ReturnCode INT;
EXEC @ReturnCode = dbo.EnrollStudentInCourse 
     @StudentID = 4, 
     @OfferingID = 1, 
     @ResultMessage = @ResultMessage OUTPUT;
 SELECT @ReturnCode AS ReturnCode, @ResultMessage AS ResultMessage;
 SELECT * From Enrollments;
GO


---------- 3)Trigger to log student name changes ----------

CREATE TRIGGER trg_StudentNameChange
ON Students
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only log if first or last name changed
    IF UPDATE(FirstName) OR UPDATE(LastName)
    BEGIN
        INSERT INTO StudentNameChangeLog (
            StudentID, 
            OldFirstName, 
            OldLastName, 
            NewFirstName, 
            NewLastName
        )
        SELECT 
            i.StudentID,
            d.FirstName AS OldFirstName,
            d.LastName AS OldLastName,
            i.FirstName AS NewFirstName,
            i.LastName AS NewLastName
        FROM inserted i
        JOIN deleted d ON i.StudentID = d.StudentID
        WHERE i.FirstName <> d.FirstName OR i.LastName <> d.LastName;
    END
END;
GO


-- Example usage:
UPDATE Students SET LastName = 'Ahmed' WHERE StudentID = 4;
SELECT * FROM StudentNameChangeLog;
GO

---------- 4)Instead of trigger to prevent deletion of required courses ----------

CREATE TRIGGER trg_PreventRequiredCourseDeletion
ON Courses
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if any of the courses to be deleted are required as prerequisites
    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN CoursePrerequisites p ON d.CourseID = p.PrerequisiteCourseID
    )
    BEGIN
        RAISERROR('Cannot delete courses that are required as prerequisites for other courses', 16, 1);
        RETURN;
    END
    
    
    -- If no conflicts, proceed with deletion
    DELETE FROM Courses
    WHERE CourseID IN (SELECT CourseID FROM deleted);
END;
GO

-- Example usage:
DELETE FROM Courses WHERE CourseID = 4;
GO



