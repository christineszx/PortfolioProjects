Select *
From CovidDeaths_UPDATED
WHERE continent <> ' '
order by 3,4

--Select *
--From CovidVaccinations_UPDATED
--order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths_UPDATED
order by 1,2


-- Total diagnosed cases vs Total deaths (Mortality rate from Covid-19)
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_deaths INT;

ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_cases INT;

SELECT 
    location, date, total_cases, total_deaths 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_deaths * 100.0) / total_cases
    END AS death_rate_percentage
FROM 
    CovidDeaths_UPDATED
WHERE LOCATION
	like '%singapore%'
	--adjust as preferred 
ORDER BY 
    location, 
    date;

-- Looking at total cases vs population
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_deaths INT;
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN population BIGINT;

SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_cases* 100.00)/population 
    END AS infection_rate_percentage
FROM 
    CovidDeaths_UPDATED
WHERE location like '%singapore%' or location like '%china%' or location like '%states%'

-- countries with highest infection rate compared to population
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_cases INT;
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN population BIGINT;

SELECT 
    location, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(population) AS population,
    CASE 
		WHEN MAX(total_cases) = 0 or MAX(population) = 0 THEN 0
        ELSE MAX(total_cases * 100.00)/MAX(population)
	END AS PercentPopulationInfected
FROM 
    CovidDeaths_UPDATED
Group by location, population
order by PercentPopulationInfected DESC;

-- Countries with highest death rate per population
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_deaths INT;
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN population BIGINT;

SELECT 
    location, 
    MAX(total_deaths) AS HighestDeathCount, 
    MAX(population) AS population,
    CASE 
		WHEN MAX(total_deaths) = 0 or MAX(population) = 0 THEN 0
        ELSE MAX(total_deaths * 100.00)/MAX(population)
	END AS PercentPopulationDied
FROM 
    CovidDeaths_UPDATED
WHERE continent <> ' '
Group by location
order by PercentPopulationDied DESC;

--Breaking down COVID-19 cases by Continent
	--Note: Useful for drilling down to details in Tableau
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN total_deaths INT;

SELECT 
    location, 
    MAX(total_deaths) AS HighestDeathCount
FROM CovidDeaths_UPDATED
WHERE continent = ' '
Group by location
order by HighestDeathCount DESC;

--Global Stats Per Day
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN new_cases INT;
ALTER TABLE CovidDeaths_UPDATED
ALTER COLUMN new_deaths INT;

SELECT date, SUM(new_cases) AS New_TotalCases_Day, SUM(new_deaths) AS New_TotalDeaths_Day,
	CASE
		WHEN SUM(new_cases)=0 OR SUM(new_deaths)=0 THEN 0
		ELSE (SUM(new_deaths)*100.00)/SUM(new_cases)
	END AS New_death_percentage 
FROM CovidDeaths_UPDATED
WHERE continent <> ' '	--adjust as preferred, can change to filter by continent if necessary 
Group by date
HAVING SUM(new_cases) <>0
ORDER BY date DESC;

--Relationship between population and total vaccination

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.total_vaccinations
FROM CovidDeaths_UPDATED Dea
JOIN CovidVaccinations_UPDATED Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent <>' '
ORDER BY 1,2,3;

--Relationship between population and perday vaccination
	-- Noting down differences (addtn, subtr etc)
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CAST(Vac.new_vaccinations AS INT)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingCount_NewVac_Day
--, (RollingCount_NewVac_Day/Dea.population)*100
FROM CovidDeaths_UPDATED Dea
JOIN CovidVaccinations_UPDATED Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent <>' '
ORDER BY 2,3;


-- USE CTE 
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingCount_NewVac_Day)
AS 
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CAST(Vac.new_vaccinations AS INT)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingCount_NewVac_Day
--, (RollingCount_NewVac_Day/Dea.population)*100
FROM CovidDeaths_UPDATED Dea
JOIN CovidVaccinations_UPDATED Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent <>' '
)
--ORDER BY 2,3;
SELECT *, (RollingCount_NewVac_Day/population)*100 FROM PopvsVac;



-- TEMP TABLE
	--DROP TABLE IF exists #PercentPopVac
CREATE TABLE #PercentPopVac
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingCount_NewVac_Day numeric
)

INSERT INTO  #PercentPopVac
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(CAST(Vac.new_vaccinations AS INT)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingCount_NewVac_Day
, (SUM(CAST(Vac.new_vaccinations AS INT)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)/Dea.population)*100 AS PercentPopVac
FROM CovidDeaths_UPDATED Dea
JOIN CovidVaccinations_UPDATED Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent <>' ';

SELECT * FROM #PercentPopVac;

-- Views for storing data during visualisation
CREATE VIEW PopvsVac AS
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.total_vaccinations
FROM CovidDeaths_UPDATED Dea
JOIN CovidVaccinations_UPDATED Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent <>' '
--ORDER BY 1,2,3;

SELECT *
FROM PopvsVac
