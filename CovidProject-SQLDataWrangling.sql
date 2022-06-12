--Glance through the data

SELECT * 
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

SELECT *
FROM CovidProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4;

------------------------------------------------------

SELECT Location, date, total_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Shows likehood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
	AND location like '%states%'
ORDER BY 1,2;

-- Total Cases vs Population
-- Shows what percentage of population got infected
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectedPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
	AND location like '%states%'
ORDER BY 1,2;

-- Countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY Location,population
ORDER BY InfectedPercentage desc;

-- Countries with highest Death count per population
SELECT Location, population, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, population
ORDER BY TotalDeathCount desc;

--Let's see things continent wise
--Continent with highest death counts
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc;

--Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2;

--Total population vs Total Vaccinations

SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CONVERT(bigint, V.new_vaccinations)) over (Partition by D.Location order by D.Location, D.date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)*100 as PercentVaccinated (You can't do this calculation here so we'll make a CTE or Temp table to access this column)
FROM CovidProject..CovidDeaths AS D
JOIN CovidProject..CovidVaccinations AS V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent is not null
	AND D.location like '%states%'
ORDER BY 2,3;

--Using CTE to perform Calculation on RollingPeopleVaccinated in previous query

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CONVERT(bigint, V.new_vaccinations)) over (Partition by D.Location order by D.Location, D.date) as RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS D
JOIN CovidProject..CovidVaccinations AS V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
FROM PopvsVac;

-- Using Temp Table to perform Calculation on RollingPeopleVaccinated in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), 
Location nvarchar(255),
Date datetime, 
Population numeric, 
new_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert INTO #PercentPopulationVaccinated
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CONVERT(bigint, V.new_vaccinations)) over (Partition by D.Location order by D.Location, D.date) as RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS D
JOIN CovidProject..CovidVaccinations AS V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
FROM #PercentPopulationVaccinated;

--Create a View for later

CREATE VIEW PercentPopulationVaccinated AS
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(CONVERT(bigint, V.new_vaccinations)) over (Partition by D.Location order by D.Location, D.date) as RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS D
JOIN CovidProject..CovidVaccinations AS V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent is not null;

Select * 
FROM PercentPopulationVaccinated;