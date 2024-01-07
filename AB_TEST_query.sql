-- Link fo the database: postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766-pooler.us-east-2.aws.neon.tech/Globox

-- Query to know how many users made more than one purchase:
SELECT Count (*)
FROM   (SELECT uid,
               Count(uid)
        FROM   activity
        GROUP  BY uid
        HAVING Count(uid) > 1
        ORDER  BY Count(uid) DESC) AS new_table; 
-- 139 users that bought more than once.

-- Query to know the start and end dates of the experiment:
SELECT CASE
         WHEN date_groups.min_groups < date_activity.min_activity THEN
         date_groups.min_groups
         ELSE date_activity.min_activity
       END AS minimum_value,
       CASE
         WHEN date_groups.max_groups > date_activity.max_activity THEN
         date_groups.max_groups
         ELSE date_activity.max_activity
       END AS maximum_value
FROM   (SELECT Min(join_dt) AS min_groups,
               Max(join_dt) AS max_groups
        FROM   groups) AS date_groups,
       (SELECT Min(dt) AS min_activity,
               Max(dt) AS max_activity
        FROM   activity) AS date_activity; 
-- Start is 2023-01-25 and end is 2023-02-06

-- Query to know how many total users were in the experiment:
SELECT Count (*) FROM groups; 
-- OR
SELECT Count (*) FROM users; 
-- 48943 users

-- Query to know how many users were in the control and treatment groups:
SELECT "group",
       Count (*)
FROM   groups
GROUP  BY "group"; 
-- 24343 in Control Group and 24600 in Treatment Group

-- Query to know the conversion rate of all users:
SELECT ( Count(DISTINCT activity.uid) * 1.00 / Count(DISTINCT
       "groups".uid) ) * 100
FROM   "groups"
       LEFT JOIN activity
              ON "groups".uid = activity.uid;  
-- The conversion rate is 4.28%

-- Query to know the user conversion rate for the control and treatment groups:
SELECT "group",
       ( Count(DISTINCT activity.uid) * 1.00 / Count(DISTINCT "groups".uid) ) *
       100
FROM   "groups"
       LEFT JOIN activity
              ON "groups".uid = activity.uid
GROUP  BY "group";
-- 3.92% in Control Group and 4.63% in Treatment Group

-- Query to know the average amount spent per user for the control and treatment groups:
SELECT "group",
       Sum(spent) / Count(DISTINCT groups.uid)
FROM   groups
       LEFT JOIN activity
              ON groups.uid = activity.uid
GROUP  BY "group"; 
-- $3.37 in Control Group and $3.39 in Treatment Group

-- Data base to use in Tableau (using join_dt for the novelty effects)
CREATE temp TABLE test AS
  (SELECT id,
          join_dt,
          country,
          gender,
          GROUPS.device,
          GROUPS.group,
          SUM(spent) AS sum_spent
   FROM   users
          left join GROUPS
                 ON users.id = GROUPS.UID
          left join activity
                 ON GROUPS.UID = activity.UID
   GROUP  BY id,
             join_dt,
             country,
             gender,
             GROUPS.device,
             GROUPS.group
   ORDER  BY id);

UPDATE test
SET    sum_spent = 0.00
WHERE  sum_spent IS NULL;

SELECT id,
       join_dt,
       country,
       gender,
       device,
       "group",
       Cast(sum_spent AS NUMERIC(10, 2)),
       CASE
         WHEN sum_spent = 0 THEN 0
         ELSE 1
       END AS purchase
FROM   test; 
