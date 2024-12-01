SELECT *
FROM ADMISSION;

---1. REMOVE DUPLICATES
---2. NULL VALUES AND BLANK VALUES
---3. STANDARDISE THE DATA
---4. DATA EXPLORATION

---CREATING A DUPLICATE SET OF DATA TABLE TO PRESERVE THE RAW DATA AS BACKUP

SELECT *
INTO ADM
FROM ADMISSION;


---REMOVING THE DUPLICATES---


---FINDING ALL THE DUPLICATES

SELECT *
FROM ADM;

SELECT *, COUNT(*) AS [NUMBER OF DUPLICATES]
FROM ADM
GROUP BY [Name],[Age],[Gender],[Admission Test Score],[High School Percentage],[City],[Admission Status]
HAVING COUNT(*) > 1;

---CHECKING TO SEE IF THE CODE IS WORKING PROPERLY

SELECT *
FROM ADM
WHERE [Name] = 'ADEEL' AND [Age] = 24.0

SELECT *
FROM ADM
WHERE [Name] = 'AHMED' AND [Age] = 21.0;

---DELETING ALL THE DUPLICATE ROWS USING CTE
 
 WITH DELETEDUPLICATES AS
 (
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY [NAME],
							   	   [AGE],
								   [Gender],
								   [Admission Test Score],
								   [High School Percentage],
								   [City],
								   [Admission Status]
	ORDER BY					   [NAME])
								
	AS							   DUPLICATES
	FROM						   ADM
)
	DELETE FROM DELETEDUPLICATES
	WHERE DUPLICATES > 1;


---REMOVING ALL THE NULL VALUES AND BLANK VALUES---


---FINDING ALL THE BLANK VALUES

SELECT *
FROM ADM
WHERE [Name] = ''
OR [Age] = ''
OR [Gender] = ''
OR [Admission Test Score] = ''
OR [High School Percentage] = ''
OR [City] = ''
OR [Admission Status] = '';

---DELETING ALL THE BLANK AND NULL VAUES
DELETE
FROM ADM
WHERE ([Name]                   IS NULL OR [Name] = '')
OR    ([Age]	                IS NULL OR [Age] = '')
OR	  ([Gender]                 IS NULL OR [Gender] = '')
OR	  ([Admission Test Score]   IS NULL OR [Admission Test Score] = '')
OR	  ([High School Percentage] IS NULL OR [High School Percentage] = '')
OR	  ([City]                   IS NULL OR [City] = '')
OR	  ([Admission Status]       IS NULL OR [Admission Status] = '');


---STANDARDISING THE DATA---


---UPDATING VARCHAR NUMERAL VALUES TO INTERGERS

UPDATE ADM
SET [Age] = CAST(FLOOR(CAST([Age] AS FLOAT)) AS INT)
WHERE TRY_CAST([Age] AS INT) IS NULL AND TRY_CAST([Age] AS FLOAT) IS NOT NULL;

UPDATE ADM
SET [ADMISSION TEST SCORE] = CAST(FLOOR(CAST([ADMISSION TEST SCORE] AS FLOAT)) AS INT)
WHERE TRY_CAST([ADMISSION TEST SCORE] AS INT) IS NULL AND TRY_CAST([ADMISSION TEST SCORE] AS FLOAT) IS NOT NULL;

UPDATE ADM
SET [High School Percentage] = CAST(CAST([High School Percentage] AS FLOAT) AS INT)
WHERE TRY_CAST([High School Percentage] AS INT) IS NULL AND TRY_CAST([High School Percentage] AS FLOAT) IS NOT NULL

---REMOVING ALL THE REDUNDANT ROWS WITH UNREALISTIC DATA

DELETE
FROM ADM
WHERE [Age] <= 0

DELETE
FROM ADM
WHERE [Admission Test Score] < 0

DELETE
FROM ADM
WHERE [High School Percentage] < 0 OR [High School Percentage] > 100

---CLEAN STANDARD DATA

SELECT *
FROM ADM
ORDER BY 6

-----------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------DATA EXPLORATION-------------------------------------------------------------------

---1. WHAT IS THE ACCEPTANCE RATE

SELECT 
    SUM(
		CASE 
			WHEN [Admission Status] = 'accepted' THEN 1 ELSE 0 END) * 100.0
			/ COUNT(*) 
			AS [Acceptance rate]
FROM ADM;

---46%

---2.DOES AGE HAVE AN IMPACT ON ADMISSION STATUS

SELECT age, [Admission Status], COUNT(*) AS COUNT
FROM ADM
GROUP BY age, [Admission Status]
ORDER BY age;

---NO 

---3. DOES THE GENDER OF THE STUDENT HAVE AN IMPACT ON ADMISSION STATUS

SELECT [Gender],COUNT(*) AS COUNT
FROM ADM
GROUP BY [Gender]

SELECT [Gender], [Admission Status], COUNT(*) AS COUNT
FROM ADM
GROUP BY Gender, [Admission Status]
ORDER BY Gender;

---SIGNIFICANTLY MORE FEMALES APPLIED THAN MALE, HOWEVER ADMISSION STATUS DOES NOT DEPEND ON GENDER

---4. DOES THE CITY A STUDENT IS FROM HAVE AN IMPACT ON ADMISSSION STAUS

SELECT [City], [Admission Status], COUNT(*) AS COUNT
FROM ADM
GROUP BY [City], [Admission Status]
ORDER BY [City];
 
--NO

---5. DOES HIGH SCHOOL PERFOMANCE AFFECT ADMISSION TEST PERFOMANCE


WITH Averages AS 
(
    SELECT 
        AVG([High School Percentage]) AS [High school average],
        AVG([Admission Test Score]) AS [ATS average]
    FROM ADM
),
Deviations AS 
(
    SELECT 
        [High school percentage] - 
		(
			SELECT [High school average] 
			FROM Averages
		) 
			AS [High school deviation] ,
        [Admission Test Score] - 
		(
			SELECT [ATS average] 
			FROM Averages) 
			AS [ATS deviation]
    FROM ADM
),
Numerator AS 
(
    SELECT 
        SUM([High school deviation] * [ATS deviation]) AS covariance
    FROM Deviations
),
Denominator AS 
(
    SELECT 
        SQRT(SUM(POWER([High school deviation], 2)) * 
		SUM(POWER([ATS deviation], 2))) 
	AS [STD DEV ADMISSION]
    FROM Deviations
)
SELECT 
    (SELECT covariance FROM Numerator) / (SELECT [STD DEV ADMISSION] FROM Denominator) AS Correlation;

---THE RESULTS SHOW A WEAK NEGATIVE CORRELATION, THIS COULD MEAN THAT THE ADMISSION TEST IS FAIR AND DOESNT DEPEND ON HIGH SCHOOL PERFOMANCE

---6. IS ADMISSION BASED ON HIGH SCHOOL PERFOMANCE OR ADMISSION SCORE

WITH [High school perfomance] AS
(
	SELECT 
		CASE
			WHEN [High School Percentage] >= 0  AND [High School Percentage] < 10 THEN '0-9'
			WHEN [High School Percentage] >= 10 AND [High School Percentage] < 20 THEN '10-19'
			WHEN [High School Percentage] >= 20 AND [High School Percentage] < 30 THEN '20-29'
			WHEN [High School Percentage] >= 30 AND [High School Percentage] < 40 THEN '30-39'
			WHEN [High School Percentage] >= 40 AND [High School Percentage] < 50 THEN '40-49'
			WHEN [High School Percentage] >= 50 AND [High School Percentage] < 60 THEN '50-59'
			WHEN [High School Percentage] >= 60 AND [High School Percentage] < 70 THEN '60-69'
			WHEN [High School Percentage] >= 70 AND [High School Percentage] < 80 THEN '70-79'
			WHEN [High School Percentage] >= 80 AND [High School Percentage] < 90 THEN '80-89'
			ELSE '90-100' END AS [Percentage range],
			[Admission Status]
	FROM ADM
	GROUP BY [High School Percentage],[Admission status]
)
SELECT [Percentage range],[admission status],
	   count(*)
	   AS [count]
FROM [High school perfomance]
GROUP BY [Percentage range],[Admission Status]
ORDER BY [Percentage range];


WITH [Admission score] AS
(
	SELECT 
		CASE
			WHEN [Admission Test Score] >= 0  AND [Admission Test Score] < 10 THEN '0-9'
			WHEN [Admission Test Score] >= 10 AND [Admission Test Score] < 20 THEN '10-19'
			WHEN [Admission Test Score] >= 20 AND [Admission Test Score] < 30 THEN '20-29'
			WHEN [Admission Test Score] >= 30 AND [Admission Test Score] < 40 THEN '30-39'
			WHEN [Admission Test Score] >= 40 AND [Admission Test Score] < 50 THEN '40-49'
			WHEN [Admission Test Score] >= 50 AND [Admission Test Score] < 60 THEN '50-59'
			WHEN [Admission Test Score] >= 60 AND [Admission Test Score] < 70 THEN '60-69'
			WHEN [Admission Test Score] >= 70 AND [Admission Test Score] < 80 THEN '70-79'
			WHEN [Admission Test Score] >= 80 AND [Admission Test Score] < 90 THEN '80-89'
			ELSE '90-100' END AS [ATS range],
			[Admission Status]
	FROM ADM
	GROUP BY [Admission Test Score],[Admission status]
)
SELECT [ATS range],[admission status],
	   count(*)
	   AS [count]
FROM [Admission score]
GROUP BY [ATS range],[Admission Status]
ORDER BY [ATS range];

---ADMISSION DOESNT  DEPEND ON HIGH SCHOOL PERFOMANCE AND ADMISSION TEST SCORE INDIVIDUALLY

/* THEREFORE BECAUSE ADMISSION TEST SCORE AND HIGH SCHOOL PERCENTAGE SHOW WEAK CORRELATION
AND BOTH FACTORS DON'T INDIVIDUALLY AFFECT THE ADMISSION STATUS OF THE STUDENT
THEN THAT MEANS ADMISSION STATUS DEPENDS ON OTHER EXTERNAL FACTORS NOT MENTIONED IN THE DATA */