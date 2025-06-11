USE UniversityCourseSystem;

--Session2
--Task2
--Dirty read 
-- Read the uncommitted data
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Balance FROM Students WHERE StudentID = 1000;

--------------------------------------------------------------------------------------
--lost update
BEGIN TRANSACTION;

-- Update GPA
UPDATE Students SET GPA = 3.466 WHERE StudentID = 1000;

-- Commit the transaction
COMMIT TRANSACTION;
--the reason this transaction updated the gpa not the one in the first session is cause the transaction in session 1 has delay before commit and this not
SELECT GPA FROM Students WHERE StudentID = 1000;
-----------------------------------------------------------------------------------------
--TASK3
--(READ COMMITTED)

-- No COMMIT or ROLLBACK yet, transaction is still open.

-- Session 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Balance FROM Students WHERE StudentID = 1000;
--#(READ UNCOMMITTED)

-- Session 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Balance FROM Students WHERE StudentID = 1000;

-- Session 2 can see the uncommitted updated balance.



--#(REPEATABLE READ)
-- Session 2
-- Attempt to update the balance
UPDATE Students SET Balance = Balance - 300 WHERE StudentID = 1000;

-- Session 2 will be blocked until Session 1 completes (commits or rolls back).

SELECT Balance FROM Students WHERE StudentID = 1000;

--(SERIZABLE)

-- Session 2
-- Attempt to insert a new record (will be blocked by Session 1)
INSERT INTO Students (FirstName, LastName, Email, DateOfBirth, EnrollmentDate, DepartmentID, ProgramID, GPA, Balance)
VALUES ('Jane', 'Doe', 'DODYYYY.doe@university.edu', '2002-08-15', '2025-03-01', 2, 3, 3.67, 1500.00);

-- Session 2 will be blocked because SERIALIZABLE prevents any conflicting operations.

--(SNAPSHOT)
-- Update the Balance while Session 1 is still reading
UPDATE Students SET Balance = Balance + 500 WHERE StudentID = 1000;

-----------------------------------------------------------------------------------------