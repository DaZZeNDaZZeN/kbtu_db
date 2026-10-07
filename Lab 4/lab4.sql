-- Create tables
CREATE TABLE employees
(
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    department  VARCHAR(50),
    salary      NUMERIC(10, 2),
    hire_date   DATE,
    manager_id  INTEGER,
    email       VARCHAR(100)
);
CREATE TABLE projects
(
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget       NUMERIC(12, 2),
    start_date   DATE,
    end_date     DATE,
    status       VARCHAR(20)
);
CREATE TABLE assignments
(
    assignment_id   SERIAL PRIMARY KEY,
    employee_id     INTEGER REFERENCES employees (employee_id),
    project_id      INTEGER REFERENCES projects (project_id),
    hours_worked    NUMERIC(5, 1),
    assignment_date DATE
);
-- Insert sample data
INSERT INTO employees (first_name, last_name, department,
                       salary, hire_date, manager_id, email)
VALUES ('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
        'john.smith@company.com'),
       ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
        'sarah.j@company.com'),
       ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
        'mbrown@company.com'),
       ('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
        'emily.davis@company.com'),
       ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
       ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
        'lisa.a@company.com');
INSERT INTO projects (project_name, budget, start_date,
                      end_date, status)
VALUES ('Website Redesign', 150000, '2024-01-01', '2024-06-30',
        'Active'),
       ('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
        'Active'),
       ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
        'Completed'),
       ('Database Migration', 120000, '2024-01-10', NULL, 'Active');
INSERT INTO assignments (employee_id, project_id,
                         hours_worked, assignment_date)
VALUES (1, 1, 120.5, '2024-01-15'),
       (2, 1, 95.0, '2024-01-20'),
       (1, 4, 80.0, '2024-02-01'),
       (3, 3, 60.0, '2024-03-05'),
       (5, 2, 110.0, '2024-02-20'),
       (6, 3, 75.5, '2024-03-10');


-- ============================================================================
-- PART 1: BASIC SELECT QUERIES
-- ============================================================================

-- Task 1.1: Query to select all employees
select (first_name || ' ' || last_name) full_name, department, salary
from employees;

-- Task 1.2 Find all unique departments
select distinct department
from employees;

-- Task 1.3 Select all projects with their names and budgets
select project_name,
       budget,
       case
           when budget > 150000 then 'Large'
           when budget between 100000 and 150000 then 'Medium'
           else 'Small'
           end budget_category
from projects;

-- Task 1.4 Display employee names and their emails
select (first_name || ' ' || last_name) full_name, coalesce(email, 'No email provided')
from employees;

-- ============================================================================
-- PART 2: WHERE CLAUSE AND COMPARISON OPERATORS
-- ============================================================================

-- Task 2.1 Employees hired after January 1, 2020
select *
from employees
where hire_date > '01-01-2020';

-- Task 2.2 Employees whose salary is between 60000 and 70000
select *
from employees
where salary between 60000 and 70000

-- Task 2.3 Employees whose last name starts with 'S' or 'J'
select *
from employees
where last_name ~ '[SJ].*';
-- or
select *
from employees
where last_name like 'S%'
   or last_name like 'J%';

-- Task 2.4 Employees who have a manager and work in the IT department
select *
from employees
where manager_id is not null
  and department = 'IT';

-- ============================================================================
-- PART 3: STRING AND MATHEMATICAL FUNCTIONS
-- ============================================================================

-- Task 3.1
select upper(first_name)   first_name,
       upper(last_name)    last_name,
       substr(email, 1, 3) email
from employees;

-- Task 3.2
select (salary * 12)  annual_salary,
       salary         monthly_salary, -- it is numeric(10, 2) so it does not need to be rounded to 2 decimals
       (salary * 1.1) ten_percent_raise
from employees;

-- Task 3.3
select format('Project: %s - Budget: $%s - Status: %s', project_name, budget, status)
from projects;

-- Task 3.4
select (first_name || ' ' || last_name)   full_name,
       extract(years from age(hire_date)) years
from employees;

-- ============================================================================
-- PART 4: AGGREGATE FUNCTIONS AND GROUP BY
-- ============================================================================

-- Task 4.1 Average salary for each department
select department, avg(salary)
from employees
group by department;

-- Task 4.2 Total hours worked on each project
select p.project_id,
       p.project_name,
       sum(a.hours_worked) AS total_hours_worked
from projects p
         left join assignments a ON p.project_id = a.project_id
group by p.project_id;

-- Task 4.3 Show departments with more than 1 employee
select department, count(*)
from employees
group by department
having count(*) > 1;

-- Task 4.4 Max min and sum
select max(salary) maximum, min(salary) minimum, sum(salary) total_payroll
from employees;

-- ============================================================================
-- PART 5: SET OPERATIONS
-- ============================================================================

-- Task 5.1 Union
select employee_id,
       (first_name || ' ' || last_name) full_name,
       salary
from employees
where salary > 60000
union
select employee_id,
       (first_name || ' ' || last_name) full_name,
       salary
from employees
where hire_date > '01-01-2020';

-- Task 5.2 Intersect
select *
from employees
where salary > 65000
intersect
select *
from employees
where department = 'IT';

-- Task 5.3 Except
select employee_id
from employees
except
select employee_id
from assignments;

-- ============================================================================
-- PART 6: SUBQUERIES
-- ============================================================================

-- Task 6.1 Employees with at least one project assigned
select *
from employees e
where exists (select employee_id from assignments where e.employee_id = assignments.employee_id);

-- Task 6.2 Employees working on projects with status 'Active'
select *
from employees
where employee_id in (select employee_id
                      from assignments a
                      where a.project_id in (select project_id from projects where status = 'Active'));

-- Task 6.3 Any
select *
from employees
where salary > any (select salary from employees where department = 'Sales');

-- ============================================================================
-- PART 7: COMPLEX QUERIES
-- ============================================================================

-- Task 7.1
select (first_name || ' ' || last_name) full_name, department, coalesce(avg(a.hours_worked), 0) hours_worked
from employees e
         left join assignments a on e.employee_id = a.employee_id
group by e.employee_id
order by e.department, e.salary;

-- Task 7.2
select project_name, sum(a.hours_worked) total_hours_worked, count(a.employee_id) employee_worked
from projects p
         left join assignments a on p.project_id = a.project_id
group by p.project_id
having sum(a.hours_worked) > 150;


-- Task 7.3
select department,
       count(*)              total_employees,
       round(avg(salary), 2) average_salary,
       max(salary)           max_salary,
       min(salary)           min_salary,
       (select e2.first_name || ' ' || e2.last_name
        from employees e2
        where e2.department = e.department
        order by e2.salary desc, e2.employee_id asc
        limit 1) as          highest_paid_employee
from employees e
group by department
order by department;