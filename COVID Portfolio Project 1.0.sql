
Select *
From AASQLProject..CovidDeaths
Order by 3,4

--Select *
--From AASQLProject..CovidVaccinations
--Order by 3,4

-- Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From AASQLProject..CovidDeaths
Order by location, date

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (cast(total_deaths AS float)/cast(total_cases AS float))*100 AS DeathPercentage
From AASQLProject..CovidDeaths
Where location like '%states%'
Order by location, date

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
Select location, date, population, total_cases, (cast(total_cases AS float)/population)*100 AS PercentPopulationInfected
From AASQLProject..CovidDeaths
--Where location like '%states%'
Order by location, date

-- Looking at countries with highest infection rates compared to population


Select location, population, Max(total_cases) AS HighestInfectionCount, Max((cast(total_cases AS float)/population))*100 AS PercentPopulationInfected
From AASQLProject..CovidDeaths
--Where location like '%states%'
Group by location, population
Order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

Select location, Max(cast(Total_deaths as int)) AS TotalDeathCount
From AASQLProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- Let's break things down by continent
-- Showing the continents with the highest death count per population

--probably won't use this query b/c numbers appear to be off...
--Select continent, Max(cast(Total_deaths as int)) AS TotalDeathCount
--From AASQLProject..CovidDeaths
----Where location like '%states%'
--Where continent is not null 
--Group by continent
--Order by TotalDeathCount desc

Select location, Max(cast(Total_deaths as int)) AS TotalDeathCount
From AASQLProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
AND location not like '%income%'
Group by location
Order by TotalDeathCount desc


-- Global Numbers

--(Note: Needed to add having clause to avoid error can't divide by zero for the DeathPercentage aggr column.
Select date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
From AASQLProject..CovidDeaths
Where continent is not null
Group by date
Having SUM(new_cases) >= 1
Order by 1,2

Select SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
From AASQLProject..CovidDeaths
Where continent is not null


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER(Partition by dea.location
														Order by dea.location, dea.date) AS RollingVaccinationCount
		--(RollingVaccinationCount/population)*100
From AASQLProject..CovidDeaths dea
Join AASQLProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3


-- Use CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount)
AS (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER(Partition by dea.location
														Order by dea.location, dea.date) AS RollingVaccinationCount
		--(RollingVaccinationCount/population)*100
From AASQLProject..CovidDeaths dea
Join AASQLProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)

Select *, (RollingVaccinationCount/population)*100 AS PercentVaccinated
From PopVsVac
Order by Location, Date


-- Use Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinationCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER(Partition by dea.location
														Order by dea.location, dea.date) AS RollingVaccinationCount
		--, (RollingVaccinationCount/population)*100
From AASQLProject..CovidDeaths dea
Join AASQLProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select *, (RollingVaccinationCount/population)*100 AS PercentVaccinated
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create view PercentPopulationVaccinated
AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER(Partition by dea.location
														Order by dea.location, dea.date) AS RollingVaccinationCount
		--, (RollingVaccinationCount/population)*100
From AASQLProject..CovidDeaths dea
Join AASQLProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select *
From PercentPopulationVaccinated