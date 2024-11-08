
-- 1. 请务必注意要保留原始table,在创建copy 的table上进行操作

-- 2.datagrip导入文件会出现第一行无法被识别为标题行的，所以我们需要掌握修改列名代码，同时删除第一行
ALTER TABLE your_table_name
RENAME COLUMN C1 TO C1,
RENAME COLUMN C2 TO C2,
RENAME COLUMN C3 TO C3,
RENAME COLUMN C4 TO C4;

DELETE FROM your_table_name
LIMIT 1;

-- 3. 在操作代码之前， 请务必注意要对日期格式进行操作，因为大多数文件导入进来的时候日期都是杂乱的，会出现导入是TEXT，而不是DATE的，所以我们需要
-- 用到str_to_date（）,然后用到date_format()进行格式化输出。

-- 4.在 SQL 中，使用特定的日期（如 9999-12-31）来表示“无限”或“未定义”的时间是一种常见的实践。
-- 通常，这样的日期用于指示一个持续到未来的事件，比如某个员工尚未离职、某个合同仍在生效等。

-- 5.擅长熟练使用update 语句
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition1 = condition2;

-- 6.对于随时间变化类型的题目:两个解决思路，举例，以直播间人数为例，公司员工数量也是以一样的道理
-- 6.1. 正负 1 累积加总方法（逐时累加）：

	•	思想：将每次用户进入标记为 +1，每次离开标记为 -1，通过对这些事件进行累积求和，得到一个时间序列上的用户净变化。用窗口函数 SUM() 实现累积加总后，能反映出每个时间点的实时在线人数。
	•	结果：可以找到整个直播过程中，同时在线人数的最大值。例如，如果在某个时刻累积人数达到 200，就表示该时刻有 200 人同时在线。
	•	优点：无需划分时间段，你可以看到整个时间线中用户数量的动态变化，并且能够找到峰值，即最高同时在线人数。
	•	应用场景：适用于分析直播期间的实时用户趋势和最高在线人数。

-- 6.2. 每小时划分统计（时间段分析）：

	•	思想：在每个时间段内统计进入人数和离开人数，然后通过这些值计算出每个时间段的净变化人数。这是通过 JOIN 和 GROUP BY 时间段的方式来实现。
	•	结果：可以看到每个时间段内的用户变化趋势（如每小时的净增长或净减少人数）。这种方法按时间段提供了离散的进出用户统计。
	•	优点：有助于分析每个时间段内用户进出情况，发现用户活跃的时段和用户流失的时间点。
	•	应用场景：适合按时间段查看用户行为，比如用于规划内容发布或用户互动的策略。