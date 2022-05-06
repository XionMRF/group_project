--- Соц.-демо выполнила Кристина
WITH soc_demo AS (
SELECT 
	cl.client_id,  
	COALESCE (TO_CHAR (TO_DATE(birth_dt, 'DDMONYYYY:HH24:MI:SS', 'NLS_DATE_LANGUAGE = American')), 'Íåò äàííûõ') AS birth_dt,
	COALESCE (FLOOR (MONTHS_BETWEEN ('2021-12-01',TO_DATE (birth_dt, 'DDMONYYYY:HH24:MI:SS', 'NLS_DATE_LANGUAGE = American'))/12),0) AS age, 
	COALESCE(cl.region_code,0) AS region_code, ad.region||
	(CASE 
		WHEN ad.region_type IS NOT NULL 
		THEN ' '||ad.region_type 
		ELSE ',' 
	END)||
	(CASE 
		WHEN ad.district IS NOT NULL 
		THEN ', '||ad.district 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad.district_type IS NOT NULL 
		THEN ' '||ad.district_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad.city_type IS NOT NULL 
		THEN ', '||ad.city_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad.city IS NOT NULL 
		THEN ' '||ad.city 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad.town_type IS NOT NULL 
		THEN ', '||ad.town_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad.town IS NOT NULL 
		THEN ' '||ad.town 
		ELSE '' 
		END) AS reg_addr, 
    ad2.region||
	(CASE 
		WHEN ad2.region_type IS NOT NULL 
		THEN ' '||ad2.region_type 
		ELSE ',' 
	END)||
	(CASE 
		WHEN ad2.district IS NOT NULL 
		THEN ', '||ad2.district 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad2.district_type IS NOT NULL 
		THEN ' '||ad2.district_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad2.city_type IS NOT NULL 
		THEN ', '||ad2.city_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad2.city IS NOT NULL 
		THEN ' '||ad2.city 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad2.town_type IS NOT NULL 
		THEN ', '||ad2.town_type 
		ELSE '' 
	END)||
	(CASE 
		WHEN ad2.town IS NOT NULL 
		THEN ' '||ad2.town 
		ELSE '' 
	END) AS fact_addr,
	COALESCE(gen.gender_nm,'Íåò äàííûõ') AS gender_nm, 
	COALESCE(edu.level_nm,'Íåò äàííûõ') AS education_level_nm,
	COALESCE(fam.status_nm,'Íåò äàííûõ') AS family_status_nm,
	COALESCE(cl.fullseniority_year_cnt,0) AS fullseniority_year_cnt,
	COALESCE(ROUND(cl.fullseniority_year_cnt/
					FLOOR (MONTHS_BETWEEN ('2021-12-01',
							TO_DATE(birth_dt, 'DDMONYYYY:HH24:MI:SS', 'NLS_DATE_LANGUAGE = American'))/12),
					2),
			0) AS work_part_of_life_pct,
	COALESCE(cl.staff_flg,'0') AS staff_flg,
	EXTRACT(YEAR FROM DATE '2021-12-01') - cl.name_change_year AS last_nm_change_year_cnt
FROM de_common.group_dim_client cl
LEFT JOIN de_common.group_dim_client_address ad
ON cl.client_id = ad.client_id
LEFT JOIN de_common.group_dict_address_type adt
ON ad.addr_type = adt.address_code
LEFT JOIN de_common.group_dim_client_address ad2
ON ad.client_id = ad2.client_id
LEFT JOIN de_common.group_dict_address_type adt2
ON ad2.addr_type = adt2.address_code
LEFT JOIN de_common.group_dict_gender gen
ON cl.gender_code = gen.gender_code
LEFT JOIN de_common.group_dict_education_level edu 
ON cl.education_level_code = edu.level_code
LEFT JOIN de_common.group_dict_family_status fam
ON cl.family_status_code = fam.status_code
WHERE adt.address_nm = 'Àäðåñ ïîñòîÿííîé ðåãèñòðàöèè' 
	  AND adt2.address_nm = 'Ôàêòè÷åñêèé àäðåñ'
),
--- Кредитные заявки выполнил Ильмир
credit_app AS (
SELECT
		client_id,
		COUNT (application_id) AS app_hist_cnt,
		COUNT (CASE 
					WHEN application_date > ADD_MONTHS('01.12.21',-6) 
					THEN application_date 
			  END) AS app_6m_cnt,
		COUNT (CASE 
					WHEN application_date > ADD_MONTHS('01.12.21',-3) 
					THEN application_date
			  END) AS app_3m_cnt,
		SUM (application_SUM_amt) AS app_hist_amt,
		SUM (CASE 
				WHEN application_date > ADD_MONTHS('01.12.21',-6) 
				THEN application_SUM_amt
				ELSE 0
			END) AS app_6m_amt,
		SUM (CASE 
				WHEN application_date > ADD_MONTHS('01.12.21',-3) 
				THEN application_SUM_amt
				ELSE 0
			END) AS app_3m_amt,
		COUNT (CASE 
					WHEN application_date > ADD_MONTHS('01.12.21',-6) 
					AND credit_product_type =6 
					THEN client_id 
			  END) AS mortgage_6m_flg,
		FLOOR (ROUND ((TO_DATE('01.12.21','dd.mm.yy') - MAX(application_date))/30,2)) AS lASt_app_month_cnt
    FROM de_common.group_fct_credit_applications
    WHERE application_date<'2021-12-01'
    GROUP BY client_id
),
--- БКИ и склейку всего кода выполнил Мустафин Рамиль Фаритович 
bki AS (
SELECT
    CLIENT_ID,
        MAX (CASE
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                                                'X'),
                                    1,1) = '5' THEN '120+'
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                                                'X'),
                                    1,1) = '4' THEN '[90-120)'
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                                                'X'),
                                    1,1) = '3' THEN '[60-90)'
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                                                'X'),
                                    1,1) = '2' THEN '[30-60)'
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                                                'X'),
                                    1,1) in ('E', 'A', 'F') THEN '[1-30)'
                WHEN SUBSTR (LPAD (PMT_STRING_84M,
                                    MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'),'MONTH')),
                            'X'),
                                    1,1) in ('X', '0', '1') THEN '0'
            ELSE 'Íåò äàííûõ'
            END) MAX_CUR_DELQ_BUCKET,
        MAX (CASE 
                WHEN REGEXP_LIKE (SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH')),
                                                    'X'), 
                                        1,3), '[EAF]') THEN '[1-30)'          
            ELSE 'Íåò äàííûõ'
            END) AS DELQ_1_30_3M_FLG,
        MAX (CASE 
                WHEN REGEXP_LIKE (SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH')),
                                                    'X'), 
                                        1,6), '[EAF]') THEN '[1-30)'          
            ELSE 'Íåò äàííûõ'
            END) AS DELQ_1_30_6M_FLG,
        MAX (CASE 
                WHEN REGEXP_LIKE (SUBSTR (LPAD (PMT_STRING_84M,
                                                MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH')),
                                                    'X'), 
                                        1,3), '[EAF]') THEN '90+'          
            ELSE 'Íåò äàííûõ'
            END) AS DELQ_90_12M_FLG,
        MIN (CASE 
            WHEN MONTHS_BETWEEN (REPORT_DT, TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH')) < 6 THEN 'Y'
            ELSE 'Íåò äàííûõ'
            END) AS LAST_AGR_LESS6M_FLG,
        MAX (MONTHS_BETWEEN (REPORT_DT,
                            TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH'))) AS FIRST_OPEN_AGR_MONTH_CNT,
        MIN (MONTHS_BETWEEN (REPORT_DT,
                            TRUNC (TO_DATE (OPEN_DT, 'DDMONYYYY:HH24:MI:SS'), 'MONTH'))) AS LAST_OPEN_AGR_MONTH_CNT,
        MAX (CASE 
            WHEN FACT_CLOSE_DT IS NULL THEN MONTHS_BETWEEN (TO_DATE (SUBSTR (PLAN_CLOSE_DT, 4, 6), 'MON-YY'), REPORT_DT)
            ELSE 0 
            END) AS MAX_CLOSE_AGR_NOW_MONTH_CNT,
        SUM (CASE 
            WHEN FACT_CLOSE_DT IS NULL THEN CREDIT_LIMIT_AMT
            ELSE 0 
            END) AS CURRENT_CREDIT_LIMIT_AMT,
        SUM (CASE 
            WHEN FACT_CLOSE_DT IS NULL THEN CURR_BALANCE_AMT
            ELSE 0 
            END) AS CURRENT_CURR_BALANCE_AMT 
FROM DE_COMMON.GROUP_REP_BKI_INFO
GROUP BY CLIENT_ID
),
--- Карточные транзакции выполнил Кирилл
card_tr AS (
SELECT client_id,    
	COALESCE (SUM (CASE 
						WHEN in_out_type = 'OUT' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-30 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_OUT_30D_AMT,
    COALESCE (SUM (CASE 
						WHEN in_out_type = 'OUT' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-90 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_OUT_90D_AMT,
    COALESCE (SUM (CASE
						WHEN in_out_type = 'OUT' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-180 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_OUT_180D_AMT,
    COALESCE (SUM (CASE
						WHEN in_out_type = 'OUT' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-365 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_OUT_365D_AMT,
    COALESCE (SUM (CASE 
						WHEN in_out_type = 'IN' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-30 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_IN_30D_AMT,

    COALESCE (SUM (CASE 
						WHEN in_out_type = 'IN' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-90 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_IN_90D_AMT,

    COALESCE (SUM (CASE 
						WHEN in_out_type = 'IN' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-180 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_IN_180D_AMT,

    COALESCE (SUM (CASE 
						WHEN in_out_type = 'IN' AND transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-365 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END), 
				0) AS TRANS_IN_365D_AMT,

    SUM (CASE 
			WHEN transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-30 
			AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
		END) AS TRANS_ALL_30D_AMT,

    SUM (CASE 
			WHEN transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-90 
			AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
		END) AS TRANS_ALL_90D_AMT,

    SUM (CASE 
			WHEN transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-180 
			AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
		END) AS TRANS_ALL_180D_AMT,

    SUM (CASE 
			WHEN transaction_dt BETWEEN TO_DATE('2021-12-01', 'YYYY-MM-DD')-365 
			AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
		END) AS TRANS_ALL_365D_AMT,

    ROUND (SUM (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
				END)/
				SUM (CASE 
						WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-3) 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END)*3, 
		2) AS LAST_MONTH_TO_AVG3M_SUM_PCT,

    ROUND (SUM (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
				END)/
				SUM (CASE 
						WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-6) 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END)*6,
		2) AS LAST_MONTH_TO_AVG6M_SUM_PCT,

    ROUND (SUM (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
				END)/
				SUM (CASE 
						WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-12) 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END)*12, 
		2) AS LAST_MONTH_TO_AVG12M_SUM_PCT,

    ROUND (SUM (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-3) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
				END)/3/
				SUM (CASE 
						WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-6) 
						AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN trans_amt 
					END)*6, 
		2) AS AVG3M_TO_AVG6M_SUM_PCT,

    ROUND (COUNT (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
				  END)/
				  COUNT (CASE 
							WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-3) 
							AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
						END)*3, 
		2) AS LAST_MONTH_TO_AVG3M_CNT_PCT,

    ROUND (COUNT (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
				  END)/
				  COUNT (CASE 
							WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-6) 
							AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
						END)*6,
		2) AS LAST_MONTH_TO_AVG6M_CNT_PCT,

    ROUND (COUNT (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-1) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
				  END)/
				  COUNT (CASE 
							WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-12) 
							AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
						END)*12, 
		2) AS LAST_MONTH_TO_AVG12M_CNT_PCT,
    ROUND (COUNT (CASE 
					WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-3) 
					AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
				  END)/3/
				  COUNT (CASE 
							WHEN transaction_dt BETWEEN ADD_MONTHS(CAST('2021-12-01' AS DATE),-6) 
							AND TO_DATE('2021-12-01', 'YYYY-MM-DD')-1 THEN transaction_id 
						END)*6, 
		2) AS AVG3M_TO_AVG6M_CNT_PCT
FROM de_common.group_fct_transactions
WHERE oper_result = 'SUCCESS'
GROUP BY client_id
),
--- Зарплатные транзакции выполнил Булат
salary_tr AS (
SELECT
    A.CLIENT_ID,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 11 THEN a.income_SUM_amt END), 0) AS SALARY_1M_AMT,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 10 THEN a.income_SUM_amt END), 0) AS SALARY_2M_AMT,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 9 THEN a.income_SUM_amt END), 0) AS SALARY_3M_AMT,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 8 THEN a.income_SUM_amt END), 0) AS SALARY_4M_AMT,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 7 THEN a.income_SUM_amt END), 0) AS SALARY_5M_AMT,
    COALESCE(SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 6 THEN a.income_SUM_amt END), 0) AS SALARY_6M_AMT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 11 THEN a.income_SUM_amt END), 0) AS SALARY_1M_CNT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 10 THEN a.income_SUM_amt END), 0) AS SALARY_2M_CNT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 9 THEN a.income_SUM_amt END), 0) AS SALARY_3M_CNT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 8 THEN a.income_SUM_amt END), 0) AS SALARY_4M_CNT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 7 THEN a.income_SUM_amt END), 0) AS SALARY_5M_CNT,
    COALESCE(COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 6 THEN a.income_SUM_amt END), 0) AS SALARY_6M_CNT,
    ROUND((SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1 THEN a.income_SUM_amt END) /
        SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 2
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 3
        THEN a.income_SUM_amt END)) * 100, 2) AS SALARY_1M_TO_3M_AMT_PCT,
    ROUND((SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1 THEN a.income_SUM_amt END) /
        SUM(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 2
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 3
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 4
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 5
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 6
        THEN a.income_SUM_amt END)) * 100, 2) AS SALARY_1M_TO_6M_AMT_PCT,
    ROUND((COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1 THEN a.income_SUM_amt END) /
        COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 2
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 3
        THEN a.income_SUM_amt END)) * 100, 2) AS SALARY_1M_TO_3M_CNT_PCT,
    ROUND((COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1 THEN a.income_SUM_amt END) /
        COUNT(CASE WHEN MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 1
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 2
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 3
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 4
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 5
        OR MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), TO_DATE(a.income_month, 'yyyy-mm')) = 6
        THEN a.income_SUM_amt END)) * 100, 2) AS SALARY_1M_TO_6M_CNT_PCT,
    MAX (y.SALARY_DURING_6M_CNT) AS SALARY_DURING_6M_CNT,
    ROUND (MIN(MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), p.lASt_salary)+1), 0) AS LAST_SAL_TRANS_MONTH_CNT,
    MAX (MONTHS_BETWEEN(TO_DATE('2021-12-01', 'yyyy-mm-dd'), p.first_salary)) AS FIRST_SAL_TRANS_MONTH_CNT 
FROM de_common.group_fct_income_transactions a
LEFT JOIN (
        SELECT
            DISTINCT(b.client_id),
            MAX(b.RANK) OVER(PARTITION BY b.client_id ORDER BY b.client_id) AS SALARY_DURING_6M_CNT
        FROM (
                 SELECT
                    z.*,
                    DENSE_RANK() OVER(PARTITION BY client_id ORDER BY income_month) AS RANK
                FROM de_common.group_fct_income_transactions z
                WHERE
                    (income_month = '2021-11' OR
                    income_month = '2021-10' OR
                    income_month = '2021-09' OR
                    income_month = '2021-08' OR
                    income_month = '2021-07' OR
                    income_month = '2021-06')
                    and income_type = '1') b) y
ON y.client_id = a.client_id
LEFT JOIN (SELECT
            DISTINCT(s.client_id),
            TO_DATE (FIRST_VALUE (income_month) OVER(PARTITION BY client_id ORDER BY client_id), 'yyyy-mm') AS first_salary,
            TO_DATE (lAST_VALUE (income_month) OVER(PARTITION BY client_id ORDER BY client_id), 'yyyy-mm') - 5 AS lASt_salary
        FROM de_common.group_fct_income_transactions s) p
ON p.client_id = a.client_id
WHERE a.income_type = '1'
GROUP BY a.client_id
)
SELECT 
                a.CLIENT_ID,
                a.BIRTH_DT,
                a.AGE,
                a.REGION_CODE,
                a.REG_ADDR,
                a.FACT_ADDR,
                a.GENDER_NM,
                a.EDUCATION_LEVEL_NM,
                a.FAMILY_STATUS_NM,
                a.FULLSENIORITY_YEAR_CNT,
                a.WORK_PART_OF_LIFE_PCT,
                a.STAFF_FLG,
                a.LAST_NM_CHANGE_YEAR_CNT,
                NVL (b.APP_HIST_CNT, 0) APP_HIST_CNT,
                NVL (b.APP_6M_CNT, 0) APP_6M_CNT,
                NVL (b.APP_3M_CNT, 0) APP_3M_CNT,
                NVL (b.APP_HIST_AMT, 0) APP_HIST_AMT,
                NVL (b.APP_6M_AMT, 0) APP_6M_AMT,
                NVL (b.APP_3M_AMT, 0) APP_3M_AMT,
                NVL (b.MORTGAGE_6M_FLG, 0) MORTGAGE_6M_FLG,
                NVL (b.LAST_APP_MONTH_CNT, 0) LAST_APP_MONTH_CNT,
                NVL (c.MAX_CUR_DELQ_BUCKET, 0) MAX_CUR_DELQ_BUCKET,
                NVL (c.DELQ_1_30_3M_FLG, 'Íåò äàííûõ') DELQ_1_30_3M_FLG,
                NVL (c.DELQ_1_30_6M_FLG, 'Íåò äàííûõ') DELQ_1_30_6M_FLG,
                NVL (c.DELQ_90_12M_FLG, 'Íåò äàííûõ') DELQ_90_12M_FLG,
                NVL (c.LAST_AGR_LESS6M_FLG, 'Íåò äàííûõ') LAST_AGR_LESS6M_FLG,
                NVL (c.LAST_OPEN_AGR_MONTH_CNT, 0) LAST_OPEN_AGR_MONTH_CNT,
                NVL (c.FIRST_OPEN_AGR_MONTH_CNT, 0) FIRST_OPEN_AGR_MONTH_CNT,
                NVL (c.MAX_CLOSE_AGR_NOW_MONTH_CNT, 0) MAX_CLOSE_AGR_NOW_MONTH_CNT,
                NVL (c.CURRENT_CREDIT_LIMIT_AMT, 0) CURRENT_CREDIT_LIMIT_AMT,
                NVL (c.CURRENT_CURR_BALANCE_AMT, 0) CURRENT_CURR_BALANCE_AMT,
                NVL (d.TRANS_OUT_30D_AMT, 0) TRANS_OUT_30D_AMT,
                NVL (d.TRANS_OUT_90D_AMT, 0) TRANS_OUT_90D_AMT,
                NVL (d.TRANS_OUT_180D_AMT, 0) TRANS_OUT_180D_AMT,
                NVL (d.TRANS_OUT_365D_AMT, 0) TRANS_OUT_365D_AMT,
                NVL (d.TRANS_IN_30D_AMT, 0) TRANS_IN_30D_AMT,
                NVL (d.TRANS_IN_90D_AMT, 0) TRANS_IN_90D_AMT,
                NVL (d.TRANS_IN_180D_AMT, 0) TRANS_IN_180D_AMT,
                NVL (d.TRANS_IN_365D_AMT, 0) TRANS_IN_365D_AMT,
                NVL (d.TRANS_ALL_30D_AMT, 0) TRANS_ALL_30D_AMT,
                NVL (d.TRANS_ALL_90D_AMT, 0) TRANS_ALL_90D_AMT,
                NVL (d.TRANS_ALL_180D_AMT, 0) TRANS_ALL_180D_AMT,
                NVL (d.TRANS_ALL_365D_AMT, 0) TRANS_ALL_365D_AMT,
                NVL (d.LAST_MONTH_TO_AVG3M_SUM_PCT, 0) LAST_MONTH_TO_AVG3M_SUM_PCT,
                NVL (d.LAST_MONTH_TO_AVG6M_SUM_PCT, 0) LAST_MONTH_TO_AVG6M_SUM_PCT,
                NVL (d.LAST_MONTH_TO_AVG12M_SUM_PCT, 0) LAST_MONTH_TO_AVG12M_SUM_PCT,
                NVL (d.AVG3M_TO_AVG6M_SUM_PCT, 0) AVG3M_TO_AVG6M_SUM_PCT,
                NVL (d.LAST_MONTH_TO_AVG3M_CNT_PCT, 0) LAST_MONTH_TO_AVG3M_CNT_PCT,
                NVL (d.LAST_MONTH_TO_AVG6M_CNT_PCT, 0) LAST_MONTH_TO_AVG6M_CNT_PCT,
                NVL (d.LAST_MONTH_TO_AVG12M_CNT_PCT, 0) LAST_MONTH_TO_AVG12M_CNT_PCT,
                NVL (d.AVG3M_TO_AVG6M_CNT_PCT, 0) AVG3M_TO_AVG6M_CNT_PCT,
                NVL (e.SALARY_2M_AMT, 0) SALARY_2M_AMT,
                NVL (e.SALARY_1M_AMT, 0) SALARY_1M_AMT,
                NVL (e.SALARY_3M_AMT, 0) SALARY_3M_AMT,
                NVL (e.SALARY_4M_AMT, 0) SALARY_4M_AMT,
                NVL (e.SALARY_5M_AMT, 0) SALARY_5M_AMT,
                NVL (e.SALARY_6M_AMT, 0) SALARY_6M_AMT,
                NVL (e.SALARY_1M_CNT, 0) SALARY_1M_CNT,
                NVL (e.SALARY_2M_CNT, 0) SALARY_2M_CNT,
                NVL (e.SALARY_3M_CNT, 0) SALARY_3M_CNT,
                NVL (e.SALARY_4M_CNT, 0) SALARY_4M_CNT,
                NVL (e.SALARY_5M_CNT, 0) SALARY_5M_CNT,
                NVL (e.SALARY_6M_CNT, 0) SALARY_6M_CNT,
                NVL (e.SALARY_1M_TO_3M_AMT_PCT, 0) SALARY_1M_TO_3M_AMT_PCT,
                NVL (e.SALARY_1M_TO_6M_AMT_PCT, 0) SALARY_1M_TO_6M_AMT_PCT,
                NVL (e.SALARY_1M_TO_3M_CNT_PCT, 0) SALARY_1M_TO_3M_CNT_PCT,
                NVL (e.SALARY_1M_TO_6M_CNT_PCT, 0) SALARY_1M_TO_6M_CNT_PCT,
                NVL (e.SALARY_DURING_6M_CNT, 0) SALARY_DURING_6M_CNT,
                NVL (e.LAST_SAL_TRANS_MONTH_CNT, 0) LAST_SAL_TRANS_MONTH_CNT,
                NVL (e.FIRST_SAL_TRANS_MONTH_CNT, 0) FIRST_SAL_TRANS_MONTH_CNT
FROM soc_demo a
LEFT JOIN credit_app b
ON a.CLIENT_ID = b.CLIENT_ID
LEFT JOIN bki c
ON a.CLIENT_ID = c.CLIENT_ID
LEFT JOIN card_tr d
ON a.CLIENT_ID = d.CLIENT_ID
LEFT JOIN salary_tr e
ON a.CLIENT_ID = e.CLIENT_ID
