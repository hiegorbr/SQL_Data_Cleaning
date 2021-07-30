-- 1. Criando a tabela de apoio para importar os dados

CREATE TABLE NashvilleHousing (UniqueID VARCHAR(255),
							   ParcelID VARCHAR(255),
							   LandUse VARCHAR(255),
							   PropertyAddress VARCHAR(255),
							   SaleDate TIMESTAMP,
							   SalePrice VARCHAR(255),
							   LegalReference VARCHAR(255),
							   SoldAsVacant VARCHAR(3),
							   OwnerName VARCHAR(255),
							   OwnerAddress VARCHAR(255),
							   Acreage NUMERIC,
							   TaxDistrict VARCHAR(255),
							   LandValue NUMERIC,
							   BuildingValue NUMERIC,
							   TotalValue NUMERIC,
							   YearBuilt INT,
							   Bedrooms	INT,
							   FullBath	INT, 
							   HalfBath INT
)
;


-- 2. Importando os dados

COPY NashvilleHousing

FROM 'C:\Users\hieeg\Documents\Portfolio\Data_Cleaning_SQL\Nashville_Housing_Data.csv'

DELIMITER ';'

CSV HEADER
;

-- 3. Analisando os dados no geral

SELECT *

FROM NashvilleHousing
;


-- 4. Transformando a data de venda em um formato de data comum

SELECT saledate, CAST(saledate AS DATE)
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ALTER COLUMN saledate TYPE DATE;

SELECT saledate
FROM NashvilleHousing;


-- 5. Preenchendo os espaços vazios na coluna de endereços

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Podemos notar que uma das colunas nos dá o ParcelID, que é uma forma de identificação do endereço
-- Vamos buscar endereços que não estejam preenchidos porém tenham o ParcelID igual a uma linha que tenha o registro preenchido
-- Para isso, vamos fazer um Self Join, e comparar os NULLs com os preenchidos através do ParcelID

SELECT t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress, NULLIF(t2.PropertyAddress, t1.PropertyAddress)
FROM NashvilleHousing t1
JOIN NashvilleHousing t2
	ON t1.ParcelID = t2.ParcelID
	and t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL;


-- 6. Dividindo a coluna de endereços

SELECT PropertyAddress
FROM NashvilleHousing


-- A coluna de endereços possui a informação de endereço e a da cidade, separados por vírgulas
-- Vamos criar uma nova coluna para as cidades para os nossos dados ficarem mais organizados

SELECT 
	SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, POSITION(',' in PropertyAddress) +1) AS City

FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD COLUMN Address VARCHAR(255);

ALTER TABLE NashvilleHousing
ADD COLUMN City VARCHAR(255);

UPDATE NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) - 1);

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, POSITION(',' in PropertyAddress) + 1);

SELECT PropertyAddress, Address, City
FROM NashvilleHousing


-- Agora faremos o mesmo com o endereço do dono

SELECT SPLIT_PART(OwnerAddress, ',', 1) AS OwnerCityAddress,
		SPLIT_PART(OwnerAddress, ',', 2) AS OwnerCity,
		SPLIT_PART(OwnerAddress, ',', 3) AS OwnerState
		
FROM NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerCityAddress VARCHAR(255);

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerCity VARCHAR(255);

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerState VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerCityAddress = SPLIT_PART(OwnerAddress, ',', 1);

UPDATE NashvilleHousing
SET OwnerCity = SPLIT_PART(OwnerAddress, ',', 2);

UPDATE NashvilleHousing
SET OwnerState = SPLIT_PART(OwnerAddress, ',', 3);


SELECT OwnerAddress, OwnerCityAddress, OwnerCity, OwnerState

FROM NashvilleHousing;


-- 7. Padronizar as respostas do 'Sold as Vacant'

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;

-- Temos 2 tipos de resposta para cada opção, então vamos padronizar
-- Substituiremos o Y por Yes e o N por No

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END
;

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;


-- 8. Ver os dados duplicados

-- Consideraremos como duplicados os dados que apresentarem os mesmos: ParcelID, PropertyAddress, SalePrice, SaleDate e LegalReference

SELECT *, COUNT(*) OVER (PARTITION BY ParcelID,
											PropertyAddress,
											SalePrice,
											SaleDate,
											LegalReference
							ORDER BY UniqueID) num
FROM NashvilleHousing

-- Com os dados separados por categoria, olharemos apenas os que possuem dados iguais

WITH duplicates as (SELECT *, COUNT(*) OVER (PARTITION BY ParcelID,
											PropertyAddress,
											SalePrice,
											SaleDate,
											LegalReference
							ORDER BY UniqueID) num
FROM NashvilleHousing)

SELECT *
FROM duplicates
WHERE num > 1;

-- Removeremos os dados que estão duplicados

WITH duplicates as (SELECT *, COUNT(*) OVER (PARTITION BY ParcelID,
											PropertyAddress,
											SalePrice,
											SaleDate,
											LegalReference
					ORDER BY UniqueID) num
					FROM NashvilleHousing);


DELETE FROM NashvilleHousing nh
Where nh.UniqueID IN (SELECT UniqueID 
					  FROM duplicates
					  WHERE num > 1);
					  


-- 9. Limpar as colunas que não utilizaremos

SELECT *
FROM NashvilleHousing

-- Removeremos as 2 colunas que já fizemos a separação anteriormente e a coluna TaxDistrict

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress;

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress;

ALTER TABLE NashvilleHousing
DROP COLUMN TaxDistrict;






