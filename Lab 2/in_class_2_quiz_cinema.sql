-- Task 1
create database cinema_db
    with template = template0
         encoding = 'UTF8'
         connection limit = 25;

-- Task 2
create table movies (
    movie_id serial primary key,
    title varchar(150),
    release_year varchar(4),
    age_rating char(3),
    runtime interval,
    rating float(1),
    budget numeric(12, 2),
    is_3d bool
);

-- Task 3
create table screenings (
    screening_id serial primary key,
    movie_id integer,
    hall_number smallint,
    screening_date date,
    start_time time without time zone,
    ticket_price numeric(6, 2),
    created_at timestamp with time zone
);

-- Task 4
alter table  movies
    alter column release_year type integer using release_year::integer,
    drop column is_3d,
    add column genre varchar(30);

alter table screenings
    alter column hall_number set default 1,
    add column is_sold_out bool,
    alter column is_sold_out set default false;

-- Task 5
drop table if exists screenings cascade;
create table screenings (
    screening_id serial primary key,
    movie_id integer,
    screening_date date,
    language varchar(20)
);
