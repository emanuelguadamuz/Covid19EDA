/*
Análisis de datos sobre COVID-19.

Habilidades utilizadas: 
- Uniones
- Conversión de Tipos de Datos
- Funciones de Windows
- Funciones de Agregación
- Expresiones Comunes de Tablas (CTE)
- Tablas Temporales
- Creación de Vistas
*/

-- Exploración de todos los datos.
select * 
from daportfoliodb..CovidDeaths$ 
where continent is not null 
order by location, date

-- Selección de los datos que se estarán usando.
select location as ubicacion, date as fecha, total_cases as casos_totales, new_cases as nuevos_casos, total_deaths as muertes_totales, population as poblacion 
from daportfoliodb..CovidDeaths$
where continent is not null
order by location, date

-- Comparación entre el total de casos y el total de muertes en Panamá.
-- Muestra la probabilidad de morir si se contrae covid en determinado país.
select location as ubicacion, date as fecha, total_cases as casos_totales, total_deaths as muertes_totales, (total_deaths/total_cases)*100 as porcentaje_de_muertes
from daportfoliodb..CovidDeaths$
where location like '%anama%' and continent is not null
order by location, date

-- Observando el total de casos vs la población de Panamá.
-- Muestra qué porcentaje de la población contrajo covid.
select location as ubicacion, date as fecha, total_cases as casos_totales, population as poblacion, (total_cases/population)*100 as porcentaje_de_contagiados 
from daportfoliodb..CovidDeaths$
where location like '%anama%' and continent is not null
order by location, date

-- Se muestran los países con mayor tasa de contagios en comparación con su población.
select location as paises_mas_afectados, population as poblacion, max(total_cases) as casos_totales, max((total_cases/population)*100) as porcentaje_de_poblacion_contagiada
from daportfoliodb..CovidDeaths$
where continent is not null
group by location, population
order by porcentaje_de_poblacion_contagiada desc

-- Se muestran los países con el mayor indice de muerte en comparacion con su población.
select location as paises_con_mayor_tasa_de_mortalidad, max(cast(total_deaths as int)) as muertes_totales
from daportfoliodb..CovidDeaths$
where continent is not null
group by location
order by muertes_totales desc

-- Se muestran los continentes con el mayor indice de muerte en comparacion con su poblacion.
select continent as continentes_con_mayor_tasa_de_mortalidad, max(cast(total_deaths as int)) as muertes_totales
from daportfoliodb..CovidDeaths$
where continent is not null
group by continent
order by muertes_totales desc

-- Se muestran los nuevos casos y muertes por covid a nivel global a lo largo del tiempo.
select date as fecha, location as ubicacion, sum(new_cases) as nuevos_casos_globales
, sum(cast(new_deaths as int)) as nuevas_muertes_globales
, sum(cast(new_deaths as int))/nullif(sum(new_cases), 0)*100 as porcentaje_de_muertes
from daportfoliodb..CovidDeaths$
where continent is not null
group by date, location
order by nuevos_casos_globales, nuevas_muertes_globales

-- Se muestra el total de casos y muertes por covid a nivel global.
select sum(new_cases) as nuevos_casos_globales, sum(cast(new_deaths as int)) as nuevas_muertes_globales, sum(cast(new_deaths as int))/sum(new_cases)*100 as porcentaje_de_muertes
from daportfoliodb..CovidDeaths$
where continent is not null
order by nuevos_casos_globales, nuevas_muertes_globales

-- Explorando los datos de la tabla CovidVaccinations.
select * 
from daportfoliodb..CovidVaccinations$ 
where continent is not null 
order by location, date

-- Observando la población total versus las vacunaciones.
-- Muestra el porcentaje de la población que ha recibido al menos una vacuna contra el Covid.
select cd.continent as continente, cd.location as pais, cd.date as fecha, cd.population as poblacion
, cd.new_cases as nuevos_casos, cd.new_deaths as nuevas_muertes, cv.new_vaccinations as nuevas_vacunaciones
, sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as seguimiento_de_personas_vacunadas
from daportfoliodb..CovidDeaths$ cd 
join daportfoliodb..CovidVaccinations$ cv 
on cd.location = cv.location 
and cd.date = cv.date
where cd.continent is not null
order by cd.location, cd.date

-- Al igual que en la consulta anterior, pero utilizando CTE para realizar un cálculo en la partición hecha con Partition By
With population_vs_vaccinations (continent, location, date, population, new_cases, new_deaths, new_vaccinations, tracking_vaccinated_people) as (
	select cd.continent, cd.location, cd.date, cd.population, cd.new_cases, cd.new_deaths, cv.new_vaccinations
	, sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as seguimiento_de_personas_vacunadas
	from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date
	where cd.continent is not null)
select continent as continente, location as ubicacion, date as fecha, population as poblacion
, new_cases as nuevos_casos, new_deaths as nuevas_muertes, new_vaccinations as nuevas_vacunaciones
, (tracking_vaccinated_people/population)*100 as porcentaje_del_seguimiento_de_personas_vacunadas 
from population_vs_vaccinations

-- Using Temp Table
drop table if exists #percent_vaccinated_people
create table #percent_vaccinated_people (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_cases float,
new_deaths nvarchar(255),
new_vaccinations numeric,
tracking_vaccinated_people numeric)

insert into #percent_vaccinated_people
select cd.continent, cd.location, cd.date, cd.population, cd.new_cases, cd.new_deaths, cv.new_vaccinations
	, sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as tracking_vaccinated_people
	--, (tracking_vaccinated_people/population)*100 as percentage_of_tracking_vaccinated_people
	from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date

select continent as continente, location as ubicacion, date as fecha, population as poblacion
, new_cases as nuevos_casos, new_deaths as nuevas_muertes, new_vaccinations as nuevas_vacunaciones
, (tracking_vaccinated_people/population)*100 as porcentaje_del_seguimiento_de_personas_vacunadas 
from #percent_vaccinated_people

-- Creación de una vista para almacenar datos para su posterior visualización
create view vw_PercentPopulationVaccinated as
select cd.continent, cd.location, cd.date, cd.population, cd.new_cases, cd.new_deaths, cv.new_vaccinations
, sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as tracking_vaccinated_people
from daportfoliodb..CovidDeaths$ cd 
join daportfoliodb..CovidVaccinations$ cv 
on cd.location = cv.location 
and cd.date = cv.date
where cd.continent is not null

select continent as continente, location as ubicacion, date as fecha, population as poblacion
, new_cases as nuevos_casos, new_deaths as nuevas_muertes, new_vaccinations as nuevas_vacunaciones
, tracking_vaccinated_people as seguimiento_de_personas_vacunadas 
from vw_PercentPopulationVaccinated