SELECT *
FROM NashvilleHousing

--standardise data format

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Property Address can be populated based off a ref point (ParcelID)

SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NU
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

--ISNULL checks to see if the expression has NULL values

-- Breaking 'Adress' into Indiv Columns (Address, City, State)
SELECT PropertyAddress
FROM NashvilleHousing
--WHERE PropertyAddress is NULL
-- ORDER BY ParcelID

SELECT
--Character Index
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS Address
FROM NashvilleHousing

--Filtering characters until ',' and going back by 1 character to eliminate the ','

--If you want to separate items into two, you must create two corresponding columns.
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Parsename (instead of substring) is useful for periods

SELECT OwnerAddress
FROM NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3) 
, PARSENAME(REPLACE(OwnerAddress,',','.'),2)
, PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3) 

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--Change 1 and 0 to Yes and No
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
,	CASE WHEN SoldAsVacant = 1 THEN 'Yes'
		 WHEN SoldAsVacant = 0 THEN 'No'
		 ELSE CAST(SoldAsVacant AS VARCHAR)
		 END 
FROM NashvilleHousing;

-- Removing Duplicates through the CTE

WITH rownumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM rownumCTE
WHERE row_num>1
ORDER BY PropertyAddress

--Delete Unused Columns
SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict;

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate;