/*
DESCRIPCION: Limpieza de Datos de Viviendas con Consultas SQL.

HABILIDADES UTILIZADAS:
- DQL (Lenguaje de consulta de datos)
- DDL (Lenguaje de definición de datos)
- DML (Lenguaje de manipulación de datos)
- Conversión de Tipos de Datos
- Funciones de Windows
- Funciones de Agregación
- CTE (Expresiones Comunes de Tablas)

INDICACIONES: Para obtener la tabla NashvilleHousing$ con su respectiva informacion 
primero se debe importar el archivo excel NashvilleHousing.xlsx a la base de datos daportfoliodb
mediante SSMS (SQL Server Management Studio).
*/

-- Revision de datos que se estarán usando
select * from daportfoliodb..NashvilleHousing$

-- Comparacion de la columna tipo de dato datetime vs la misma version date.
select SaleDate as FechaVentaDT, convert(date, SaleDate) as FechaVenta from daportfoliodb..NashvilleHousing$

-- La columna SaleDate se muestra en un formato de fecha y tiempo.
-- La parte tiempo no aporta ningun valor (00:00:00.000) por lo que se procede a dejar unicamente la fecha.
-- Para esto se cambiará el tipo de datos de la columna de datetime a date.
alter table NashvilleHousing$ alter column SaleDate date

-- Verificando el resultado
select SaleDate as Fecha from daportfoliodb..NashvilleHousing$

-- En la columna PropertyAddress se encuentra valores valores NULL, 
-- que tienen el mismo valor en la columna ParcelID pero con un valor que no es NULL.
select * from daportfoliodb..NashvilleHousing$ where PropertyAddress is null order by [UniqueID ], ParcelID

-- Evidenciando lo anterior
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from daportfoliodb..NashvilleHousing$ a
join daportfoliodb..NashvilleHousing$ b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
order by a.ParcelID

-- Se proceden a actualizar los valores NULL de la columna PropertyAddress que cumplen la condicion
update a set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from daportfoliodb..NashvilleHousing$ a
join daportfoliodb..NashvilleHousing$ b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- La columna PropertyAddress contiene información como direción y ciudad
-- que deberia estar en diferentes columnas.
select PropertyAddress from daportfoliodb..NashvilleHousing$

-- Extrayedo dirección y ciudad de la columna PropertyAddress
select substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1) as Direccion
, substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as Ciudad
from daportfoliodb..NashvilleHousing$

-- Creando una nueva columna para ciudad
alter table NashvilleHousing$ add PropertyCity nvarchar(255)

-- Rellenando la nueva columna ciudad
update NashvilleHousing$ set PropertyCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1 , len(PropertyAddress))

-- Actualizando la columna dirección
update NashvilleHousing$ set PropertyAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1)

-- Comprobación
select PropertyAddress, PropertyCity from daportfoliodb..NashvilleHousing$

-- Revisando la tabla OwnerAddress.
-- Es necesario extraer dirección, ciudad y estado.
select OwnerAddress from daportfoliodb..NashvilleHousing$

-- Consulta para extraer Dirección, Ciudad y Estado con substring()
select OwnerAddress as DireccionCompleta
, substring(OwnerAddress, 1, charindex(',', OwnerAddress) - 1) as Direccion
, substring(OwnerAddress, charindex(',', OwnerAddress) + 2, charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) - charindex(',', OwnerAddress) - 2) as Ciudad
, substring(OwnerAddress, charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) + 2, len(OwnerAddress) - charindex(',', OwnerAddress, charindex(',', OwnerAddress) + 1) - 1) as Estado
from NashvilleHousing$

-- Consulta para extraer Dirección, Ciudad y Estado con parsename()
select OwnerAddress as DireccionCompleta
, parsename(replace(OwnerAddress, ',', '.') , 3) as Direccion
, parsename(replace(OwnerAddress, ',', '.') , 2) as Ciudad
, parsename(replace(OwnerAddress, ',', '.') , 1) as Estado
from daportfoliodb..NashvilleHousing$

-- Creando una nueva tabla para guardar las ciudades extraídas
alter table NashvilleHousing$ add OwnerCity nvarchar(255);

-- Rellenando la nueva tabla con las ciudades extraídas
update NashvilleHousing$ set OwnerCity = parsename(replace(OwnerAddress, ',', '.') , 2)

-- Creando una nueva tabla para guardar los estados extraídos
alter table NashvilleHousing$ add OwnerState nvarchar(255)

-- Rellenando la nueva tabla con los estados extraídos
update NashvilleHousing$ set OwnerState = parsename(replace(OwnerAddress, ',', '.') , 1)

-- Actualizando la columna OwnerAddress
update NashvilleHousing$ set OwnerAddress = parsename(replace(OwnerAddress, ',', '.') , 3)

-- Revisando cambios
select OwnerAddress, OwnerCity, OwnerState from daportfoliodb..NashvilleHousing$

-- Verificando inconsistencias en los registros de la columna SoldAsVacant.
select distinct(SoldAsVacant), count(SoldAsVacant) as Total
from daportfoliodb..NashvilleHousing$
group by SoldAsVacant
order by SoldAsVacant

-- Sustituyendo todas las Y con Yes y N con No.
select SoldAsVacant
, case when SoldAsVacant = 'Y' then 'Yes' when SoldAsVacant = 'N' then 'No' else SoldAsVacant end as SoldAsVacant_Fixed
from daportfoliodb..NashvilleHousing$

-- Depurando inconsistencias en la tabla SoldAsVacant.
update NashvilleHousing$
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes' when SoldAsVacant = 'N' then 'No' else SoldAsVacant end

-- Encontrando y elminando registros duplicados.
with DuplicateRecordsCTE as (select *
, row_number() over(partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference order by UniqueID) DuplicateRecords
from daportfoliodb..NashvilleHousing$)

-- Encontrando.
select * from DuplicateRecordsCTE where DuplicateRecords > 1 order by [UniqueID ], ParcelID, PropertyAddress

-- Eliminando.
-- Antes de usar esta consulta debe omitirse o comentar la consulta para encontrar duplicados y viceversa.
--delete from DuplicateRecordsCTE where DuplicateRecords > 1

-- Eliminando columnas no usadas
--select * from daportfoliodb..NashvilleHousing$
--alter table daportfoliodb..NashvilleHousing$ drop column TaxDistrict


















