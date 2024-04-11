/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Total Cases vs Total Deaths (Percentage of deaths per covid case)

Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From public.covid_deaths
Where location IN ('India')
and continent is not null 
order by 1,2;

-- Total Cases vs Population (Percentage of population infected with Covid)

Select location, date, total_cases,total_deaths, population, (total_cases/population)*100 as PercentPopulationInfected
From public.covid_deaths
Where location IN ('India')
and continent is not null 
order by 1,2;

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From public.covid_deaths
Where continent is not null 
Group By location,population
HAVING MAX(total_cases) IS NOT NULL
order by 4 DESC;

-- Countries With Highest Death Counts per Population
Select location,MAX(total_deaths) AS total_Deaths, MAX((total_deaths/population)*100) as DeathPercentage
From public.covid_deaths
Where continent is not null 
Group By location
HAVING MAX(total_deaths) IS NOT NULL
order by 2 DESC, 3 DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Contintents with the highest death count per population
Select continent,MAX(total_deaths) AS total_Deaths, MAX((total_deaths/population)*100) as DeathPercentage
From public.covid_deaths
Where continent is not null 
Group By continent
HAVING MAX((total_deaths/population)*100) IS NOT NULL
order by 3 DESC, 2 DESC;

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From public.covid_deaths
Where continent is not null 
--Group By date
order by 1,2;

-- Total Population vs Vaccinations (Percentage of Population that has recieved at least one Covid Vaccine)
Select d.continent, d.location,d.date,d.population,v.new_vaccinations,SUM(new_vaccinations) OVER (Partition by d.location ORDER BY d.date) AS RollingPeopleVaccinated
From public.covid_deaths d
JOIN public.covid_vaccinations v
ON d.location = v.location and d.date=v.date
Order By 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location,d.date,d.population,v.new_vaccinations,SUM(new_vaccinations) OVER (Partition by d.location ORDER BY d.date) AS RollingPeopleVaccinated
From public.covid_deaths d
JOIN public.covid_vaccinations v
ON d.location = v.location and d.date=v.date
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;

-- Using sub-query to perform Calculation on Partition By in previous query

SELECT Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated, (RollingPeopleVaccinated/Population)*100
FROM
(
	Select d.continent, d.location,d.date,d.population,v.new_vaccinations,MAX(new_vaccinations) OVER (Partition by d.location ORDER BY d.date) AS RollingPeopleVaccinated
From public.covid_deaths d
JOIN public.covid_vaccinations v
ON d.location = v.location and d.date=v.date
--order by 2,3
) PopvsVac;

-- Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
Create Temp Table PercentPopulationVaccinated 
(continent varchar(255),
location varchar (255),
Date date,
population bigint,
new_vaccination bigint,
rollingpeoplevaccinated bigint)

insert into PercentPopulationVaccinated 
Select d.continent, d.location,d.date,d.population,v.new_vaccinations,SUM(new_vaccinations) OVER (Partition by d.location ORDER BY d.date) AS RollingPeopleVaccinated
From public.covid_deaths d
JOIN public.covid_vaccinations v
ON d.location = v.location and d.date=v.date
Order By 2,3;

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated ;

-- Creating View to store data for later visualizations 

CREATE VIEW percent_population_vaccinated AS
Select d.continent, d.location,d.date,d.population,v.new_vaccinations,SUM(new_vaccinations) OVER (Partition by d.location ORDER BY d.date) AS RollingPeopleVaccinated
From public.covid_deaths d
JOIN public.covid_vaccinations v
ON d.location = v.location and d.date=v.date
Order By 2,3;

CREATE VIEW population_with_highest_death_count AS
Select continent,MAX(total_deaths) AS total_Deaths, MAX((total_deaths/population)*100) as DeathPercentage
From public.covid_deaths
Where continent is not null 
Group By continent
HAVING MAX((total_deaths/population)*100) IS NOT NULL
order by 3 DESC, 2 DESC;

CREATE VIEW countries_with_highest_death_rate AS
Select continent,MAX(total_deaths) AS total_Deaths, MAX((total_deaths/population)*100) as DeathPercentage
From public.covid_deaths
Where continent is not null 
Group By continent
HAVING MAX((total_deaths/population)*100) IS NOT NULL
order by 3 DESC, 2 DESC;
