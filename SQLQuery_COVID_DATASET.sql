
--SELECT * 
--FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE continent IS NOT NULL
--ORDER BY 3, 5


--SELECT * 
--FROM COVID_PORTFOLIO_PROJECT.. COVID_VACCINES
--WHERE continent IS NOT NULL
--ORDER BY 3, 5

-- SELECT THE DATA THAT WE ARE GOING TO BE USING FOR THIS PROJECT

SELECT location, date, total_cases, new_cases, CAST(total_deaths AS INT), population
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE continent IS NOT NULL
ORDER BY 1, 2

-- TOTAL CASES VS TOTAL DEATHS
-- LIKELIHOOD OF DYING DUE TO COVID IN INDIA
SELECT location, date, total_cases, CAST(total_deaths AS INT), (CAST(total_deaths AS INT)/total_cases)*100 AS deathpercentage
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
WHERE location LIKE '%India%'
AND continent IS NOT NULL
ORDER BY 1, 2

-- LOOKING AT TOTAL CASES VS POPULATION
-- SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentpopulaitoninfected
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
-- WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT location, population, MAX(total_cases) AS highestinfectioncount, MAX((total_cases/population))*100 AS percentpopulaitoninfected
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY percentpopulaitoninfected DESC

-- LOOKING AT COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION
SELECT location, MAX(CAST(total_deaths AS INT)) AS totaldeathcount
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totaldeathcount DESC

-- LOOKING AT CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(CAST(total_deaths AS INT)) AS totaldeathcount
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeathcount DESC
-- LOOKS LIKE THE ABOVE GUVES US A WRONG NUMBER

-- LETS TRY THIS
SELECT location AS continents, MAX(CONVERT(INT, total_deaths)) AS totaldeathcount
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE location LIKE '%India%'
WHERE continent IS NULL
GROUP BY location
ORDER BY totaldeathcount DESC
--BUT THIS DATA IS ALSO NOT GIVING US CORRECT INFORMATION ON CONTINENTS WE WILL USE ABOT QUERY
-- MAY BE WE NEED TO REPLACE location WITH continent IN ABOVE ALL QUERIES FOR SELECT AND GROUPBY


-- GLOBAL DATA
-- TOTAL CASES VS TOTAL DEATHS
-- LIKELIHOOD OF DYING DUE TO COVID IN INDIA
SELECT date, SUM(new_cases) AS new_cases, SUM(CONVERT(INT, new_deaths)) AS new_deaths, (SUM(CONVERT(INT, new_deaths))/SUM(new_cases))*100 AS deathpercentage
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- GLOBAL DATA
-- TOTAL CASES VS TOTAL DEATHS
SELECT SUM(new_cases) AS new_cases, SUM(CAST(new_deaths AS INT)) AS new_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS deathpercentage
FROM COVID_PORTFOLIO_PROJECT.. COVID_DEATHS
WHERE continent IS NOT NULL
ORDER BY 1, 2

--WORKING WITH VACCINATION TABLES
-- PERFORM JOINS
SELECT *
FROM COVID_PORTFOLIO_PROJECT..COVID_DEATHS AS deaths
JOIN COVID_PORTFOLIO_PROJECT..COVID_VACCINES AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date


-- TOTAL POPULATION VS VACCINATIONS
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations,
SUM(CONVERT(BIGINT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingcount 
FROM COVID_PORTFOLIO_PROJECT..COVID_DEATHS AS deaths
JOIN COVID_PORTFOLIO_PROJECT..COVID_VACCINES AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3
-- In the above query when using INT in converting new_vaccines it is showing error so use BIGINT

--USING CTE
WITH populationvsvaccines (continent, location, date, population, new_vaccinations, rollingcount)
AS
(SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations
, SUM(CONVERT(BIGINT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingcount 
FROM COVID_PORTFOLIO_PROJECT..COVID_DEATHS AS deaths
JOIN COVID_PORTFOLIO_PROJECT..COVID_VACCINES AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rollingcount/population)*100 AS percentagevaccinated
FROM populationvsvaccines

-- TEMP TABLE WITH PARTITION ON TH ABOVE QUERY

DROP TABLE IF EXISTS percentpopulationvaccinated
CREATE TABLE percentpopulationvaccinated
(
continent VARCHAR(255),
location VARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
rollingcount NUMERIC
)

INSERT INTO percentpopulationvaccinated
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations
, SUM(CONVERT(BIGINT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingcount 
FROM COVID_PORTFOLIO_PROJECT..COVID_DEATHS AS deaths
JOIN COVID_PORTFOLIO_PROJECT..COVID_VACCINES AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rollingcount/population)*100 AS percentagevaccinated
FROM percentpopulationvaccinated

--CREATE A VIEW TO STOTE DATA FOR THE LATER USE IN VISUALIZATION

USE COVID_PORTFOLIO_PROJECT;   
GO 
CREATE VIEW percentpopulationvaccinated 
AS
SELECT deaths.continent,deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations
, SUM(CONVERT(BIGINT, vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingcount 
FROM COVID_PORTFOLIO_PROJECT..COVID_DEATHS AS deaths
JOIN COVID_PORTFOLIO_PROJECT..COVID_VACCINES AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3
GO

-- Query the view  
SELECT* 
FROM percentpopulationvaccinated
ORDER BY 2,3

-- DROP VIEW
--DROP VIEW percentpopulationvaccinated