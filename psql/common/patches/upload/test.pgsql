LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries

create temporary table t1 (a varchar, b varchar, dummy char);

create temporary table t2 (a varchar, a_id int, dummy char);

create temporary table t3 (b varchar, a_id int, dummy char);

create temporary table t4 (b varchar, b_id int, dummy char);

create temporary table t5 (a_id int, b_id int, dummy char);

create temporary table t6 (a_id int, b_id int, ab_id int, dummy char);

insert into t1 (values ('aaa', 'aaa'), ('aab', 'aaa'), ('aac', 'aab'), ('bac', 'dac'), ('bac', 'bac'), ('aaa', 'aaa'), ('aaa', 'aab'));

create temporary sequence a_seq;

create temporary sequence b_seq;

create temporary sequence ab_seq;

select * from t1;

select upload_bypart(-1, 't1', 't2', 't3', '{{"a:text"}}', 'a_id:int', 'a_seq', '/tmp/t1_3');

select * from t2;
select * from t3;

select upload_bypart(-1, 't3', 't4', 't5', '{{"b:text"}}', 'b_id:int', 'b_seq', null);

select * from t4;
select * from t5;

select upload_bypart(-1, 't5', 't6', null, '{{"a_id:int"},{"b_id:int"}}', 'ab_id:int', 'ab_seq', null);

select * from t6;
