#--------------------------------------------------- 1 Task --------------------------------------------------------------
SELECT t.ID_client,
	COUNT(*) AS total_operations,
	ROUND(SUM(t.Sum_payment) / COUNT(*), 2) AS avg_check,
	ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_monthly_total
FROM (
    SELECT ID_client, date_new, Sum_payment
	FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
  ) t
JOIN (
    SELECT ID_client
	FROM (
		SELECT ID_client, COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS months
        FROM transactions
        WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
        GROUP BY ID_client
    ) AS monthly
    WHERE months = 12
) active ON t.ID_client = active.ID_client
GROUP BY t.ID_client
ORDER BY total_operations DESC;

#--------------------------------------------------- 2 Task --------------------------------------------------------------
#-------a---------
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month,
	ROUND(AVG(Sum_payment), 2) AS avg_check
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;
#-------b---------
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month,
	COUNT(*) AS total_operations
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;
#-------c---------
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, 
	COUNT(DISTINCT ID_client) AS avg_clients
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;
#-------d---------
WITH monthly AS (
	SELECT
		DATE_FORMAT(date_new, '%Y-%m') AS month,
		COUNT(*) AS monthly_ops,
		SUM(Sum_payment) AS monthly_sum
	FROM transactions
	WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
	GROUP BY month
),
yearly AS (
	SELECT
		COUNT(*) AS total_ops,
		SUM(Sum_payment) AS total_sum
	FROM transactions
	WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
)
SELECT
	m.month,
	m.monthly_ops,
    y.total_ops,
	m.monthly_sum,
    y.total_sum,
	ROUND(m.monthly_ops / y.total_ops * 100, 2) AS ops_percent,
	ROUND(m.monthly_sum / y.total_sum * 100, 2) AS sum_percent
FROM monthly m
JOIN yearly y ON 1=1
ORDER BY m.month;
#-------e---------
SELECT DATE_FORMAT(t.date_new, '%Y-%m') AS month,
	c.Gender,
	COUNT(DISTINCT t.ID_client) AS count,
	ROUND(SUM(t.Sum_payment), 2) AS gender_sum
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month, c.Gender
ORDER BY month, count;

#--------------------------------------------------- 3 Task --------------------------------------------------------------
WITH transactions_age_group AS (
	SELECT
		t.ID_client,
		t.Sum_payment,
		t.date_new,
    CASE
		WHEN c.Age IS NULL THEN 'No Age Info'
		WHEN c.Age >= 90 THEN '90+'
		ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
    END AS age_group
	FROM transactions t
	LEFT JOIN customers c ON t.ID_client = c.Id_client
	WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
),

yearly_totals AS (
	SELECT age_group,
		COUNT(*) AS total_operations,
		ROUND(SUM(Sum_payment), 2) AS total_sum,
        COUNT(DISTINCT ID_client) as total_client
	FROM transactions_age_group
	GROUP BY age_group
),

quarterly_data AS (
	SELECT age_group,
		CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter,
		ROUND(AVG(Sum_payment), 2) AS avg_payment,
		COUNT(DISTINCT ID_client) AS client_count,
		COUNT(*) AS ops_count,
		SUM(Sum_payment) AS sum_payment
	FROM transactions_age_group
	GROUP BY age_group, quarter
),

quarter_totals AS (
	SELECT CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter,
		COUNT(*) AS total_ops_q,
		SUM(Sum_payment) AS total_sum_q
	FROM transactions_age_group
	GROUP BY quarter
)

SELECT y.age_group, y.total_operations, y.total_client, y.total_sum,
	q.quarter, q.avg_payment, q.sum_payment, q.client_count, q.ops_count,
	ROUND(q.ops_count / qt.total_ops_q * 100, 2) AS ops_percent_in_quarter,
	ROUND(q.sum_payment / qt.total_sum_q * 100, 2) AS sum_percent_in_quarter
FROM yearly_totals y
LEFT JOIN quarterly_data q ON y.age_group = q.age_group
LEFT JOIN quarter_totals qt ON q.quarter = qt.quarter
ORDER BY y.age_group, q.quarter;