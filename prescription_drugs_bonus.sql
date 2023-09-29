
-- 1.  How many npi numbers appear in the prescriber table but not in the prescription table?
-- 4,458

WITH pre1_names AS (
	SELECT DISTINCT(npi)
	FROM prescriber
),

pre2_names AS (
SELECT DISTINCT(npi)
FROM prescription
)

SELECT COUNT(pre1_names.npi) - COUNT(pre2_names.npi) AS tot_diff
FROM pre1_names FULL JOIN pre2_names USING (npi);



-- 2.  a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS tot_fam_drug_claim
FROM prescriber INNER JOIN prescription AS pre USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY tot_fam_drug_claim DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS tot_cardio_drug_claim
FROM prescriber INNER JOIN prescription AS pre USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY tot_cardio_drug_claim DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for 
--   	  parts a and b into a single query to answer this question.

SELECT generic_name, SUM(total_claim_count) AS tot_drug_claim
FROM prescriber INNER JOIN prescription AS pre USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice' OR specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY tot_drug_claim DESC
LIMIT 5;

	-- Or, in a more convoluted way:

WITH family_practice AS (
	SELECT generic_name, SUM(total_claim_count) AS tot_fam_drug_claim
	FROM prescriber INNER JOIN prescription AS pre USING (npi)
					INNER JOIN drug USING (drug_name)
	WHERE specialty_description = 'Family Practice'
	GROUP BY generic_name
	ORDER BY tot_fam_drug_claim DESC
),

cardio AS (
	SELECT generic_name, SUM(total_claim_count) AS tot_cardio_drug_claim
	FROM prescriber INNER JOIN prescription AS pre USING (npi)
					INNER JOIN drug USING (drug_name)
	WHERE specialty_description = 'Cardiology'
	GROUP BY generic_name
	ORDER BY tot_cardio_drug_claim DESC
)

SELECT generic_name, --tot_fam_drug_claim, tot_cardio_drug_claim,
	   COALESCE(tot_fam_drug_claim,0) + COALESCE(tot_cardio_drug_claim,0) AS tot_drug_claim
FROM family_practice FULL JOIN cardio USING (generic_name)
ORDER BY tot_drug_claim DESC
LIMIT 5;



-- 3.  Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. 
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) 
--		  across all drugs. Report the npi, the total number of claims, and include a column showing the city.

WITH provider_info AS (
	SELECT npi, nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_full_name,
		   nppes_provider_city
	FROM prescriber
)

SELECT npi, SUM(total_claim_count) AS tot_claims, nppes_provider_city, provider_full_name
FROM prescription AS pre INNER JOIN provider_info USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, provider_full_name, nppes_provider_city
ORDER BY tot_claims DESC, provider_full_name
LIMIT 5;

--     b. Now, report the same for Memphis.

WITH provider_info AS (
	SELECT npi, nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_full_name,
		   nppes_provider_city
	FROM prescriber
)

SELECT npi, provider_full_name, SUM(total_claim_count) AS tot_claims, nppes_provider_city
FROM prescription INNER JOIN provider_info USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, provider_full_name, nppes_provider_city
ORDER BY tot_claims DESC, provider_full_name
LIMIT 5;

--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

WITH provider_info AS (
	SELECT npi, nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_full_name,
		   nppes_provider_city
	FROM prescriber),

nash AS (
	SELECT npi, provider_full_name, SUM(total_claim_count) AS tot_claims, nppes_provider_city
	FROM prescription INNER JOIN provider_info USING (npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, provider_full_name, nppes_provider_city
	ORDER BY tot_claims DESC, provider_full_name
	LIMIT 5),

memphis AS (
	SELECT npi, provider_full_name, SUM(total_claim_count) AS tot_claims, nppes_provider_city
	FROM prescription INNER JOIN provider_info USING (npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, provider_full_name, nppes_provider_city
	ORDER BY tot_claims DESC, provider_full_name
	LIMIT 5),

knox AS (
	SELECT npi, provider_full_name, SUM(total_claim_count) AS tot_claims, nppes_provider_city
	FROM prescription INNER JOIN provider_info USING (npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY npi, provider_full_name, nppes_provider_city
	ORDER BY tot_claims DESC, provider_full_name
	LIMIT 5),

chatta AS (
	SELECT npi, provider_full_name, SUM(total_claim_count) AS tot_claims, nppes_provider_city
	FROM prescription INNER JOIN provider_info USING (npi)
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY npi, provider_full_name, nppes_provider_city
	ORDER BY tot_claims DESC, provider_full_name
	LIMIT 5)

SELECT *
FROM nash

UNION

SELECT *
FROM memphis

UNION

SELECT *
FROM knox

UNION

SELECT *
FROM chatta

ORDER BY tot_claims DESC;



-- 4.  Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, SUM(overdose_deaths) AS tot_overdose_deaths
FROM fips_county AS fips INNER JOIN overdose_deaths AS od ON fips.fipscounty::numeric = od.fipscounty
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
						 FROM overdose_deaths)
GROUP BY county
ORDER BY tot_overdose_deaths DESC;



-- 5.  a. Write a query that finds the total population of Tennessee.
-- 6,597,381 	*** You can get this result without joining and a WHERE clause ***

SELECT SUM(population) AS tn_pop
FROM population INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN';

--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--		  its population, and the percentage of the total population of Tennessee that is contained in that county.

WITH tn_pop AS (
	SELECT SUM(population) AS tn_pop
	FROM population INNER JOIN fips_county USING (fipscounty)
	WHERE state = 'TN'
)

SELECT county, population, ROUND((population / tn_pop)*100, 3) AS pop_percent
FROM population INNER JOIN fips_county USING (fipscounty)
				CROSS JOIN tn_pop
ORDER BY pop_percent DESC;

