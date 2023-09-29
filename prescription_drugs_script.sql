-- Just messing around to get used to things:
SELECT *
FROM prescriber as pre INNER JOIN zip_fips as z ON pre.nppes_provider_zip5 = z.zip
ORDER BY z.zip;



-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- Bruce Pendley, npi 1881634483, had a total of 99,707 claims.

SELECT npi, SUM(total_claim_count) AS total_claims 
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
-- Bruce Pendley, specialist in family practice, had a total of 99,707 claims.

SELECT pre1.npi, SUM(total_claim_count) AS total_claims, nppes_provider_first_name, 
	   nppes_provider_last_org_name, specialty_description
FROM prescriber AS pre1 INNER JOIN prescription AS pre2 USING (npi)
GROUP BY npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY total_claims DESC;



-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
-- Family practice has the most at 9,752,347

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

--    b. Which specialty had the most total number of claims for opioids?
-- Nurse Practitioner at 900,845 claims

SELECT specialty_description, SUM(total_claim_count) AS tot_op_claim
FROM drug INNER JOIN prescription USING (drug_name)
		  INNER JOIN prescriber   USING (npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY tot_op_claim DESC;

--    c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
-- Yes! There are 15 specialties without any prescriptions

SELECT specialty_description, COUNT(drug_name) AS drug_count
FROM prescriber FULL JOIN prescription USING (npi)
GROUP BY specialty_description
HAVING COUNT(drug_name) = 0;

--    d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
-- The top 3 are Case Manager/Care Coordinator, Orthopedic Surgery, and Interventional Pain Management

SELECT specialty_description,
	   COALESCE (tot_claim,    0) AS tot_claim, 							   -- replaces NULLS with 0
	   COALESCE (tot_op_claim, 0) AS tot_op_claim,							   -- replaces NULLS with 0
	   COALESCE (ROUND((tot_op_claim / tot_claim) * 100, 3), 0) AS op_percent  -- replaces NULLS with 0
	   
FROM (SELECT specialty_description, SUM(total_claim_count) AS tot_claim
	  FROM prescriber FULL JOIN prescription USING (npi)
	  GROUP BY specialty_description
	  ORDER BY tot_claim DESC
	 ) AS tot_claims -- table gives total claims per specialty (includes all specialties)
	  
	  FULL JOIN
	  
	 (SELECT specialty_description, SUM(total_claim_count) AS tot_op_claim
	  FROM prescriber FULL JOIN prescription USING (npi)
			     	 INNER JOIN     drug     USING (drug_name)
	  WHERE opioid_drug_flag = 'Y'
	  GROUP BY specialty_description
	 ) AS op_claims -- table gives total opioid claims per specialty (does NOT inculde all specialties)
	  
	  USING (specialty_description)
	  
ORDER BY op_percent DESC, tot_claim DESC;



-- 3. a. Which drug (generic_name) had the highest total drug cost?
-- Pirfenidone had the highest cost at $2,829,174.30 and Asfotase Alfa had the highest average cost at $1,890,733.05

SELECT generic_name, total_drug_cost::money
FROM drug INNER JOIN prescription USING (drug_name)
ORDER BY total_drug_cost DESC;

	-- Average cost per generic_name:

SELECT generic_name, AVG(total_drug_cost)::money AS avg_drug_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY avg_drug_cost DESC;

--    b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
-- Immun Glob G(IGG)/GLY/IGA OV50 has the highest cost per day at $7,141.11 while C1 Esterase Inhibitor is the priciest by generic name.

SELECT generic_name, (total_drug_cost / total_day_supply)::money AS cost_per_day
FROM drug INNER JOIN prescription AS pre USING (drug_name)
ORDER BY cost_per_day DESC;

	-- Average cost per day based on generic_name:

SELECT generic_name,
	   AVG(total_drug_cost / total_day_supply)::money AS cost_per_day
FROM drug INNER JOIN prescription AS pre USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;



-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs 
-- which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
	   CASE WHEN   opioid_drug_flag   = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ElSE 'neither' END AS drug_type
FROM drug;

--    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
-- Opioids cost more at $105,080,626.37 compared to antibiotics costing $38,435,121.26

SELECT 
	   CASE WHEN   opioid_drug_flag   = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ElSE 'neither' END AS drug_type,
	   SUM(total_drug_cost)::money AS tot_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY drug_type;



-- 5. a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
-- 56

SELECT COUNT(*) AS total_tn_cbsa
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
-- Nashville-Davidson-Murfreesboro-Franklin,TN has the highest at 1,830,410 while Morristown, TN has the lowest at 116,352.

SELECT cbsaname, SUM(population) AS total_pop
FROM population INNER JOIN cbsa USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop;

--    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
-- Sevier county has the highest with 95,523

SELECT county, population
FROM population AS pop FULL JOIN     cbsa    USING (fipscounty)
					  INNER JOIN fips_county USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;



-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000
ORDER BY total_claim_count;

--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'Y'
	   		ELSE 'N' END AS opioid_flag
FROM prescription INNER JOIN drug USING (drug_name)
WHERE total_claim_count > 3000
ORDER BY total_claim_count;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug_name, total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'Y'
	   		ELSE 'N' END AS opioid_flag,
	   nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_full_name -- || is a shorthand for concat
FROM prescription INNER JOIN    drug    USING (drug_name)
				  INNER JOIN prescriber USING (npi)
WHERE total_claim_count > 3000
ORDER BY total_claim_count;



-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') ***Management is spelled incorrectly***
--	  in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: 
--	  Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi.npi, drug_name
FROM (SELECT npi
	  FROM prescriber
	  WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	 ) AS npi
	  
	  CROSS JOIN

	 (SELECT drug_name
	  FROM drug
	  WHERE opioid_drug_flag = 'Y'
	 ) AS drug_name;

--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber 
--    had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT npi.npi, drug_name, SUM(total_claim_count) AS tot_claim_from_npi 
FROM (SELECT npi
	  FROM prescriber
	  WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	 ) AS npi
	  
	  CROSS JOIN
	  
	 (SELECT drug_name
	  FROM drug
	  WHERE opioid_drug_flag = 'Y'
	 ) AS drug_name
	  
	  LEFT JOIN
	  
	  prescription USING (drug_name, npi)

GROUP BY npi.npi, drug_name, total_claim_count
ORDER BY tot_claim_from_npi;

--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
-- *** parts commented out are for finding the name of each prescriber ***

SELECT npi.npi, drug_name,
	   COALESCE (SUM(total_claim_count), 0) AS tot_claim_from_npi --,
	   --nppes_provider_first_name || ' ' || nppes_provider_last_org_name AS provider_full_name
FROM (SELECT npi
	  FROM prescriber
	  WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	 ) AS npi
	  
	  CROSS JOIN
	  
	 (SELECT drug_name
	  FROM drug
	  WHERE opioid_drug_flag = 'Y'
	 ) AS drug_name
	  
	  LEFT JOIN
	  
	  prescription USING (drug_name, npi)
	  
	  -- LEFT JOIN prescriber USING(npi)

GROUP BY npi.npi, drug_name, total_claim_count --, nppes_provider_first_name || ' ' || nppes_provider_last_org_name
ORDER BY tot_claim_from_npi DESC;

