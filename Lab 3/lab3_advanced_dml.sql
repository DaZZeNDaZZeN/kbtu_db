-- ============================================================================
-- Part A: Database and Table Setup
-- ============================================================================

-- 1. Create Database and Tables

create database advanced_lab;

drop table if exists departments cascade;
drop table if exists employees;
drop table if exists projects;

-- Table 1: departments
create table departments
(
    dept_id    serial primary key,
    dept_name  varchar(50) not null unique,
    budget     int         not null default 50000,
    manager_id int
);

-- Table 2: employees
create table employees
(
    emp_id     serial primary key,
    first_name varchar(50) not null,
    last_name  varchar(50) not null,
    department varchar(50) default 'Unassigned',
    salary     int         default 40000,
    hire_date  date        default current_date,
    status     varchar(20) default 'Active'
);

-- Table 3: projects
create table projects
(
    project_id   serial primary key,
    project_name varchar(100) not null,
    dept_id      int          references departments (dept_id) on delete set null,
    start_date   date,
    end_date     date,
    budget       int
);


-- ============================================================================
-- Part B: Advanced INSERT Operations
-- ============================================================================

-- 2. INSERT with column specification
insert into employees (first_name, last_name, department)
values ('John', 'Doe', 'IT');

-- 3. INSERT with DEFAULT values
insert into employees (first_name, last_name, department, salary, status)
values ('Jane', 'Smith', 'HR', default, default);

-- 4. INSERT multiple rows in single statement
insert into departments (dept_name, budget, manager_id)
values ('IT', 150000, 101),
       ('HR', 80000, 102),
       ('Sales', 120000, 103);

-- 5. INSERT with expressions
insert into employees (first_name, last_name, department, salary, hire_date)
values ('Alice', 'Johnson', 'Finance', 50000 * 1.1, current_date);

-- 6. INSERT from SELECT (subquery)
insert into employees (first_name, last_name, department, salary, hire_date, status)
select first_name, last_name, department, salary, hire_date, status
from employees
where department = 'IT';


-- ============================================================================
-- Part C: Complex UPDATE Operations
-- ============================================================================

-- Extra data for UPDATE & DELETE testing
insert into employees (first_name, last_name, department, salary, hire_date, status)
values ('Mark', 'Davis', 'IT', 65000, '2019-05-15', 'Active'),
       ('Lucy', 'Heart', 'Sales', 45000, '2021-03-10', 'Active'),
       ('David', 'Miller', 'Sales', 85000, '2018-11-01', 'Inactive'),
       ('Evelyn', 'Carter', 'IT', 35000, '2023-06-01', 'Terminated');

-- 7. UPDATE with arithmetic expressions
update employees
set salary = salary * 1.10
where salary is not null;

-- 8. UPDATE with WHERE clause and multiple conditions
update employees
set status = 'Senior'
where salary > 60000
  and hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
update employees
set status = case
                 when salary > 80000 and status == 'Active' then 'Senior'
                 when salary between 50000 and 80000 and status = 'Active' then 'Middle'
                 else 'Junior'
    end;

-- 10. UPDATE with DEFAULT
update employees
set department = default
where status = 'Inactive';

-- 11. UPDATE with subquery
update departments d
set budget = cast((select avg(e.salary) * count(e) * 1.2
                   from employees e
                   where e.department = d.dept_name) as int);

-- 12. UPDATE multiple columns
update employees
set salary = salary * 1.15,
    status = 'Promoted'
where department = 'Sales';


-- ============================================================================
-- Part D: Advanced DELETE Operations
-- ============================================================================

-- Insert projects for further deletion
insert into projects (project_name, dept_id, start_date, end_date, budget)
values ('Legacy System Upgrade', 1, '2022-01-01', '2022-12-31', 60000),
       ('Cloud Migration', 1, '2023-01-01', '2024-06-30', 120000);

-- 13. DELETE with simple WHERE condition
delete
from employees
where status = 'Terminated';

-- 14. DELETE with complex WHERE clause
delete
from employees
where salary < 40000
  and hire_date > '2023-01-01'
  and department is null;

-- 15. DELETE with subquery
delete
from departments
where dept_name not in (select distinct department
                        from employees
                        where department is not null);

-- 16. DELETE with RETURNING clause
delete
from projects
where end_date < '2023-01-01'
returning *;


-- ============================================================================
-- Part E: Operations with NULL Values
-- ============================================================================

-- 17. INSERT with NULL values
insert into employees (first_name, last_name, department, salary, status)
values ('Robert', 'Paulson', null, null, 'Active');

-- 18. UPDATE NULL handling
update employees
set department = 'Unassigned'
where department is null;

-- 19. DELETE with NULL conditions
delete
from employees
where salary is null
   or department is null;


-- ============================================================================
-- Part F: RETURNING Clause Operations
-- ============================================================================

-- 20. INSERT with RETURNING
insert into employees (first_name, last_name, department, salary)
values ('Sarah', 'Connor', 'IT', 65000)
returning emp_id, (first_name || ' ' || last_name) as full_name;

-- 21. UPDATE with RETURNING
update employees
set salary = salary + 5000
where department = 'IT'
returning emp_id, (salary - 5000) as old_salary, salary as new_salary;

-- 22. DELETE with RETURNING all columns
delete
from employees
where hire_date < '2020-01-01'
returning *;


-- ============================================================================
-- Part G: Advanced DML Patterns
-- ============================================================================

-- 23. Conditional INSERT
insert into employees (first_name, last_name, department, salary)
select 'Michael', 'Scott', 'Sales', 75000
where not exists (select 1
                  from employees
                  where first_name = 'Michael'
                    and last_name = 'Scott');

-- 24. UPDATE with JOIN logic using subqueries
update employees
set salary = salary * case
                          when (select budget
                                from departments
                                where dept_name = employees.department) > 100000 then 1.10
                          else 1.05
    end
where employees.department in (select dept_name from departments);

-- 25. Bulk operations
-- 25.1: Bulk insert 5 employees
insert into employees (first_name, last_name, department, salary, status)
values ('Tom', 'Hardy', 'Marketing', 45000, 'New'),
       ('Emma', 'Watson', 'Marketing', 48000, 'New'),
       ('Chris', 'Evans', 'Marketing', 52000, 'New'),
       ('Mark', 'Ruffalo', 'Marketing', 50000, 'New'),
       ('Scarlett', 'Johansson', 'Marketing', 55000, 'New');

-- 25.2: Bulk update inserted employees' salaries by 10%
update employees
set salary = salary * 1.10
where status = 'New';

-- 26. Data migration simulation
create table employee_archive
(
    emp_id      int primary key,
    first_name  varchar(50),
    last_name   varchar(50),
    department  varchar(50),
    salary      int,
    hire_date   date,
    status      varchar(20),
    archived_at timestamp default current_timestamp
);

with moved_employees as (
    delete from employees
        where status = 'Inactive'
        returning emp_id, first_name, last_name, department, salary, hire_date, status)
insert
into employee_archive (emp_id, first_name, last_name, department, salary, hire_date, status)
select emp_id, first_name, last_name, department, salary, hire_date, status
from moved_employees;

-- 27. Complex business logic
-- Add project
insert into projects (project_name, dept_id, start_date, end_date, budget)
values ('Enterprise ERP', (select dept_id from departments where dept_name = 'IT' limit 1), '2024-01-01', '2024-12-31',
        90000);

-- Update project according to business logic
update projects
set end_date = end_date + interval '30 days'
where budget > 50000
  and dept_id in (select dept_id
                  from departments
                  where dept_name in
                        (select department as c
                         from employees
                         group by department
                         having count(department) > 3));
