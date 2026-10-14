
-- ============================================================================
-- PART 1: CHECK CONSTRAINTS
-- ============================================================================

-- Task 1.1: basic CHECK
create table employees (
    employee_id serial primary key,
    first_name text,
    last_name text,
    age integer check (age between 18 and 65),
    salary numeric(10, 2) check (salary > 0)
);

-- Task 1.2: named CHECK
create table products_catalog (
    product_id serial primary key,
    product_name text,
    regular_price numeric(10, 2),
    discounted_price numeric(10, 2),
    constraint valid_discount check (regular_price > 0 and
                                     discounted_price > 0 and
                                     discounted_price < regular_price)
);

-- Task 1.3: multiple column CHECK
create table bookings (
    booking_id serial primary key,
    check_in_date date,
    check_out_date date,
    num_guests integer,
    check (num_guests between 1 and 10 and check_out_date > check_in_date)
);

-- Task 1.4: testing CHECK constraints
-- good
insert into employees (first_name, last_name, age, salary) values ('Ren', 'Charette', 19, 150000);
insert into employees (first_name, last_name, age, salary) values ('Neko', 'Para', 21, 120000);
-- bad, age is less than 18
-- insert into employees (first_name, last_name, age, salary) values ('Some', 'Guy', 15, 500);

-- good
insert into products_catalog (product_name, regular_price, discounted_price) values ('Soap', 450, 350);
insert into products_catalog (product_name, regular_price, discounted_price) values ('Candy', 600, 480);
-- bad, discounted_price > regular_price
-- insert into products_catalog (product_name, regular_price, discounted_price) values ('Tea', 640, 750);

-- good
insert into bookings (check_in_date, check_out_date, num_guests) values ('15-09-2026', '18-09-2026', 3);
insert into bookings (check_in_date, check_out_date, num_guests) values ('23-09-2026', '27-09-2026', 2);
-- bad, num_guests > 10
-- insert into bookings (check_in_date, check_out_date, num_guests) values ('11-10-2026', '12-10-2026', 14);

-- ============================================================================
-- PART 2: NOT NULL CONSTRAINTS
-- ============================================================================

-- Task 2.1: NOT NULL implementation
create table customers (
    customer_id serial primary key,
    email text not null,
    phone text,
    registration_date date not null
);

-- Task 2.2: combining constraints
create table inventory (
    item_id serial primary key,
    item_name text not null,
    quantity integer not null check (quantity >= 0),
    unit_price numeric(10, 2) not null check (unit_price > 0),
    last_updated timestamp not null
);

-- Task 2.3: testing NOT NULL
-- good
insert into customers (email, phone, registration_date) values ('customer1@email.com', '+12345', current_date);
insert into customers (email, phone, registration_date) values ('customer2@email.com', null, current_date);
-- bad, email cannot be null
-- insert into customers (email, phone, registration_date) values (null, '+23456', current_date);

-- good, inventory records with valid data
insert into inventory (item_name, quantity, unit_price, last_updated) values ('Laptop', 10, 1200.00, current_timestamp);
insert into inventory (item_name, quantity, unit_price, last_updated) values ('Mouse', 50, 25.50, current_timestamp);
-- bad, quantity cannot be null
-- insert into inventory (item_name, quantity, unit_price, last_updated) values ('Keyboard', null, 45.00, current_timestamp);
-- bad, unit_price cannot be null
-- insert into inventory (item_name, quantity, unit_price, last_updated) values ('Monitor', 15, null, current_timestamp);

-- ============================================================================
-- PART 3: UNIQUE CONSTRAINTS
-- ============================================================================

-- Task 3.1: single column UNIQUE
create table users (
    user_id serial primary key,
    username text unique,
    email text unique,
    created_at timestamp
);

-- Task 3.2: multi-column UNIQUE
create table course_enrollments (
    enrollment_id serial primary key,
    student_id integer,
    course_code text,
    semester text,
    constraint unique_enrollment unique (student_id, course_code, semester)
);

-- Task 3.3: named UNIQUE constraints
drop table if exists users cascade;
create table users (
    user_id serial primary key,
    username text,
    email text,
    created_at timestamp
);

alter table users add constraint unique_username unique (username);
alter table users add constraint unique_email unique (email);


-- testing unique constraints
-- good
insert into users (username, email, created_at) values ('alice123', 'alice@email.com', current_timestamp);
insert into users (username, email, created_at) values ('bob456', 'bob@email.com', current_timestamp);
-- bad, duplicate username violates unique_username
-- insert into users (username, email, created_at) values ('alice123', 'alice_new@email.com', current_timestamp);
-- bad, duplicate email violates unique_email
-- insert into users (username, email, created_at) values ('charlie789', 'alice@email.com', current_timestamp);

-- good, enrollment combinations
insert into course_enrollments (student_id, course_code, semester) values (101, 'CS101', 'Fall2026');
insert into course_enrollments (student_id, course_code, semester) values (101, 'CS102', 'Fall2026');
-- bad, duplicate combination of student_id, course_code, and semester
-- insert into course_enrollments (student_id, course_code, semester) values (101, 'CS101', 'Fall2026');

-- ============================================================================
-- PART 4: PRIMARY KEY CONSTRAINTS
-- ============================================================================

-- Task 4.1: single column primary key
create table departments (
    dept_id integer primary key,
    dept_name text not null,
    location text
);

-- insert sample departments
insert into departments (dept_id, dept_name, location) values (1, 'Human Resources', 'Building A');
insert into departments (dept_id, dept_name, location) values (2, 'Engineering', 'Building B');
insert into departments (dept_id, dept_name, location) values (3, 'Marketing', 'Building C');

-- bad, duplicate dept_id violates primary key constraint
-- insert into departments (dept_id, dept_name, location) values (1, 'Finance', 'Building D');
-- bad, null dept_id violates primary key constraint
-- insert into departments (dept_id, dept_name, location) values (null, 'Sales', 'Building E');

-- Task 4.2: composite primary key
create table student_courses (
    student_id integer,
    course_id integer,
    enrollment_date date,
    grade text,
    primary key (student_id, course_id)
);

-- Task 4.3: comparison exercise
-- 1. difference between UNIQUE and PRIMARY KEY:
--    - a primary key uniquely identifies each record, cannot accept null values, and a table can have only one primary key.
--    - a unique constraint also ensures column values are distinct, but it allows a single null value and a table can have multiple unique constraints.
-- 2. when to use single-column vs composite PRIMARY KEY:
--    - use a single-column primary key when a surrogate or natural ID uniquely identifies the row on its own.
--    - use a composite primary key when identity relies on the combination of multiple columns (such as association tables in many-to-many relationships).
-- 3. why a table can have only one PRIMARY KEY but multiple UNIQUE constraints:
--    - the primary key uniquely and definitely identifies each row and serves as main source of row identification, whereas multiple unique constraints can be used to identify multiple unique attributes.

-- ============================================================================
-- PART 5: FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Task 5.1: basic foreign key
create table employees_dept (
    emp_id integer primary key,
    emp_name text not null,
    dept_id integer references departments(dept_id),
    hire_date date
);

-- good, valid dept_id exists in departments table
insert into employees_dept (emp_id, emp_name, dept_id, hire_date) values (1, 'John Doe', 1, current_date);
insert into employees_dept (emp_id, emp_name, dept_id, hire_date) values (2, 'Jane Smith', 2, current_date);
-- bad, non-existent dept_id violates foreign key constraint
-- insert into employees_dept (emp_id, emp_name, dept_id, hire_date) values (3, 'Bob Ross', 99, current_date);

-- Task 5.2: multiple foreign keys
create table authors (
    author_id integer primary key,
    author_name text not null,
    country text
);

create table publishers (
    publisher_id integer primary key,
    publisher_name text not null,
    city text
);

create table books (
    book_id integer primary key,
    title text not null,
    author_id integer references authors(author_id),
    publisher_id integer references publishers(publisher_id),
    publication_year integer,
    isbn text unique
);

-- insert sample data into library system
insert into authors (author_id, author_name, country) values (1, 'J.K. Rowling', 'UK');
insert into authors (author_id, author_name, country) values (2, 'George Orwell', 'UK');

insert into publishers (publisher_id, publisher_name, city) values (1, 'Bloomsbury', 'London');
insert into publishers (publisher_id, publisher_name, city) values (2, 'Secker & Warburg', 'London');

insert into books (book_id, title, author_id, publisher_id, publication_year, isbn)
values (1, 'Harry Potter', 1, 1, 1997, '978-0747532743');
insert into books (book_id, title, author_id, publisher_id, publication_year, isbn)
values (2, '1984', 2, 2, 1949, '978-0451524935');

-- Task 5.3: ON DELETE options
create table categories (
    category_id integer primary key,
    category_name text not null
);

create table products_fk (
    product_id integer primary key,
    product_name text not null,
    category_id integer references categories(category_id) on delete restrict
);

create table orders (
    order_id integer primary key,
    order_date date not null
);

create table order_items (
    item_id integer primary key,
    order_id integer references orders(order_id) on delete cascade,
    product_id integer references products_fk(product_id),
    quantity integer check (quantity > 0)
);

-- insert sample data to test ON DELETE behaviors
insert into categories (category_id, category_name) values (1, 'Electronics');
insert into products_fk (product_id, product_name, category_id) values (101, 'Smartphone', 1);

insert into orders (order_id, order_date) values (500, current_date);
insert into order_items (item_id, order_id, product_id, quantity) values (1001, 500, 101, 2);

-- 1. try to delete a category that has products (should fail with RESTRICT)
-- delete from categories where category_id = 1;

-- 2. delete an order and observe that order_items are automatically deleted (CASCADE)
-- delete from orders where order_id = 500;

-- 3. documentation of results:
--    - ON DELETE RESTRICT prevents parent deletion if child references exist.
--    - ON DELETE CASCADE automatically deletes all dependent child rows when the parent record is removed.

-- ============================================================================
-- PART 6: PRACTICAL APPLICATION
-- ============================================================================

-- Task 6.1: e-commerce database design
create table ecommerce_customers (
    customer_id serial primary key,
    name text not null,
    email text unique not null,
    phone text,
    registration_date date not null
);

create table ecommerce_products (
    product_id serial primary key,
    name text not null,
    description text,
    price numeric(10, 2) not null check (price >= 0),
    stock_quantity integer not null check (stock_quantity >= 0)
);

create table ecommerce_orders (
    order_id serial primary key,
    customer_id integer references ecommerce_customers(customer_id) on delete restrict,
    order_date date not null,
    total_amount numeric(10, 2) not null check (total_amount >= 0),
    status text not null check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

create table order_details (
    order_detail_id serial primary key,
    order_id integer references ecommerce_orders(order_id) on delete cascade,
    product_id integer references ecommerce_products(product_id) on delete restrict,
    quantity integer not null check (quantity > 0),
    unit_price numeric(10, 2) not null check (unit_price >= 0)
);

-- insert 5 sample records per table
-- customers
insert into ecommerce_customers (name, email, phone, registration_date) values ('Alice Smith', 'alice.smith@email.com', '555-0101', '2026-01-10');
insert into ecommerce_customers (name, email, phone, registration_date) values ('Bob Jones', 'bob.jones@email.com', '555-0102', '2026-01-15');
insert into ecommerce_customers (name, email, phone, registration_date) values ('Charlie Brown', 'charlie.brown@email.com', '555-0103', '2026-02-01');
insert into ecommerce_customers (name, email, phone, registration_date) values ('Diana Prince', 'diana.prince@email.com', '555-0104', '2026-02-20');
insert into ecommerce_customers (name, email, phone, registration_date) values ('Evan Wright', 'evan.wright@email.com', '555-0105', '2026-03-01');

-- products
insert into ecommerce_products (name, description, price, stock_quantity) values ('Wireless Mouse', 'Ergonomic optical mouse', 25.99, 150);
insert into ecommerce_products (name, description, price, stock_quantity) values ('Mechanical Keyboard', 'RGB backlit keyboard', 79.99, 80);
insert into ecommerce_products (name, description, price, stock_quantity) values ('HD Monitor', '27-inch 1080p monitor', 199.99, 45);
insert into ecommerce_products (name, description, price, stock_quantity) values ('USB-C Hub', 'Multiport adapter', 35.50, 200);
insert into ecommerce_products (name, description, price, stock_quantity) values ('Gaming Headset', 'Surround sound headset', 59.99, 90);

-- orders
insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (1, '2026-03-05', 105.98, 'delivered');
insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (2, '2026-03-10', 199.99, 'shipped');
insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (3, '2026-03-12', 35.50, 'processing');
insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (4, '2026-03-14', 139.98, 'pending');
insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (5, '2026-03-15', 79.99, 'cancelled');

-- order_details
insert into order_details (order_id, product_id, quantity, unit_price) values (1, 1, 1, 25.99);
insert into order_details (order_id, product_id, quantity, unit_price) values (1, 5, 1, 59.99);
insert into order_details (order_id, product_id, quantity, unit_price) values (2, 3, 1, 199.99);
insert into order_details (order_id, product_id, quantity, unit_price) values (3, 4, 1, 35.50);
insert into order_details (order_id, product_id, quantity, unit_price) values (4, 2, 1, 79.99);

-- test query 1: retrieve customer orders with full details
select c.name as customer_name, o.order_id, o.status, p.name as product_name, od.quantity, od.unit_price
from ecommerce_customers c
join ecommerce_orders o on c.customer_id = o.customer_id
join order_details od on o.order_id = od.order_id
join ecommerce_products p on od.product_id = p.product_id;

-- test query 2: attempt invalid status check constraint
-- insert into ecommerce_orders (customer_id, order_date, total_amount, status) values (1, current_date, 50.00, 'unknown');

-- test query 3: attempt negative price check constraint
-- insert into ecommerce_products (name, description, price, stock_quantity) values ('Bad Product', 'Test', -5.00, 10);