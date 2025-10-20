-- Importing tables CovidDeaths & CovidVaccs from Excel into SQL --
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Table imports worked! --

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs. total deaths --
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at the percentage of population who got Covid in the US -- 
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Which countries have the highest infection rates? --
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 
   AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC -- 4 means PercentPopInfected 

-- Looking at countries with highest death count per population --
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC --US had the most deaths 

-- Looking at deaths by continents -- 
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC --North America had the most deaths, but only pulling US numbers

-- Looking at deaths by continents, but changing the code a bit for potential precision --
SELECT continent, SUM(cast(new_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC 

-- Showing continents with the highest death count per population --
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers --
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, 
   SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentageInTheWorld
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
   SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentageInTheWorld
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2  -- Looking at total deaths in the world vs total cases in the world


-- COVID VACCINATION TABLE TIME --
SELECT * FROM PortfolioProject..CovidVaccinations 

-- Joining CovidDeaths and CovidVaccination tables --
SELECT death.continent, death.location, death.date, death.population,
       vaccs.new_vaccinations, SUM(CONVERT(INT, vaccs.new_vaccinations)) 
       -- Can convert columns by using either CAST or CONVERT
       OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vaccs
  ON death.location = vaccs.location
  AND death.date = vaccs.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3

-- Looking at Total Population vs Vaccinations -- 
-- Make a CTE to find the percentage of vaccinations 
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population,
       vaccs.new_vaccinations, SUM(CONVERT(INT, vaccs.new_vaccinations)) 
       -- Can convert columns by using either CAST or CONVERT
       OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vaccs
  ON death.location = vaccs.location
  AND death.date = vaccs.date
WHERE death.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PeopleVacPercentage
FROM PopvsVac 

-- Making a TEMP TABLE instead of a CTE --
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), location nvarchar(255), date datetime, population numeric, 
       new_vaccinations numeric, RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population,
       vaccs.new_vaccinations, SUM(CONVERT(INT, vaccs.new_vaccinations)) 
       -- Can convert columns by using either CAST or CONVERT
       OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vaccs
  ON death.location = vaccs.location
  AND death.date = vaccs.date
WHERE death.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS PeopleVacPercentage
FROM #PercentPopulationVaccinated

-- Creating VIEW to store data for later visualizations --
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population,
       vaccs.new_vaccinations, SUM(CONVERT(INT, vaccs.new_vaccinations)) 
       -- Can convert columns by using either CAST or CONVERT
       OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vaccs
  ON death.location = vaccs.location
  AND death.date = vaccs.date
WHERE death.continent IS NOT NULL