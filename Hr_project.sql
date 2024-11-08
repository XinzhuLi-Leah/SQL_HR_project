-- 注意：please keep raw_data:hr_raw 原始表格必须保留
CREATE TABLE Human_Resources AS
SELECT *
FROM hr_raw;

-- data cleaning

-- 1.change column name 修改列的名字
SET SQL_SAFE_UPDATES = 0;    -- 安全模式先关闭一下

ALTER TABLE Human_Resources
CHANGE COLUMN id emp_id VARCHAR(20) NULL;

-- 2.date transform 日期整理
-- 原本导入的日期数据是TEXT 类型 
-- TEXT 类型本质上是字符串类型的一种。它用于存储长文本数据，可以看作是一个特殊的字符串类型。不同点在于：
-- CHAR 和 VARCHAR：用于存储较短的字符串，CHAR 是固定长度，VARCHAR 是可变长度。
-- TEXT：用于存储大量的文本数据，比 VARCHAR 支持更长的字符数，适合存放文章、评论或描述等。

-- 是的，你需要两步：首先整理日期格式，然后再更改列的数据类型。这是因为数据库不能自动将不符合日期格式的数据转换为日期类型，所以你需要确保所有的数据格式都正确。


SELECT hire_date from Human_Resources;

SELECT 
	  hire_date,
	  case 
		WHEN hire_date LIKE '%/%' THEN STR_TO_DATE(hire_date, '%d/%m%Y')
		WHEN hire_date LIKE '%-%' THEN STR_TO_DATE(hire_date, '%d-%m-%Y')
	end as date_time
	from Human_Resources

-- STR_TO_DATE 是一种 SQL 函数，用于将字符串类型的数据解析并转换为日期格式。
-- 为什么上面的version 是错的，因为举个例子，1/20/2022:这很明显是m-d-y的形式，而如果你把这个格式解析为d-m-y，就会有问题啊，怎么会有20月呢？
-- 9/29/2010 这个也是 你解析为了 d-m-y，当然是错的啊

SELECT 
	  hire_date,
	  case 
		WHEN hire_date LIKE '%/%' THEN STR_TO_DATE(hire_date, '%m/%d/%Y')
		WHEN hire_date LIKE '%-%' THEN STR_TO_DATE(hire_date, '%m-%d-%Y')
	end as date_time
	from Human_Resources
    

UPDATE Human_Resources
SET hire_date = 
  case
	WHEN hire_date LIKE '%/%' THEN str_to_date(hire_date, '%m/%d/%Y')
    WHEN hire_date LIKE '%-%' THEN str_to_date(hire_date, '%m-%d-%Y')
    ELSE NULL
END;
-- 如果 hire_date 列的数据类型是 TEXT 或 VARCHAR，即便你用 STR_TO_DATE() 函数成功将字符串转换为日期格式，在更新时它会被存储为字符串，而不是实际的日期格式。
-- 这就是为什么所有日期都显示为 YYYY-MM-DD 格式（标准的日期字符串格式）。


-- VS date_format
-- DATE_FORMAT() 是用来将日期或日期时间类型数据格式化为字符串，而不是用于改变数据库中存储的日期格式。
ALTER TABLE Human_Resources MODIFY hire_date DATE;

-- 如果你希望更新后的日期在存储中仍保持原有的分隔符（如 /），那么你应该转换后再重新格式化成字符串
UPDATE Human_Resources
SET hire_date = 
  CASE
    WHEN hire_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m/%d/%Y'), '%m/%d/%Y')
    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'), '%m/%d/%Y')
    ELSE NULL
  END;
  
select birthdate from Human_Resources
 
UPDATE Human_Resources
SET birthdate = 
  CASE
    WHEN birthdate LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m/%d/%Y'), '%Y/%m/%d')
    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m-%d-%Y'), '%Y/%m/%d')
    ELSE NULL
  END;
  
  ALTER TABLE Human_Resources MODIFY birthdate DATE;
  
 -- date()：将日期时间格式进一步转换为仅包含日期部分（YYYY-MM-DD）。请注意小时是i而不是m ,因为m已经被用来是月份了
UPDATE Human_Resources
SET termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != ' ';

-- 这里出错了，这个错误是因为 '0000-00-00' 不是一个有效的日期值。在 MySQL 的某些配置（如严格模式）下，它会被视为不合法的日期。
UPDATE Human_Resources
SET termdate = '0000-00-00'
where termdate is null

UPDATE Human_Resources
SET termdate = '1500-01-01'
where termdate is null 

-- 算了，没有离职的员工还是用9999会比较好
UPDATE Human_Resources
SET termdate = '9999-01-01' 
WHERE termdate = '1500-01-01';

SELECT termdate from Human_Resources

ALTER TABLE Human_Resources
MODIFY COLUMN termdate DATE;

-- 3.添加一列年纪的列 同时还需要我们去计算年纪
ALTER TABLE Human_Resources 
ADD COLUMN age INT;

UPDATE Human_Resources
SET age = timestampdiff(year,birthdate,curdate())
-- 发现了好多负数年纪，是怎么造成的呢？因为在生日那一栏很多人填的是两位数年份，比如89，76，66，然后SQL上面update日期的时候自动的解析了2089，2067，那和现在的curdate()相比，那就是负数年纪
-- 怎么解决呢？2066年减去100年就好喽！

select birthdate ,date_sub(birthdate, interval 100 year) from Human_Resources
where year(birthdate) > '2024'

UPDATE Human_Resources
SET birthdate = date_sub(birthdate, interval 100 year)
WHERE year(birthdate) > '2024'




-- 4.QUESTIONS

-- 1. What is the gender breakdown of employees in the company?
select gender,count(*) as employee_numbers
from Human_Resources
group by gender

-- 2. What is the race/ethnicity breakdown of employees in the company?
select race,count(*) as employee_numbers
from Human_Resources
group by race
order by employee_numbers desc


-- 3. What is the age distribution of employees in the company?
select
min(age) as yongest_age,max(age) as oldest_age
from  Human_Resources

WITH tmp1 AS 
(SELECT emp_id,age,FLOOR(age/10)*10 AS age_group
FROM Human_Resources
)
SELECT 
age_group, COUNT(*) AS count
FROM tmp1
GROUP BY FLOOR(age/10)*10
ORDER BY FLOOR(age/10)*10


SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, 
  COUNT(*) AS count
FROM 
  Human_Resources
GROUP BY age_group
ORDER BY age_group;


SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, gender,
  COUNT(*) AS count
FROM 
 Human_Resources
WHERE 
  age >= 18
GROUP BY age_group, gender
ORDER BY age_group, gender;


-- 4. How many employees work at headquarters versus remote locations?
select location ,count(*) as employee_numbers
from Human_Resources
group by location

-- 5. What is the average length of employment for employees who have been terminated?
-- 离职的人的平均工作年限

with tmp1 as
(select emp_id,first_name,last_name,hire_date,termdate,datediff(termdate,hire_date) as working_days
from Human_Resources
where termdate <= curdate()
)
select 
avg(working_days) as average_length_days, round(avg(working_days) /365,2) as average_length_years
from tmp1

-- 6. How does the gender distribution vary across departments and job titles?
select gender,department,jobtitle,count(*) as employee_numbers
from Human_Resources
group by gender,department,jobtitle
order by gender,department,jobtitle

-- 7. What is the distribution of job titles across the company?
select jobtitle,count(*) as employee_numbers
from Human_Resources
group by jobtitle
order by employee_numbers desc

-- 8. Which department has the highest turnover rate?
--  下面这段你自己的其实嵌套多了哦，sum 其实可以和case when 结合起来的！会简捷一些的！
with tmp1 as
(select *,
		case
		when termdate <= curdate() then '1' 
		else '0'
		end as leave_mark
from Human_Resources
),
tmp2 as 
(
select department,sum(leave_mark) as total_leaves,count(emp_id) as total_employees
from tmp1
group by department
)
select 
department,round((total_leaves/total_employees)*100,4) as turnover_rate
from tmp2
order by turnover_rate desc



SELECT department, COUNT(*) as total_count, 
    SUM(CASE WHEN termdate <= CURDATE()  THEN 1 ELSE 0 END) as terminated_count, 
    SUM(CASE WHEN termdate > CURDATE() THEN 1 ELSE 0 END) as active_count,
    round((SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END) / COUNT(*))*100,2) as termination_rate
FROM Human_Resources
GROUP BY department
ORDER BY termination_rate DESC;





-- 9. What is the distribution of employees across locations by city and state?
select location_state,location_city,count(*) as employee_numbers
from Human_Resources
group by location_state,location_city
order by location_state,location_city,employee_numbers desc

-- 10. How has the company's employee count changed over time based on hire and term dates?
-- 这个 SQL 查询旨在分析公司在不同时间的员工数量变化，基于员工的入职日期和离职日期。
-- 我自己写的这个-1，1这个代码。会有一个问题，那就是将招聘日期和辞职日期结合之后，就会有招聘日期是停留在2020年，而离职日期还会有2024年2027年...之类的
-- 那就会导致截止到2024年11 月7 日也就是我查询的今天，会出现后面的2020 2021 2022 2023 2024直邮流出没有流入
-- 那我就加个条件嘛where 筛选一下时间
	with tmp1 as 
	(
	select hire_date as date, 1 as change_mark
	from Human_Resources
	union all
	select termdate, -1 as change_mark
	from Human_Resources
	where termdate <= curdate()
	) 
	select year(date),sum(change_mark) as annual_change,sum(sum(change_mark)) over(order by year(date) ) as consecutive_employee_numbers
	from tmp1
	where year(date) <= '2020'
	group by year(date)
	ORDER BY year(date);
    
    
    
WITH tmp1 AS (
    SELECT hire_date AS date, 1 AS change_mark
    FROM Human_Resources
    UNION ALL
    SELECT termdate, -1 AS change_mark
    FROM Human_Resources
    WHERE termdate <= CURDATE()
)
SELECT 
    YEAR(date) AS year,
    count(CASE WHEN change_mark = 1 THEN 1 ELSE null END) AS hires,
    count(CASE WHEN change_mark = -1 THEN 1 ELSE null END) AS leaves,
    count(CASE WHEN change_mark = 1 THEN 1 ELSE null END)-count(CASE WHEN change_mark = -1 THEN 1 ELSE null END) as net_change,
 sum(sum(change_mark)) over(order by year(date) ) as consecutive_employee_numbers
 FROM 
    tmp1
GROUP BY 
    YEAR(date)
ORDER BY 
    YEAR(date);
    
    

SELECT 
    YEAR(hire_date) AS year, 
    COUNT(*) AS hires, 
    SUM(CASE WHEN  termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations, 
    COUNT(*) - SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END) AS net_change,
    ROUND(((COUNT(*) - SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END)) / COUNT(*) * 100),2) AS net_change_percent
FROM 
    Human_Resources
GROUP BY 
    YEAR(hire_date)
ORDER BY 
    YEAR(hire_date) ASC;
-- 上面这个做法简直就是大错特错 对于分组后的count作为hires当然是没问题的，terminations的计算方法有问题
-- sum case when那句话统计的是只要比2024年早的离职日期 那就计1 然后加总 ，感觉像是按年加总，实质没有任何分组加总在里面
-- 会统计所有 termdate 小于等于当前日期的离职记录，而不是与 YEAR(hire_date) 对应的 termdate。
-- 对于 2000 年的分组，它会统计 2000 年的 hires 数量。但 SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END) 不会只统计 2000 年的 termdate，而是所有 termdate 小于等于 CURDATE() 的记录。
-- 这个 group by 感觉没有很大的作用

SELECT 
    hire_counts.year AS year,
    hires,
    terminations,
    hires - terminations AS net_change,
    ROUND((terminations) / (terminations+hires) * 100, 2) AS termination_rate -- 离职率一直在上升哦 随着年份推进
FROM (
    SELECT 
        YEAR(hire_date) AS year,
        COUNT(*) AS hires
    FROM Human_Resources
    GROUP BY YEAR(hire_date)
) AS hire_counts                 -- 每一年的招聘人数
LEFT JOIN (
    SELECT 
        YEAR(termdate) AS year,
        COUNT(*) AS terminations
    FROM Human_Resources
    WHERE termdate <= CURDATE()   -- 条件是必须是离职人员 所以离职日期一定要有效的 不能是9999那种 所以加上条件
    GROUP BY YEAR(termdate)    -- 每一年的离职人数
) AS termination_counts
ON hire_counts.year = termination_counts.year    -- 连接。年份相同的。因为我统计的是每一年的招聘入职人数和离职走掉的人数
ORDER BY year ASC;

-- 11. What is the tenure distribution for each department?
-- 任期的分布，如果是离职了，那就是离职-聘用日期，如果还没离职，那么离职日期就设定为今天好了，那就是一直工作到今天，工了几年就是几年嘛
with tmp1 as 
(SELECT 
        department,
        (DATEDIFF(
        case when termdate > curdate() then curdate()
        else termdate 
        end,
         hire_date) ) as tenure_days
    FROM 
        Human_Resources
)
select department,min(tenure_days),max(tenure_days),avg(tenure_days),min(tenure_days)/365,max(tenure_days)/365,avg(tenure_days)/365
from tmp1
group by department
order by department




