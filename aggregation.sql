CREATE TABLE IF NOT EXISTS departments (
    filial_id int8,
    department_id int8,
    dep_chif_id int8
);


CREATE TABLE IF NOT EXISTS items (
    id text,
    name text,
    price int8,
    sdate timestamp,
    edate timestamp,
    is_actual int8
);


CREATE TABLE IF NOT EXISTS sales (
    sale_date timestamp,
    salesman_id int8,
    item_id text,
    quantity int8,
    final_price int8
);


CREATE TABLE IF NOT EXISTS sellers (
    id int8,
    fio text,
    department_id int8
);


CREATE TABLE IF NOT EXISTS services (
	id text,
	name text,
	price int8,
	sdate timestamp,
	edate timestamp,
	is_actual int8
);


WITH T AS (
	SELECT
		sales.salesman_id,
		sales.final_price,
		DATE_PART('year',
			sales.sale_date) AS year_num,
		DATE_PART('month',
			sales.sale_date) AS month_num,
		DATE_PART('week',
			sales.sale_date) AS week_num,
		sales.final_price - tmp1.price * sales.quantity AS margin,
		100 * (1 - CAST(tmp1.price * sales.quantity AS FLOAT) / CAST(sales.final_price AS FLOAT)) AS margin_percentage
	FROM
		sales
		JOIN (
			SELECT
				*
			FROM
				services
		UNION
		SELECT
			*
		FROM
			items) tmp1 ON (tmp1.id = sales.item_id
			AND sales.sale_date BETWEEN tmp1.sdate
			AND tmp1.edate)
)
SELECT
	period_type,
	TO_DATE(CONCAT(CAST(year_num AS TEXT), CAST(period_num AS TEXT)), CASE WHEN period_type = 'week' THEN
			'yyyyww'
		WHEN period_type = 'month' THEN
			'yyyymm'
		END) AS start_date,
	TO_DATE(CONCAT(CAST(year_num AS TEXT), CAST(period_num AS TEXT)), CASE WHEN period_type = 'week' THEN
			'yyyyww'
		WHEN period_type = 'month' THEN
			'yyyymm'
		END) + CASE WHEN period_type = 'week' THEN
		INTERVAL '7 days'
	WHEN period_type = 'month' THEN
		INTERVAL '1 month'
	END AS end_date,
	fio AS salesman_fio,
	chif_fio,
	sales_count,
	sales_sum,
	max_overcharge_item,
	max_overcharge_percent
FROM (
	SELECT
		'week' AS period_type,
		salesman_id,
		year_num,
		week_num AS period_num,
		COUNT(*) AS sales_count,
		SUM(final_price) AS sales_sum,
		MAX(margin) AS max_overcharge_item,
		MAX(margin_percentage) AS max_overcharge_percent
	FROM
		T
	GROUP BY
		year_num,
		period_num,
		salesman_id
	UNION
	SELECT
		'month' AS period_type,
		salesman_id,
		year_num,
		month_num AS period_num,
		COUNT(*) AS sales_count,
		SUM(final_price) AS sales_sum,
		MAX(margin) AS max_overcharge_item,
		MAX(margin_percentage) AS max_overcharge_percent
	FROM
		T
	GROUP BY
		year_num,
		period_num,
		salesman_id) AS tmp3
	JOIN (
		SELECT
			s1.id,
			s1.fio,
			s2.id AS chif_id,
			s2.fio AS chif_fio
		FROM
			sellers s1
			LEFT JOIN departments d ON s1.department_id = d.department_id
			LEFT JOIN sellers s2 ON d.dep_chif_id = s2.id) AS tmp4 ON tmp3.salesman_id = tmp4.id
ORDER BY
	salesman_fio,
	start_date;
