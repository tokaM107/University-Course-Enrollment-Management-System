
--Task1: Simulate Transactions Using BEGIN TRANSACTION, SAVEPOINT, COMMIT, and ROLLBACK
USE UniversityCourseSystem;

BEGIN TRANSACTION;

BEGIN TRY
    -- Check if email already exists to avoid unique constraint error
    IF EXISTS (SELECT 1 FROM Students WHERE Email = 'new.student.email@university.edu')
    BEGIN
        THROW 50001, 'A student with this email already exists.', 1;
    END

    -- Insert new student with updated data
    INSERT INTO Students (FirstName, LastName, Email, DateOfBirth, EnrollmentDate, DepartmentID, ProgramID, GPA, Balance)
    VALUES ('John', 'Doe', 'new.student.email@university.edu', '2002-07-22', '2025-03-01', 2, 3, 3.5, 1500.00);

    -- Savepoint after successful insert
    SAVE TRANSACTION SavePoint_AddStudent;

    -- Attempt invalid update (this will fail due to CHECK constraint)
    UPDATE Students SET Balance = -1000 WHERE StudentID = SCOPE_IDENTITY();

    -- If update succeeds (unexpected), commit transaction
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT 'Error detected: ' + ERROR_MESSAGE();

    -- Rollback entire transaction (savepoint may not exist if error before it)
    ROLLBACK TRANSACTION;
END CATCH;

--What happened? inserted a new student successfully Then  tried to update that student�s Balance to -1000, which violates the CHECK constraint (Balance must be >= 0)This causes an error.

--The error is caught in the CATCH block.

--Inside the CATCH, I ROLLBACK the entire transaction.

-- the insert is also rolled back because the error happened after the insert and I rolled back everything(the new student was NOT inserted permanently because the rollback undoes the entire transaction, including the insert)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Task2 Demonstrate a Dirty Read or Lost Update Problem
--here is windows/Session 1 another query file will hold the other transaction 
--Dirty read is only in read uncommitted 
BEGIN TRANSACTION;

-- Update balance but do not commit
UPDATE Students SET Balance = Balance + 500 WHERE StudentID = 1000;

-- Check balance
SELECT Balance FROM Students WHERE StudentID = 1000;
ROLLBACK TRANSACTION;

---------------------------------------------------------------------------------------------------------------------
--Lost Update 
--one update to overwrite the other unintentionally btw 2 Transactions
BEGIN TRANSACTION;

-- Update GPA
UPDATE Students SET GPA = 3.177 WHERE StudentID = 1000;
WAITFOR DELAY '00:00:10'; -- delay before commit

-- Commit the transaction
COMMIT TRANSACTION;
SELECT GPA FROM Students WHERE StudentID = 1000;
----------------------------------------------------------------------------------------------------------------------
--TASK3
--Examples Showing Different Isolation Levels
--(READ COMMITTED (Default)_#1
-- Session 1
BEGIN TRANSACTION;
UPDATE Students SET Balance = Balance - 700 WHERE StudentID = 1002;
-- No COMMIT or ROLLBACK yet, transaction is still open.
ROLLBACK TRANSACTION;

--#(READ UNCOMMITTED)
-- Session 1
BEGIN TRANSACTION;
UPDATE Students SET Balance = Balance + 1000 WHERE StudentID = 1001;

-- No COMMIT or ROLLBACK yet, transaction is still open.

-- Rollback changes in Session 1:
ROLLBACK TRANSACTION;

--( REPEATABLE READ)
-- Session 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT Balance FROM Students WHERE StudentID = 1000;

-- No other session can update or delete StudentID = 1000 until this transaction is committed or rolled back.

-- Session 2
UPDATE Students SET Balance = Balance - 300 WHERE StudentID = 1000;

-- Session 2 will be blocked until Session 1 completes.
-- Commit or Rollback in Session 1:
ROLLBACK TRANSACTION;

--#(REPEATABLE READ)
-- Session 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

-- Select the balance (this locks the row for reading and prevents modifications by others)
SELECT Balance FROM Students WHERE StudentID = 1000;

-- delay 
WAITFOR DELAY '00:00:10'; -- 10-second delay

-- Commit or Rollback to release the lock
ROLLBACK TRANSACTION;


-- No other session can update or delete StudentID = 1000 until this transaction is committed or rolled back.
SELECT Balance FROM Students WHERE StudentID = 1000;

--(SERIALIZABLE)
-- Session 1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

-- Lock the entire table by selecting all rows
SELECT * FROM Students;

-- Delay to simulate a long-running transaction
WAITFOR DELAY '00:00:15';

-- Commit the transaction (releasing the lock)
COMMIT TRANSACTION;


--(SNAPSHOT)
ALTER DATABASE UniversityCourseSystem
SET ALLOW_SNAPSHOT_ISOLATION ON;

--ALTER DATABASE UniversityCourseSystem
--SET READ_COMMITTED_SNAPSHOT ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

-- Reads balance as of transaction start, no locks held
SELECT Balance FROM Students WHERE StudentID = 1000;

WAITFOR DELAY '00:00:10';  -- 10 second delay to simulate long transaction

COMMIT TRANSACTION;




-----------------------------------------------------------------------------------------------------------------------
-- Shows currently blocked and blocking sessions
SELECT
    blocking_session_id,
    session_id,
    wait_type,
    wait_time,
    wait_resource,
    last_wait_type
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
-----------------------------------------------------------------------------------------------------------------------
--TASK4
 --#SQL Server Techniques to Solve Concurrency Issues
--**Concurrency issues happen when multiple users or processes try to read or modify the same data at the same time. This can lead to problems like:
--Dirty reads: Reading uncommitted (and possibly rolled-back) changes,Non-repeatable reads: Data changes between reads within the same transaction,Phantom reads: New rows appear or disappear during a transaction,Lost updates: Two transactions overwrite each other�s changes,Deadlocks: Two or more transactions block each other forever.
--we implement first solution isolation levels and seconed solution locking but not direct we could try shared locks? ,Row Versioning third solution implement by snapshot isolation level,Optimistic vs Pessimistic Concurrency 

--row level 
--Scenario
	--Student wants to see all courses they are registered for.

	--We lock the rows while reading so no one else can modify them during the read.

	--No edits allowed in this transaction � read-only with locking.

--student see courses with row-level shared locks:
-- Set isolation level to READ COMMITTED (default, uses shared locks)

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;

-- Select courses the student is enrolled in with shared locks to prevent modifications during read
SELECT 
    c.CourseID, 
    c.CourseCode, 
    c.CourseName, 
    co.Semester, 
    co.Year, 
    co.Schedule
FROM Enrollments e WITH (HOLDLOCK, ROWLOCK)
JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
JOIN Courses c ON co.CourseID = c.CourseID
WHERE e.StudentID = 1001 AND e.Status = 'Active';

-- Keep transaction open to hold locks while student reads the data
WAITFOR DELAY '00:00:10';  -- simulate 10 seconds reading time

COMMIT TRANSACTION;


--Uses tables: Enrollments, CourseOfferings, and Courses in a university system context.

--Filters enrollments by StudentID = 1001 and enrollment Status = 'Active'.

--Joins Enrollments to CourseOfferings and then to Courses.

--Retrieves detailed info: course code, semester, year, schedule, etc.

-------------------------------------------------------------------------------------
--Transaction with a trigger to pay courses
	--When a student pays  the system checks all their active enrollments.
	--Sum the fees of all active course offerings.
	--Deduct the total from the student's balance.
	--Prevent activation if balance is insufficient.
	--Use concurrency control to avoid race conditions.
	--Use a trigger to automatically do this when any enrollment changes to 'Active'.
	--Allow partial activation only if the student can pay for all active courses.

ALTER TABLE CourseOfferings
ADD Price DECIMAL(10, 2) NOT NULL DEFAULT 0;
GO

CREATE TRIGGER trg_PayForAllActiveCourses
ON Enrollments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only proceed if any enrollment status changed to 'Active'
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.EnrollmentID = d.EnrollmentID
        WHERE i.Status = 'Active' AND d.Status <> 'Active'
    )
    BEGIN
        DECLARE @StudentID INT;
        
        -- Get distinct StudentIDs with activation in this update
        DECLARE activatedStudents CURSOR FOR
        SELECT DISTINCT i.StudentID
        FROM inserted i
        JOIN deleted d ON i.EnrollmentID = d.EnrollmentID
        WHERE i.Status = 'Active' AND d.Status <> 'Active';

        OPEN activatedStudents;
        FETCH NEXT FROM activatedStudents INTO @StudentID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @TotalFee DECIMAL(10,2);
            DECLARE @Balance DECIMAL(10,2);

            -- Calculate total fee for all active enrollments for this student
            SELECT @TotalFee = SUM(co.Price)
            FROM Enrollments e WITH (UPDLOCK, HOLDLOCK)
            JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
            WHERE e.StudentID = @StudentID AND e.Status = 'Active';

            -- Get current balance with lock
            SELECT @Balance = Balance
            FROM Students WITH (UPDLOCK, HOLDLOCK)
            WHERE StudentID = @StudentID;

            IF @Balance >= @TotalFee
            BEGIN
                -- Deduct total fee once
                UPDATE Students
                SET Balance = Balance - @TotalFee
                WHERE StudentID = @StudentID;
            END
            ELSE
            BEGIN
                DECLARE @BalanceStr VARCHAR(20);
                DECLARE @TotalFeeStr VARCHAR(20);

                SET @BalanceStr = CONVERT(VARCHAR(20), @Balance);
                SET @TotalFeeStr = CONVERT(VARCHAR(20), @TotalFee);

                RAISERROR('Student %d has insufficient balance (%s) to pay total active courses fee (%s).',
                          16, 1,
                          @StudentID,
                          @BalanceStr,
                          @TotalFeeStr);
                ROLLBACK TRANSACTION;
                CLOSE activatedStudents;
                DEALLOCATE activatedStudents;
                RETURN;
            END

            FETCH NEXT FROM activatedStudents INTO @StudentID;
        END

        CLOSE activatedStudents;
        DEALLOCATE activatedStudents;
    END
END;
GO

--TEST
UPDATE Enrollments
SET Status = 'Active'
WHERE EnrollmentID = 5000;  --it was Completed


SELECT StudentID, Balance
FROM Students
WHERE StudentID = (SELECT StudentID FROM Enrollments WHERE EnrollmentID = 5000); --done
