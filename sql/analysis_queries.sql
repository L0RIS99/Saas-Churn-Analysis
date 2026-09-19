# OVERVIEW 
SELECT *
FROM subscriptions
 ; 

SELECT *
FROM monthly_revenue
 ; 
 
 # DATA EXPLORATION 
DESCRIBE subscriptions
; 
#  
SELECT *
FROM subscriptions
WHERE customer_id IS NULL; 
# no null values on customer_id , which confirms that the column NULL in the describe output was just to inform that null values were authorized. 

SELECT DISTINCT churned
FROM subscriptions
;
#this column will be used to do some calculation, so important to make sure we only have 2 outputs,  and not different outputs that says the same things, just written differently. 

# column checks 
SELECT 
    'plan' AS column_name, 
    plan AS value, 
    COUNT(*) AS nb_of_line
FROM subscriptions
GROUP BY plan
UNION ALL
SELECT 
    'billing_cycle' AS column_name, 
    billing_cycle AS value, 
    COUNT(*) AS nb_of_line
FROM subscriptions
GROUP BY billing_cycle
UNION ALL 
SELECT 
    'acquisition_channel' AS column_name, 
    acquisition_channel AS value, 
    COUNT(*) AS nb_of_line
FROM subscriptions
GROUP BY acquisition_channel
UNION ALL 
SELECT 
    'company_size' AS column_name, 
    company_size AS value, 
    COUNT(*) AS nb_of_line
FROM subscriptions
GROUP BY company_size
UNION ALL 
SELECT 
    'region' AS column_name, 
    region AS value, 
    COUNT(*) AS nb_of_line
FROM subscriptions
GROUP BY region ;
#all columns are clean , no 2 different outputs to say the same thing 

# check that when the customer is churned , churned date and churned reason are also populated

SELECT *
FROM subscriptions
WHERE (churned = 'Yes' AND churn_date IS NULL) 
   OR ( churned = 'Yes' AND churn_reason IS NULL );
# no results, so no inconsistencies in the data
SELECT *
FROM subscriptions
WHERE (churned = 'No' AND churn_date IS NOT NULL) 
   OR ( churned = 'No' AND churn_reason IS NOT NULL );
# for the no , we have results, but churn_date and churn_reason are empty, we are going to check if this is populated with empty strings : 
SELECT churn_date, churn_reason, LENGTH(churn_date), LENGTH(churn_reason)
FROM subscriptions
WHERE churned = 'No' AND churn_date IS NOT NULL
;
# confirmed, it is populated by empty strings, not NULL values.

SELECT 'churn_date', COUNT(*)
FROM subscriptions WHERE churn_date IS NULL OR TRIM(churn_date) = ''
UNION ALL
SELECT 'churn_reason', COUNT(*)
FROM subscriptions WHERE churn_reason IS NULL OR TRIM(churn_reason) = '';

# 287 results, which correspond to the number of churned = no , which is consistent. 

# now we need to convert the signup_date and the churn_date into DATE type. 
ALTER TABLE subscriptions ADD COLUMN signup_date_clean DATE;
ALTER TABLE subscriptions ADD COLUMN churn_date_clean DATE;

UPDATE subscriptions
SET signup_date_clean = STR_TO_DATE(signup_date, '%Y-%m-%d');

UPDATE subscriptions
SET churn_date_clean = CASE 
    WHEN TRIM(churn_date) = '' THEN NULL
    ELSE STR_TO_DATE(churn_date, '%Y-%m-%d')
END;
 
DESCRIBE subscriptions ;

SELECT COUNT(*) AS total,
       COUNT(signup_date_clean) AS converties,
       SUM(CASE WHEN signup_date IS NOT NULL AND TRIM(signup_date)<>'' AND signup_date_clean IS NULL THEN 1 ELSE 0 END) AS conversions_ratees
FROM subscriptions;

SELECT COUNT(*) AS total_churned,
       COUNT(churn_date_clean) AS converties,
       SUM(CASE WHEN churn_date IS NOT NULL AND TRIM(churn_date) <> '' AND churn_date_clean IS NULL THEN 1 ELSE 0 END) AS conversions_ratees
FROM subscriptions
WHERE churned = 'Yes';

#all conversions have been made properly now we have two colonnes with the right type 
DESCRIBE monthly_revenue;
SELECT * 
FROM monthly_revenue LIMIT 5;
SELECT COUNT(*) 
FROM monthly_revenue;


SELECT *
FROM subscriptions;

#####
# QUESTION 1 : overall churn rate 


SELECT (SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) / COUNT(*))*100 AS overall_churn_rate
FROM subscriptions;

#overall churned on the last 4 years = 52.17% 

SELECT *
FROM monthly_revenue
 ;
# how the monthly churn rate trended over the past 4 years? Is churn improving or getting worse?
 
SELECT LEFT(month, 4) AS years, AVG(monthly_churn_rate_pct) AS avg_churn
FROM monthly_revenue
GROUP BY LEFT(month, 4)
ORDER BY years;
 
# looks like it is improving as the avg churn per month is getting lower between 2022 and 2024 but looks like it stabilize around 3.5%-3.6% between 2024-2025 . To verify with power BI. 

#####
#QUESTION 2 : highest churn rate per subscription plan & billing cycle on retention 


SELECT plan, (SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) / COUNT(*))*100 AS churn_rate_by_plan, COUNT(*) AS sum_clients
FROM subscriptions
GROUP BY plan; 
# highest churn rate on the starter plan (70%), lowest on the enterprise plan (22%) but with also only 50 clients so it gives us a trend but the number is low so it is needed to be careful on it

SELECT billing_cycle, (SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) / COUNT(*))*100 AS churn_rate_by_cycle, COUNT(*) AS sum_clients
FROM subscriptions
GROUP BY billing_cycle; 

# annual has a churn rate lower : probably more engaged initialy, less opportunity to churn compared to a monthly client. 

#####
# QUESTION 3 : Top 3 reasons customers churn, and do these reasons differ by plan type or company size? 

SELECT churn_reason,  COUNT(*) AS sum_clients
FROM subscriptions
WHERE churned = 'Yes'
GROUP BY churn_reason
ORDER BY sum_clients DESC; 
# 1 budget cuts, 2 price too high, 3 company closed 
WITH churn_reason_cte AS (
SELECT plan, churn_reason, COUNT(*) AS sum_clients
FROM subscriptions
WHERE churned = 'Yes'
GROUP BY plan,churn_reason
ORDER BY sum_clients DESC
)

SELECT 
	plan,
	churn_reason,
    sum_clients,
    RANK() OVER (PARTITION BY plan ORDER BY sum_clients DESC) AS ranked
FROM churn_reason_cte
;
# reason differs depending on the plan : missing features for business, no longer needed for enterprise, price too high / budget cut for professional, price too high for starters. 
# pricing/budget concerns dominate churn on entry-level plans (Starter, Professional), while higher-tier plans churn more due to missing features 
# it suggests that retention strategy should differ by segment: price/value for lower tiers, product depth for higher tiers.

WITH churn_reason_company AS (
SELECT company_size, churn_reason, COUNT(*) AS sum_clients
FROM subscriptions
WHERE churned = 'Yes'
GROUP BY company_size,churn_reason
ORDER BY sum_clients DESC
)

SELECT 
	company_size,
	churn_reason,
    sum_clients,
    RANK() OVER (PARTITION BY company_size ORDER BY sum_clients DESC) AS ranked
FROM churn_reason_company;
# company size 500+: poor Support is the top churn reason, suggesting large accounts expect dedicated, high-touch support that isnt being met. also budget Cuts affects most company sizes fairly evenly.


#####
# Question 4 : CLV by plan, compare to CAC, which plans are most/least profitable?


WITH lifespan AS (
SELECT *,
	TIMESTAMPDIFF(MONTH, signup_date_clean, 
    CASE WHEN churned = 'Yes' THEN churn_date_clean ELSE CURDATE() END
) AS lifespan_months
FROM subscriptions
)

SELECT 
    plan,
    AVG(lifespan_months) AS avg_lifespan_months,
    ROUND(AVG(monthly_revenue), 1) AS avg_monthly_revenue,
    ROUND((AVG(lifespan_months) * ROUND(AVG(monthly_revenue), 1)), 1) AS CLV,
    (SELECT ROUND(AVG(customer_acquisition_cost), 1) FROM monthly_revenue) AS avg_cac,
    ROUND(
        (AVG(lifespan_months) * ROUND(AVG(monthly_revenue), 1)) 
        / (SELECT AVG(customer_acquisition_cost) FROM monthly_revenue)
    , 2) AS clv_cac_ratio
FROM lifespan
GROUP BY plan;

####
# checking the feature usage & for churned and not churned 

SELECT churned, ROUND(AVG(feature_usage_pct), 1) AS avg_feature_usage
FROM subscriptions
GROUP BY churned;
#27.5% for the churned, 55% for the active client, which means we could define a threshold at 35% to flag the active users at risk of churning


SELECT 
    COUNT(*) AS at_risk_customers,
    (SELECT COUNT(*) FROM subscriptions WHERE churned = 'No') AS total_active,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM subscriptions WHERE churned = 'No') * 100, 1) AS pct_at_risk
FROM subscriptions
WHERE churned = 'No' AND feature_usage_pct < 35;
# 67 active users have a % feature usage rate < 35  , so 23.3% of the total active users
