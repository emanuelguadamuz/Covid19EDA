/*
DESCRIPCION: Consultas de Datos COVID-19 y Visualización en Tableau.

HABILIDADES UTILIZADAS: 
- Uniones
- Conversión de Tipos de Datos
- Funciones de Windows
- Funciones de Agregación
- CTE (Expresiones Comunes de Tablas)
- Tablas Temporales
- Creación de Vistas

INDICACIONES: Para obtener las tablas CovidDeaths$ y CovidVaccinations$ con su respectiva informacion 
primero se procedió a depurar las columnas a usar en los archivos excel CovidDeaths.xlsx y CovidVaccinations.xlsx. 
A continuacion, se procedió con la importacion de dichos archivos a las base de datos daportfoliodb mediante 
SSMS (SQL Server Management Studio).
*/

-- Tableau 1: Actualización de Dashboard COVID-19
-- Comparación entre el total de casos vs el total de muertes en Panamá.
-- Muestra la tasa de mortalidad  y se ajusta la población paulatinamente.
select 
	cd.continent as continente,
	cd.location as ubicacion, 
	cd.date as fecha,
	population - sum(convert(int, total_deaths)) over (
		partition by cd.location 
		order by cd.date
	) as poblacion_ajustada,
	total_cases as casos_totales, 
	new_cases as nuevos_casos, 
	total_deaths as muertes_totales, 
	new_deaths as nuevas_muertes,
	(total_deaths/total_cases)*100 as tasa_de_mortalidad,
	hosp_patients as pacientes_hospitalizados,
	new_tests as nuevas_pruebas,
	total_tests as pruebas_totales,
	positive_rate as tasa_positiva,
	max(total_cases/population) * 100 as tasa_de_contagios,
	tests_units as unidades_de_prueba,
	max(total_vaccinations/population) * 100 as tasa_de_vacunados,
	total_vaccinations as vacunaciones_totales,
	people_vaccinated as personas_vacunadas,
	new_vaccinations as nuevas_vacunaciones,
	population_density as densidad_de_la_poblacion,
	median_age as edad_media,
	aged_65_older as edad_65_mayor,
	aged_70_older as edad_70_mayor,
	extreme_poverty as pobreza_extrema,
	cardiovasc_death_rate as tasa_de_mortalidad_cardiovascular,
	diabetes_prevalence as prevalencia_de_diabetes,
	female_smokers as mujeres_fumadoras,
	male_smokers as hombres_fumadores,
	handwashing_facilities as instalaciones_para_lavarse_las_manos,
	hospital_beds_per_thousand as camas_de_hospital_x_cada_mil,
	life_expectancy as expectativa_de_vida,
	human_development_index as indice_desarrollo_humano
from daportfoliodb..CovidDeaths$ cd
	join daportfoliodb..CovidVaccinations$ cv
	on cd.location = cv.location
	and cd.date = cv.date
	and cv.total_vaccinations is not null
where cd.continent is not null
	--and cd.location like '%panama%'
group by 
	cd.continent, 
	cd.location, 
	cd.date, 
	population, 
	total_cases, 
	new_cases, 
	total_deaths, 
	new_deaths, 
	hosp_patients, 
	new_tests, 
	total_tests,
	positive_rate,
	tests_units,
	total_vaccinations,
	people_vaccinated,
	new_vaccinations,
	population_density,
	median_age,
	aged_65_older,
	aged_70_older,
	extreme_poverty,
	cardiovasc_death_rate,
	diabetes_prevalence,
	female_smokers,
	male_smokers,
	handwashing_facilities,
	hospital_beds_per_thousand,
	life_expectancy,
	human_development_index
order by cd.continent, cd.location, cd.date

-- Tableau 2: Tasa de mortalidad en Panama.
select 
	max(date) as fecha, 
	max (population) as poblacion, 
	sum(new_cases) as casos_totales, 
	sum(cast(new_deaths as int)) as muertes_totales, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where location like '%panama%'
--group by date
order by casos_totales, muertes_totales

-- Tableau 3: Total de muertes en cada continente.
-- La tabla CovidDeaths muestra International, European Union y World como ubicación,
-- por lo que se omitieron para obtener resultados consistentes. 
select 
	location as ubicacion, 
	sum(cast(new_deaths as int)) as muertes_totales
from daportfoliodb..CovidDeaths$
where continent is null 
	and location not in ('World', 'European Union', 'International')
group by location
order by muertes_totales desc

-- Tableau 4: Tasa de contagios y el valor maximo de personas contagiadas en cada país.
select 
	location as ubicacion, 
	population as poblacion, 
	max(total_cases) as valor_max_contagiados, 
	max(total_cases/population)*100 as tasa_de_contagios
from daportfoliodb..CovidDeaths$
group by location, population
order by tasa_de_contagios desc

-- Tableau 5: Tasa de mortalidad y el valor maximo de personas contagiadas en cada país a lo largo del tiempo.
select 
	location as ubicacion, 
	population as poblacion, 
	date as fecha, 
	max(total_cases) as valor_max_contagiados, 
	max(total_cases/population)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
--where location like '%anama%'
group by location, population, date
order by tasa_de_mortalidad desc

-- Tableau 6: Seguimiento de la población que esta siendo vacunada a lo largo del tiempo a nivel global.
select 
	cd.continent as continente, 
	cd.location as ubicacion, 
	cd.date as fecha, 
	cd.population as poblacion, 
	cd.new_cases, 
	cd.new_deaths, 
	cv.new_vaccinations, 
	max(cv.total_vaccinations) as seguimiento_de_poblacion_vacunada
from daportfoliodb..CovidDeaths$ cd
	join daportfoliodb..CovidVaccinations$ cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null 
	and cv.total_vaccinations is not null
group by cd.continent, cd.location, cd.date, population, new_cases, new_deaths, cv.new_vaccinations
order by cd.continent, cd.location, cd.date

-- Tableau 7: Tasa de mortalidad en Panamá
select 
	sum(new_cases) as casos_totales, 
	sum(cast(new_deaths as int)) as muertes_totales, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where location like '%panama%'
	and continent is not null 
order by casos_totales, muertes_totales

-- Tableau 8: Tasa de vacunados y seguimiento de la población vacunada a nivel global.
with population_vs_vaccinations (
	continent, 
	location, 
	date, 
	population, 
	new_cases, 
	new_deaths, 
	new_vaccinations, 
	vaccinated_population_tracking) 
as (select 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cd.new_cases, 
		cd.new_deaths, 
		cv.new_vaccinations, 
		sum(convert(int, cv.total_vaccinations)) over (
			partition by cd.location 
			order by cd.location, cd.date
		)
	from daportfoliodb..CovidDeaths$ cd
		join daportfoliodb..CovidVaccinations$ cv
		on cd.location = cv.location
		and cd.date = cv.date
	where cd.continent is not null
	)

select 
	continent as continente, 
	location as ubicacion, 
	date as fecha, 
	population as poblacion, 
	new_cases as nuevos_casos, 
	new_deaths as nuevas_muertes, 
	new_vaccinations as nuevas_vacunaciones,
	vaccinated_population_tracking as seguimiento_de_poblacion_vacunada,
	(vaccinated_population_tracking/population)*100 as tasa_de_vacunados 
from population_vs_vaccinations

-- Tableau 9: Tasa de mortalidad a nivel global.
select 
	sum(new_cases) as casos_totales, 
	sum(cast(new_deaths as int)) as muertes_totales, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where continent is not null 
order by casos_totales, muertes_totales
