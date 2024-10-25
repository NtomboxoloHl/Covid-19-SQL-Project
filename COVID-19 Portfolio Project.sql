SELECT *
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null
ORDER BY  3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio..CovidDeaths
ORDER BY  1,2   -- this shows that the results are sorted first by LOCATION and then time ASC (by default).

-- We're gonna determine how many cases are there and how many deaths occured per country. 
-- Shows the likelihood of dying if you contract covid in your country.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM ProjectPortfolio..CovidDeaths
WHERE location like '%africa'
ORDER BY  1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid
SELECT location, date, population,total_cases, (total_cases/population)*100 AS population_infected_rate
FROM ProjectPortfolio..CovidDeaths
--WHERE location like '%africa'
ORDER BY  1,2

-- Which countries have the highest infection rate compared to the population 
SELECT location, population,MAX(total_cases) AS highest_infection_count  , MAX((total_cases/population))*100 AS population_infected_rate
FROM ProjectPortfolio..CovidDeaths
--WHERE location like '%africa'
GROUP BY location, population
ORDER BY  population_infected_rate DESC



-- Let's look at countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null  /*Notice that there are groupings of entire continents in our data. This is caused a NULL entry in continent
								and therefore the entry that was supposed to be a continuent is on location.*/
GROUP BY location 
ORDER BY  total_death_count DESC 

-- Let's break things down by continent. Which continent has the highest death count 
SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null  
GROUP BY continent
ORDER BY  total_death_count DESC 

-- Let's break things down by global number. We;re looking at overall death percentage globally 
SELECT  SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentge
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null 
--GROUP BY date
ORDER BY  1,2

--Looking at how many people in the world that have vaccinated. JOIN covid vaccination on covid deaths table.
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
	SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations ,
			SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated                                    
	FROM ProjectPortfolio..CovidDeaths AS dea
	JOIN ProjectPortfolio..CovidVaccinations AS vac 
		ON dea.location = vac.location 
		AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
)

SELECT * , (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac

--TEMPORARY TABLE 
DROP TABLE IF EXISTS  PercentagePopulationVaccinated
CREATE TABLE PercentagePopulationVaccinated 
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric)

Insert into PercentagePopulationVaccinated
	SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations ,
			SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated                                    
	FROM ProjectPortfolio..CovidDeaths AS dea
	JOIN ProjectPortfolio..CovidVaccinations AS vac 
		ON dea.location = vac.location 
		AND dea.date = vac.date
	--WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT * , (RollingPeopleVaccinated/Population)*100 AS Vaccinated_Rate
FROM PercentagePopulationVaccinated


-- Creating view to store data later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
	SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations ,
				SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated                                    
	FROM ProjectPortfolio..CovidDeaths AS dea
	JOIN ProjectPortfolio..CovidVaccinations AS vac 
			ON dea.location = vac.location 
			AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT * 
FROM PercentPopulationVaccinated