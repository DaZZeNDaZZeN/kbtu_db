-- Exercise 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);   -- 5
SELECT rental_days(11);  -- 8
SELECT rental_days(19);  -- NULL
SELECT rental_days(999); -- NULL

-- Both return NULL, but for different reasons.
-- For rental 19, the row exists in rentals, but its end_date is NULL (the rental is still open),
-- so the expression NULL - start_date evaluates to NULL.
-- For rental 999, no matching row exists in the table,
-- so SELECT ... INTO assigns NULL to v_days



-- Exercise 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*)
    INTO v_cnt
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_cnt;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);  -- 5
SELECT member_rental_count(5);  -- 4
SELECT member_rental_count(6);  -- 0
SELECT member_rental_count(99); -- 0

-- COUNT(*) is an aggregate function that always produces a single integer row,
-- even when the WHERE clause matches zero rows. Because the count of zero
-- matching rows is 0 (not an unknown value), PostgreSQL returns 0 rather
-- than NULL for both an existing member with no rentals (member 6)
-- and a nonexistent member (member 99)




-- Exercise 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30); -- 'Astana'
SELECT station_city(77); -- NULL


-- Exercise 2.4
SELECT rental_id,
       member_id,
       rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC, rental_id;



-- Exercise 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100.0), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15); -- 62.90



-- Exercise 3.2
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
)
AS $$
BEGIN
    SELECT COUNT(*)::INT,
           COALESCE(SUM(fee), 0),
           MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);


-- SELECT member_stats(3) packs all OUT parameters into a single anonymous
-- record column, whereas SELECT * FROM member_stats(3) unpacks them
-- into individual named columns (rental_cnt, total_fee, last_start).
-- Inside a larger query, FROM member_stats(...) (often with LATERAL)
-- is preferred because each column can be referenced directly by name
-- in SELECT, WHERE, JOIN, or ORDER BY without unpacking composite fields.
-- For member 6 (who has no rentals), rental_cnt is 0, total_fee is 0, and last_start is NULL.




-- Exercise 3.3
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee)
FROM rentals
WHERE rental_id = 1; -- 18.50 (13.50 + 5.00)

-- An INOUT parameter implicitly defines the function's return
-- type and automatically returns the final value of that parameter
-- when the function body finishes, so neither a RETURNS clause nor
-- an explicit RETURN statement is required.




-- Exercise 3.4
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total   NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
)
AS $$
BEGIN
    SELECT SUM(p_fees[i]),
           ROUND(AVG(p_fees[i]), 2),
           MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);

-- Calling fee_summary() with no arguments fails with ERROR: function fee_summary()
-- does not exist because a VARIADIC parameter without a DEFAULT requires at least
-- one argument. A VARIADIC parameter must be last in the parameter list because
-- it greedily consumes all remaining positional arguments; if another parameter
-- followed it, PostgreSQL could not tell where the variadic list ends and the next parameter begins.




-- Exercise 3.5
-- (a) The id of the row to look up: IN — the caller only passes a read-only
-- lookup key into the function.

-- (b) A running balance that the caller passes in and expects back updated:
-- INOUT — the function needs both to read the initial balance and to return
-- the modified value in the same parameter.

-- (c) A list of station ids of unknown length: VARIADIC — it accepts any
-- number of trailing arguments of the same type and collects them into an array.

-- (d) Two statistics returned together from one pass over a table: OUT — multiple
-- OUT parameters let the function return several named columns from a single SELECT ... INTO pass.






-- Exercise 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1); -- 98.50
SELECT total_fees(6); -- 0





-- Exercise 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01'); -- 98.50
SELECT total_fees(1, DATE '2025-01-01'); -- 50.00

-- List both overloaded versions
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc
WHERE proname = 'total_fees';




-- Exercise 4.3
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Fails with ambiguity error:
SELECT total_fees(1);
--  [42725] ERROR: function total_fees(integer) is not unique
--  Hint: Could not choose a best candidate function. You might need to add explicit type casts.
--  Position: 8

-- Both total_fees(INT) and total_fees(INT, DATE DEFAULT '2025-01-01') can legally
-- be called with a single INTEGER argument. Because neither is a strictly better
-- match than the other, PostgreSQL refuses to guess and raises an ambiguity error.




-- Exercise 4.4
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1); -- 50.00



-- Exercise 4.5
CREATE OR REPLACE FUNCTION total_fees(p_full_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.full_name = p_full_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova'); -- 98.50
SELECT total_fees(1);                 -- 50.00

-- Adding total_fees(VARCHAR) does not reintroduce ambiguity because its first
-- parameter type (VARCHAR) is completely distinct from INTEGER and neither type
-- is implicitly cast to the other. total_fees('Aisha Nurlanova') calls
-- total_fees(VARCHAR) and sums all of Aisha's rentals across all dates (98.50),
-- whereas total_fees(1) calls total_fees(INT, DATE DEFAULT '2025-01-01') and only
-- sums rentals starting on or after 2025-01-01 (50.00).




-- Exercise 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id    INT,
    found_model VARCHAR,
    found_rate  NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model, daily_rate
    FROM bikes
    WHERE model ILIKE p_pattern
    ORDER BY bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

-- Calling a set-returning function in the SELECT list without FROM packs
-- each returned row into a single composite-value column rather than expanding
-- the declared RETURNS TABLE columns into separate table columns.





-- Exercise 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    out_rental_id  INT,
    out_model      VARCHAR,
    out_station    VARCHAR,
    out_days       INT,
    out_fee        NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id,
           b.model,
           s.station_name,
           (r.end_date - r.start_date)::INT,
           r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);





-- Exercise 5.3
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- [42702] ERROR: column reference "bike_id" is ambiguous
--   Detail: It could refer to either a PL/pgSQL variable or a table column.
--   Where: PL/pgSQL function bike_list(integer) line 3 at RETURN QUERY

-- CREATE FUNCTION only checks basic PL/pgSQL syntax; embedded SQL statements
-- inside the body are parsed and bound against table schemas and PL/pgSQL
-- variables when the function is first executed. Because
-- RETURNS TABLE (bike_id INT, model VARCHAR) implicitly creates PL/pgSQL output
-- variables named bike_id and model, referencing unqualified bike_id
-- inside SELECT ... FROM bikes is ambiguous at runtime.



-- Exercise 5.3 - Fix 1: Rename output columns
DROP FUNCTION IF EXISTS bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model
    FROM bikes
    WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.3 - Fix 2: Keep output names, qualify table columns with alias
DROP FUNCTION IF EXISTS bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model
    FROM bikes b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);



-- Exercise 5.4
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name  VARCHAR,
    s_bikes INT,
    s_free  INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- if COUNT is not casted to integer we get this error
-- [42804] ERROR: structure of query does not match function result type
--   Detail: Returned type bigint does not match expected type integer in column "s_bikes" (position 2).




-- Exercise 6.1
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

-- If the label after END does not match the opening <<label>>, PostgreSQL rejects
-- the block at parse time with a syntax error: ERROR: end label "<wrong_label>"
-- differs from block's label "rental_report".




-- Exercise 6.2
DO $$
<<outer_block>>
DECLARE
    fee_total NUMERIC := 0;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
    RAISE NOTICE '1. Outer before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC := 0;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE '2. Subblock own value: %', fee_total;
        RAISE NOTICE '3. Outer value from inside subblock: %', outer_block.fee_total;
    END;

    RAISE NOTICE '4. Outer after subblock: %', fee_total;
END outer_block $$;

-- The four numbers are 621.50, 369.00, 621.50, and 621.50. The assignment inside
-- the subblock did not change the outer variable; declaring a variable of
-- the same name in a subblock creates an independent local variable that shadows
-- the outer one only for the lifetime of that subblock.



-- Exercise 6.3 - Failing version (sub_var out of scope in second subblock)
DO $$
BEGIN
    DECLARE
        sub_var INT := 42;
    BEGIN
        RAISE NOTICE 'First subblock: %', sub_var;
    END;

    BEGIN
        RAISE NOTICE 'Second subblock: %', sub_var; -- Fails here
    END;
END $$;

--[42703] ERROR: column "sub_var" does not exist
--  Where: PL/pgSQL function inline_code_block line 10 at RAISE

-- Exercise 6.3 - Fixed version (declaration moved to outer block)
DO $$
DECLARE
    sub_var INT := 42;
BEGIN
    BEGIN
        RAISE NOTICE 'First subblock: %', sub_var;
    END;

    BEGIN
        RAISE NOTICE 'Second subblock: %', sub_var;
    END;
END $$;




-- Exercise 6.4
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total  NUMERIC
)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO before_total
    FROM rentals
    WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0)
    INTO after_total
    FROM rentals
    WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT before_total,
       after_total,
       before_total + after_total AS split_sum,
       (SELECT SUM(fee) FROM rentals) AS table_total
FROM fee_split(DATE '2025-01-01');


-- Exercise 7.1
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT COUNT(b.bike_id)::INT, s.capacity
    INTO bikes_parked, v_capacity
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.station_id = p_station_id
    GROUP BY s.station_id, s.capacity;

    IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND((bikes_parked * 100.0) / v_capacity, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

-- Returning NULL when capacity = 0 is semantically accurate because percentage
-- occupancy is undefined for a station with zero docks (returning 0.0 would
-- falsely imply the station has empty docks available, and NULL also avoids
-- skewing downstream AVG(capacity_pct) calculations).





-- Exercise 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_cnt  INT,
    total_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY total_spent DESC, m.member_id
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

-- Aisha Nurlanova has 5 rentals—more than Chen Wei (4) and Daniyar Serik (4)—yet
-- is ranked 4th. This is not a bug because the function ranks members by total
-- amount spent, not rental count. Aisha spent 98.50 (one of her 5 rentals,
-- rental 19, is still open with a NULL fee, and she used lower-rate bikes),
-- which is less than Chen Wei's 139.25 and Daniyar Serik's 138.00.





-- Exercise 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model  VARCHAR,
    rental_days INT,
    amount_owed NUMERIC,
    status      VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);

-- For rental 11, the calculated amount (74.00) matches the stored
-- fee (74.00). For rental 19, end_date is NULL, so the duration is
-- calculated up to CURRENT_DATE (CURRENT_DATE - DATE '2025-10-10'),
-- which increases by 1 day (and 4.50 in fees) every calendar day.
-- A function that depends on CURRENT_DATE cannot be marked IMMUTABLE
-- because an IMMUTABLE function must always return the exact same output
-- for the same input arguments regardless of when it is called; it should
-- be STABLE (the default is VOLATILE).




-- Exercise 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_cnt    INT,
    rental_cnt    INT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (
    member_cnt    INT,
    rental_cnt    INT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r
      ON r.member_id = m.member_id
     AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
SELECT * FROM city_report('Astana', DATE '2025-01-01');

-- The date filter (r.start_date >= p_from_date) must go in the ON clause.
-- If placed in the WHERE clause, rows where r.start_date is NULL
-- (such as Elena Petrova, who lives in Almaty and has no rentals) fail
-- the WHERE predicate and get discarded, silently turning the LEFT JOIN into
-- an INNER JOIN. For Almaty, placing the date filter in ON gives member_cnt = 3,
-- whereas placing it in WHERE drops Elena Petrova and wrongly gives member_cnt = 2.




-- Lab Questions
--
-- 1. Function name vs. signature: A function's name is just its identifier
--    (e.g., total_fees), while its signature is the name combined with its
--    ordered list of input argument types (e.g., total_fees(integer, date)).
--    Because PostgreSQL allows overloading, multiple functions can share one name,
--    so DROP FUNCTION requires the full signature to know which specific version to remove.
--
--
-- 2. Purpose of dollar quoting ($$): Dollar quoting delimits a function body
--    so you can write single-quoted string literals inside PL/pgSQL without
--    escaping every apostrophe as ''. Example that would be awkward without $$:
--
--
-- 3. Multiple OUT parameters vs. RETURNS TABLE: Use multiple OUT parameters
--    when the function always returns a single row of several values
--    (such as aggregate stats for one member in member_stats). Use RETURNS TABLE
--    when the function returns a set of zero, one,
--    or many rows (such as find_bikes or member_history).
--
--
-- 4. Why VARIADIC must be last: A VARIADIC parameter consumes an arbitrary number
--    of trailing arguments into an array. If a function were defined
--    as f(VARIADIC a INT[], b INT) and called as f(1, 2, 3), PostgreSQL could
--    not determine whether a should receive {1, 2} and b receive 3, or if an
--    argument is missing—and with default values or matching types,
--    parsing becomes completely ambiguous.
--
--
-- 5. RETURN vs. RETURN QUERY: RETURN expression immediately exits a scalar
--    function and hands back a single value. RETURN QUERY SELECT ... appends
--    all rows produced by a SELECT query to the result set of a set-returning
--    (RETURNS TABLE / RETURNS SETOF) function without immediately terminating execution.
--
--
-- 6. Why a DEFAULT parameter can break existing calls: Adding a default value
--    makes a multi-argument function callable with fewer arguments; if an overloaded
--    function with that shorter signature already exists, existing calls become
--    ambiguous (function ... is not unique). In production, avoid overloading
--    the same function name when using DEFAULT parameters—either extend a single
--    function with optional trailing defaults or use distinct function names.
--
--
-- 7. Subblock variable lifetime and shadowing: A variable declared in a subblock
--    exists only while that subblock executes and is destroyed as soon as the
--    subblock's END; is reached. If it shadows an outer variable of the same
--    name, you can still read the outer variable from inside the subblock by
--    qualifying it with the outer block's label: outer_label.variable_name
--
--
-- 8. Advantage and disadvantage of moving business logic into stored functions:
--
--    Advantage: Consistency and performance—every client shares one central rule,
--    and multi-step operations execute inside the database in a single network round trip.
--
--    Disadvantage: Portability and maintainability—PL/pgSQL is PostgreSQL-specific,
--    harder to version-control and unit-test than application code, and shifts
--    CPU load onto the database server.
--
--
-- 9. Trusted vs. untrusted procedural languages: A trusted language (like PL/pgSQL)
--    is sandboxed and cannot access the server's filesystem, OS processes,
--    or network, so regular database users can safely create functions in it.
--    An untrusted language (like PL/Python or C) has unrestricted access to
--    the host system, so only a database superuser is allowed to create functions in it.
--
--
-- 10. Changing argument types with CREATE OR REPLACE FUNCTION: Because
--     PostgreSQL identifies functions by signature (name + argument types),
--     changing the argument types does not replace the old function—it creates
--     a second, overloaded function alongside the original. Existing callers may
--     silently continue hitting the stale old version, or calls may fail with
--     ambiguity errors if both signatures match.
