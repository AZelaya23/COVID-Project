--- creating queries to use for tableau
--1.
select 
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from CovidDeaths
where
	continent is not null
-- group by date
order by 1,2

--2.
select 
	location,
	sum(cast(new_deaths as int)) as total_death_count
from
	CovidDeaths
where
	continent is null and
	location not in ('World','European Union','International')
group by
	location
order by 
	total_death_count
--3.
select
	location,
	population,
	max(total_cases) as highest_infection_count,
	max(total_cases/population)*100 as percent_population_infected
from
	CovidDeaths
group by
	location,population,date
order by
	percent_population_infected DESC

---4.
Select 
	Location, 
	Population, 
	date,
	MAX(total_cases) as highest_infection_count,  
	Max((total_cases/population))*100 as percent_population_infected
From CovidDeaths
--Where location like '%states%'
Group by 
	Location, Population, date
order by 
	percent_population_infected desc



---- Impletmenting the Excel filed
---Covid Deaths table
select *
from CovidDeaths
where continent is not null
order by 3, 4

---Covid Vaccinations
select *
from CovidVaccinations
where continent is not null
order by 3, 4

--- Select Data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by location, date


--- Finding the total cases vs total deaths in the united states
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
from CovidDeaths
where location like '%states%' and continent is not null
order by location, date;
---Finding: By the end of 2020, the start of the pandemic, the U.S. had a death percentage of 1.8% with a little over 2 million people contracting COVID
--- and 352k people have died due to COVID

--- finding the total cases vs population
--- shows what percentage of population got covid
select location, date,total_cases, population, (total_cases/population)*100 as case_percentage
from CovidDeaths
where location like '%states%' and continent is not null
order by location, date;

--- finding the countries with the highest infection rate compared to population
select location,
	population,
	max(total_cases)as highest_infection_count, 
	max((total_cases/population))*100 as case_percentage
from CovidDeaths
--where location like '%states% and continent is not null
group by location, population
order by case_percentage desc



--- show the countries with the highest death count per population
--Initially, total death is shown as VarChar, but we want it as an int. Solution: casting
select location,
	Max (cast(total_deaths as int)) as totalDeathCount
from CovidDeaths
where continent is null
group by location
order by totalDeathCount desc


-- Show the continents with the highest death counts
select
	continent,
	max(cast(total_deaths as int)) as totalDeathCount
from
	CovidDeaths
where
	continent is not null
group by
	continent
order by
	totalDeathCount DESC


--- Global numbers
select  
	date, 
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)), 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage 
from 
	CovidDeaths
where 
	--location like '%states%' and 
	continent is not null
group by 
	date
order by 
	1,2;

--- JOINING COVID death table and COVID vaccinations table
--note: we use parition by so that we want the count to reset
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date)as rolling_people_vaccinations

from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where
	dea.continent is not null
order by 2,3

--- Using CTE
with popVsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinations)
as
(
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where
	dea.continent is not null
--order by 2,3
)
select *, (rolling_people_vaccinations/population)*100 as rolling_percentage
from popVsVac

-- creating a temp table
drop table if exists Percent_population_vaccinated
Create table Percent_population_vaccinated(
	continent nvarchar (255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccination numeric,
	rolling_people_vaccinated numeric
)

insert into Percent_population_vaccinated
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where
	dea.continent is not null
order by 2,3

select *, (rolling_people_vaccinated/population)*100 as rolling_percentage
from Percent_population_vaccinated

-- creating views to store data for visualizations
create view Percent_population_vaccinate as
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where
	dea.continent is not null
--order by 2,3