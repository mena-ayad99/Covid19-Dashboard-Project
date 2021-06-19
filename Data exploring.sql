--Exploring the Covid project data

SELECT * 
FROM CovidProject..Co19death
ORDER BY 3,4

--SELECT * 
--FROM CovidProject..Co19vac
--ORDER BY 3,4


SELECT location, date, population, new_cases, total_cases, total_deaths  
FROM CovidProject..Co19death
ORDER BY 1,2

--Looking at total cases vs total deaths

SELECT location, date, population,  total_cases, total_deaths  , (total_deaths/ total_cases *100) AS death_rate
FROM CovidProject..Co19death
WHERE location = 'Canada'
ORDER BY 1,2


--Looking at total cases vs population

SELECT location, date, population,  total_cases, (total_cases/ population *100) AS infection_rate
FROM CovidProject..Co19death
WHERE location = 'Canada'
ORDER BY 1,2


--Countries with the highest infection rate

SELECT location, population,  Max(total_cases) AS total_cases, (Max(total_cases)/ population *100) AS infection_rate
FROM CovidProject..Co19death
--WHERE location = 'Canada'
GROUP BY location, population
ORDER BY infection_rate DESC



--Countries with highest death count 

SELECT location, population,  MAX(CAST(total_deaths AS int)) AS death_count
FROM CovidProject..Co19death
WHERE continent IS NOT NULL
--where clause to remove the regional and non-country enteries from locations
GROUP BY location, population
ORDER BY death_count DESC


--Countries with highest death ratio of the total population 

SELECT location, population,  MAX(CAST(total_deaths AS int)) AS death_count 
	,MAX(CAST(total_deaths AS int))/ population *100 AS pop_death_ratio
FROM CovidProject..Co19death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY pop_death_ratio DESC


--Global death ratio

SELECT date, SUM(new_cases) as global_new_cases, SUM(CAST (new_deaths AS int)) AS global_new_death
	, SUM(CAST (new_deaths AS int))/SUM(new_cases) *100 AS global_death_percent
FROM CovidProject..Co19death
WHERE continent IS NOT NULL
Group BY date
ORDER BY 1



--Exploring the merged tables

SELECT *
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
ON de.location= vc.location
AND de.date= vc.date
ORDER BY de.location,de.date


-- Exploring population vs the daily vaccination progress

SELECT de.continent, de.location, de.date, de.population, vc.new_vaccinations 
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
	ON de.location= vc.location
	AND de.date= vc.date
WHERE de.continent IS NOT NULL
ORDER BY de.location,de.date



-- Exploring population vs rolling vaccination progress

SELECT de.continent, de.location, de.date, de.population, vc.new_vaccinations 
	,SUM(Cast (vc.new_vaccinations as int)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as rolling_vaccination_count
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
	ON de.location= vc.location
	AND de.date= vc.date
WHERE de.continent IS NOT NULL
ORDER BY de.location,de.date


-- Using CTE to do further calc on vaccination progress


With POPvsVAC (continent, location, date, population, new_vaccinations, rolling_vaccination_count)
AS
(
SELECT de.continent, de.location, de.date, de.population, vc.new_vaccinations 
	,SUM(Cast (vc.new_vaccinations as int)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as rolling_vaccination_count
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
	ON de.location= vc.location
	AND de.date= vc.date
WHERE de.continent IS NOT NULL
--ORDER BY de.location,de.date
)

SELECT *, (rolling_vaccination_count/population*100) AS rolling_vaccination_percent
FROM POPvsVAC
WHERE location = 'Canada'



--Creating a temp Table for Vaccination rollout

DROP TABLE IF exists vac_rollout

CREATE TABLE vac_rollout
(
continent nvarchar(255),
location  nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination_count numeric
)

INSERT INTO vac_rollout

SELECT de.continent, de.location, de.date, de.population, vc.new_vaccinations 
	,SUM(Cast (vc.new_vaccinations as int)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as rolling_vaccination_count
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
	ON de.location= vc.location
	AND de.date= vc.date
WHERE de.continent IS NOT NULL


SELECT *, (rolling_vaccination_count/population*100) AS rolling_vaccination_percent
FROM vac_rollout
WHERE location like '%states%'



--Creating a view for Vaccination rollout to be used in visualization

DROP VIEW IF exists vac_rollout_view

CREATE VIEW vac_rollout_view  AS

SELECT de.continent, de.location, de.date, de.population, vc.new_vaccinations 
	,SUM(Cast (vc.new_vaccinations as int)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as rolling_vaccination_count
FROM CovidProject..Co19death as de
Join CovidProject..Co19vac as vc
	ON de.location= vc.location
	AND de.date= vc.date
WHERE de.continent IS NOT NULL

