### Part 1 
#### Task 1.1

Relation A: Employee
Employee(EmpID, SSN, Email, Phone, Name, Department, Salary) 

1. list at least 6 different superkeys

A. EmpID, SSN
B. SSN
C. EmpID, Email
D. Phone, Name, SSN
E. Department, Salary, EmpID
F. EmpID

2. Identify all candidate keys

A. EmpID
B. SSN
C. Email
D. Phone

3. Which candidate key would you choose as primary key and why?

I would choose EmpID because it is short and easy to remember and it cannot be null and it is unique.

4. Can two employees have the same phone number? Justify your answer based on the data shown.

It seems that phone number of each employee ends with their EmpID, so it should be unique.


Relation B: Course Registration
Registration(StudentID, CourseCode, Section, Semester, Year, Grade, Credits)

1. Determine the minimum attributes needed for the primary key

5 attributes, StudentID, CourseCode, Section, Semester, Year.

2. Explain why each attribute in your primary key is necessary
StudentID is needed to distinguish which student registered for which things, because there may be 2 students that picked the same thing

CourseCode is needed because a student can enroll in multiple distinct courses within the same semester and year.

Section is needed because a student could theoretically take different sections or components of a course

Semester is needed because of rule 1 which states that a student can take the same course in different semesters, without this attribute a student could pick the exact same thing but in different semester and we would get a duplicate

Year is needed to distinguish between same semesters (fall, spring) across years (fall 2026 and fall 2027 are different because of the year)

3. Identify any additional candidate keys (if they exist)
There are no additional candidate keys because remaining attributes Grade and Credits do not hold any additional information that helps in identifying unique rows

