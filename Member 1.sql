

--Advanced Query with JOIN, GROUP BY, HAVING
SELECT 
    D.DepartmentName,
    AVG(S.GPA) AS AverageGPA
FROM 
    Students S
JOIN 
    Departments D ON S.DepartmentID = D.DepartmentID
WHERE 
    S.GPA IS NOT NULL
GROUP BY 
    D.DepartmentName
HAVING 
    AVG(S.GPA) > 3.0;
    
    
    
--Subquery with Aggregation  
    SELECT 
    S.StudentID,
    S.FirstName,
    S.LastName,
    COUNT(E.EnrollmentID) AS CourseCount
FROM 
    Students S
JOIN 
    Enrollments E ON S.StudentID = E.StudentID
GROUP BY 
    S.StudentID, S.FirstName, S.LastName
HAVING 
    COUNT(E.EnrollmentID) > (
        SELECT AVG(CourseCount)
        FROM (
            SELECT COUNT(*) AS CourseCount
            FROM Enrollments
            GROUP BY StudentID
        ) AS Sub
    );



--Nested Query with JOIN
SELECT 
    S.StudentID,
    S.FirstName,
    S.LastName
FROM 
    Students S
WHERE 
    S.StudentID IN (
        SELECT E.StudentID
        FROM Enrollments E
        JOIN CourseOfferings CO ON E.OfferingID = CO.OfferingID
        JOIN Courses C ON CO.CourseID = C.CourseID
        WHERE C.CourseCode = 'CS101'
    );




--- creating view of student progress 

CREATE VIEW vw_StudentProgress AS
SELECT 
    S.StudentID,
    S.FirstName,
    S.LastName,
    COUNT(E.EnrollmentID) AS TotalCourses,
    AVG(E.Grade) AS AverageGrade,
    S.GPA
FROM 
    Students S
LEFT JOIN 
    Enrollments E ON S.StudentID = E.StudentID
GROUP BY 
    S.StudentID, S.FirstName, S.LastName, S.GPA;



--List students who have taken more than 5 courses

SELECT *
FROM vw_StudentProgress
WHERE TotalCourses > 0;





--view to show instructor load 

CREATE VIEW vw_InstructorLoad AS
SELECT 
    I.InstructorID,
    I.FirstName,
    I.LastName,
    CO.Semester,
    CO.Year,
    COUNT(CO.OfferingID) AS TotalCoursesAssigned
FROM 
    Instructors I
LEFT JOIN 
    CourseOfferings CO ON I.InstructorID = CO.InstructorID
GROUP BY 
    I.InstructorID, I.FirstName, I.LastName, CO.Semester, CO.Year;

--list instructors with more than 2 courses assigned
SELECT *
FROM vw_InstructorLoad
WHERE TotalCoursesAssigned > 0;