/*
DESCRIPCION: Exploración de Datos COVID-19.

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

SELECT 
    cd1.location,
    cd1.date,
    cd1.population - (
        SELECT SUM(cd2.new_deaths) 
        FROM CovidDeaths cd2 
        WHERE cd2.location = cd1.location 
        AND cd2.date <= cd1.date
    ) AS adjusted_population,
    cd1.new_cases,
    cd1.new_deaths
FROM CovidDeaths cd1
ORDER BY cd1.location, cd1.date;
*/

-- Selección de los datos que se estarán usando.
select 
	cd.continent as continente,
	cd.location as ubicacion, 
	cd.date as fecha,
	population,
	population - sum(convert(int, total_deaths)) over (
		partition by cd.location 
		order by cd.date
	) as poblacion_ajustada,
	/*cd.population - (select sum(convert(int, cd2.total_deaths)) 
		from daportfoliodb..CovidDeaths$ cd2 
		where cd2.location = cd.location and cd2.date <= cd.date) as adjusted_population,*/
	(convert(decimal(18, 10), cast(total_deaths as float) 
		/ population)) * 100 as tasa_de_crecimiento_poblacional, --population_reduction_rate,
	total_cases as casos_totales, 
	new_cases as nuevos_casos, 
	total_deaths as muertes_totales, 
	new_deaths as nuevas_muertes,
	(total_deaths / nullif(total_cases, 0)) * 100 as tasa_de_mortalidad, --case_fatality_rate
	hosp_patients as pacientes_hospitalizados,
	new_tests as nuevas_pruebas,
	total_tests as pruebas_totales,
	positive_rate as tasa_positiva,
	convert(decimal(18, 10), max(total_cases) / population) * 100 as tasa_de_contagios,
	tests_units as unidades_de_prueba,
	max(total_vaccinations / population) * 100 as tasa_de_vacunados,
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
	on cd.continent = cv.continent
	and cd.location = cv.location
	and cd.date = cv.date
--where cd.continent is not null --and cd.location like 'nicaragua'
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

-- Comparación entre el total de casos vs el total de muertes en Panamá.
-- Muestra la tasa de mortalidad  y se ajusta la población paulatinamente.
select 
	location as ubicacion, 
	date as fecha, 
	population - sum(convert(int, total_deaths)) over (
		partition by location 
		order by date
	) as poblacion_ajustada, 
	total_cases as casos_totales, 
	total_deaths as muertes_totales, 
	(total_deaths / total_cases) * 100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where location like '%panama%' 
	and continent is not null
order by location, date

-- Observando el total de casos vs la población de Panamá.
-- Muestra qué porcentaje de la población contrajo covid.
select 
	location as ubicacion, 
	date as fecha, 
	total_cases as casos_totales, 
	population as poblacion, 
	(total_cases/population)*100 as tasa_de_contagios 
from daportfoliodb..CovidDeaths$
where location like '%panama%' 
	and continent is not null
order by location, date

-- Se muestran los países con mayor tasa de contagios en comparación con su población.
select 
	location as paises_mas_afectados, 
	population as poblacion, 
	max(total_cases) as casos_totales, 
	max((total_cases/population)*100) as tasa_de_contagios
from daportfoliodb..CovidDeaths$
where continent is not null
group by location, population
order by tasa_de_contagios desc

-- Se muestran los países con el mayor indice de muerte en comparacion con su población.
select 
	location as paises_con_mayor_tasa_de_mortalidad, 
	max(cast(total_deaths as int)) as muertes_totales
from daportfoliodb..CovidDeaths$
where continent is not null
group by location
order by muertes_totales desc

-- Se muestran los continentes con el mayor indice de muerte en comparacion con su poblacion.
select 
	continent as continentes_con_mayor_tasa_de_mortalidad, 
	max(cast(total_deaths as int)) as muertes_totales
from daportfoliodb..CovidDeaths$
where continent is not null
group by continent
order by muertes_totales desc

-- Se muestran los nuevos casos y muertes por COVID-19 a nivel global a lo largo del tiempo.
select 
	date as fecha, 
	location as ubicacion, 
	sum(new_cases) as nuevos_casos_globales, 
	sum(cast(new_deaths as int)) as nuevas_muertes_globales, 
	sum(cast(new_deaths as int))/nullif(sum(new_cases), 0)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where continent is not null
group by date, location
order by nuevos_casos_globales, nuevas_muertes_globales

-- Se muestra el total de casos y muertes por COVID-19 a nivel global.
select 
	sum(new_cases) as nuevos_casos_globales, 
	sum(cast(new_deaths as int)) as nuevas_muertes_globales, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as tasa_de_mortalidad
from daportfoliodb..CovidDeaths$
where continent is not null
order by nuevos_casos_globales, nuevas_muertes_globales

-- Seguimiento de la Poblacion Vacunada y Tasa de Vacunados.
select 
	cd.continent as continente, 
	cd.location as pais, 
	cd.date as fecha, 
	cd.population as poblacion, 
	cd.new_cases as nuevos_casos, 
	cd.new_deaths as nuevas_muertes, 
	cv.new_vaccinations as nuevas_vacunaciones, 
	sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date
	) as seguimiento_de_poblacion_vacunada,
	(sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date
	) / population) * 100 as tasa_de_vacunados
from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null
order by cd.continent, cd.location, cd.date

-- Seguimiento de la Poblacion Vacunada y Tasa de Vacunados utilizando CTE.
with poblacion_vs_vacunaciones (
	continente, 
	ubicacion, 
	fecha, 
	poblacion, 
	nuevos_casos, 
	nuevas_muertes, 
	nuevas_vacunaciones, 
	seguimiento_de_poblacion_vacunada,
	tasa_de_vacunados) 
as (
select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cd.new_cases, 
	cd.new_deaths, 
	cv.new_vaccinations, 
	sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date),
	(sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date) / population) * 100
from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null)

select * from poblacion_vs_vacunaciones order by continente, ubicacion, fecha

-- Seguimiento de la poblacion vacunada y Tasa de Vacunados creando un Tabla Temporal.
drop table if exists #tasa_de_poblacion_vacunada
create table #tasa_de_poblacion_vacunada (
	continente nvarchar(255),
	ubicacion nvarchar(255),
	fecha datetime,
	poblacion numeric,
	nuevos_casos float,
	nuevas_muertes nvarchar(255),
	nuevas_vacunaciones numeric,
	seguimiento_de_poblacion_vacunada numeric,
	tasa_de_vacunados float)

insert into #tasa_de_poblacion_vacunada
select 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cd.new_cases, 
	cd.new_deaths, 
	cv.new_vaccinations, 
	sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date),
	(sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date) / population) * 100
from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null

select * from #tasa_de_poblacion_vacunada order by continente, ubicacion, fecha

-- Seguimiento de la Poblacion Vacunada y Tasa de Vacunados 
-- creando una Vista para almacenar datos para su posterior visualización.
use daportfoliodb
drop view if exists vw_TasaDePoblacionVacunada
create view vw_TasaDePoblacionVacunada 
as 
select 
	cd.continent as continente, 
	cd.location as ubicacion, 
	cd.date as fecha, 
	cd.population as poblacion, 
	cd.new_cases as nuevos_casos, 
	cd.new_deaths as nuevas_muertes, 
	cv.new_vaccinations as nuevas_vacunaciones, 
	sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date
	) as seguimiento_de_poblacion_vacunada,
	(sum(convert(int, cv.total_vaccinations)) over (
		partition by cd.location 
		order by cd.location, cd.date
	) / population) * 100 as tasa_de_vacunados
from daportfoliodb..CovidDeaths$ cd 
	join daportfoliodb..CovidVaccinations$ cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null

select * from vw_TasaDePoblacionVacunada order by continente, ubicacion, fecha
