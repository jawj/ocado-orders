
-- in psql ...


-- loading

create database ocado;
\c ocado

create table products (
  timestamp int,
  name text,
  price real
);

\copy products from '/Users/George/Development/ocado-orders/ocado-orders.csv' csv

alter table products add column t timestamp;
update products set t = to_timestamp(timestamp) at time zone 'Europe/London';


-- analysis

# total qty and spend by product
select count(*) as qty, sum(price) as total, name from products group by name order by total desc;

# total qty and spend on butter and Weleda products
select count(*) as qty, sum(price) as total, name from products where name like '%Unsalted%Butter' group by name order by total desc;
select count(*) as qty, sum(price) as total, name from products where name like 'Weleda%' group by name order by total desc;

# total qty and spend by product for 2016
select count(*) as qty, sum(price) as total, name from products where extract(year from t) = 2016 group by name order by total desc;

# total spend by month
select date_trunc('month', t) as month, sum(price) as total from products group by month order by month asc;
