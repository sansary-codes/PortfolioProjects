                       -- DATA CLEANING WITH THE NASHVILLE HOUSING DATASET --

    -- Looking at the data --
SELECT *
FROM PortfolioProject..NashvilleHousing

   
   
   -- Changing the SaleDate from the date/time format to just date --

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)  --This didn't work 

ALTER TABLE NashvilleHousing  -- Another method
ADD SaleDateConverted date
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDateConverted, CONVERT(date, SaleDate) AS Date
FROM PortfolioProject..NashvilleHousing -- This worked
SELECT *
FROM PortfolioProject..NashvilleHousing -- SaleDateConverted at end of table




    -- Looking at the Property Address column -- 
SELECT *
FROM NashvilleHousing -- Some repeats, some zeros, some nulls
WHERE PropertyAddress IS NULL -- 29 addresses are null

SELECT *
FROM NashvilleHousing
ORDER BY ParcelID -- Where ParcelID are the same, the addresses are also the same
                  -- We can combine them by using SELF-JOIN

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]  -- SELF-JOINING while keeping one of the UniqueIDs
                                       -- Notice how one PropertyAddress is filled while the other side would say NULL
WHERE a.PropertyAddress IS NULL -- where a.PropertyAddress is null, b.PropertyAddress has the address
                                
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
       ISNULL(a.PropertyAddress, b.PropertyAddress) -- Use ISNULL to fill out a's property address with b's
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]  -- SELF-JOINING while keeping one of the UniqueIDs
                                       -- Notice how one PropertyAddress is filled while the other side would say NULL
WHERE a.PropertyAddress IS NULL 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
   ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL -- 29 rows affected, exactly how many nulls there were




    -- Breaking PropertyAddress into Address and City --

SELECT PropertyAddress
FROM NashvilleHousing  -- Street name and city within PropertyAddress column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
                                  -- This will not only stop at the comma, but also omit it from the addresses
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
                                  -- Going to the comma, omitting it from city name, and going to the end of the word
FROM PortfolioProject..NashvilleHousing 

ALTER TABLE NashvilleHousing  -- Adding new address column to original table
ADD PropertySplitAddress nvarchar(255);
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing  -- Adding new city column to original table
ADD PropertySplitCity nvarchar(255);
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing -- It worked! New columns of address & city at the end of table




    -- Looking at OwnerAddress column and breaking it into Address, City, and State --
SELECT OwnerAddress
FROM NashvilleHousing  -- Address, city, and state are combined

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State-- Splitting into address, city, and state
                                              -- Funny how we have to number it in reverse
FROM NashvilleHousing

ALTER TABLE NashvilleHousing  -- Adding new address column to original table
ADD OwnerSplitAddress nvarchar(255);
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing  -- Adding new city column to original table
ADD OwnerSplitCity nvarchar(255);
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing  -- Adding new state column to original table
ADD OwnerSplitState nvarchar(255);
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
     -- Remember to run ALTER TABLE query then UPDATE query!

SELECT *
FROM NashvilleHousing -- It worked! The three columns are at the end of the table




    -- Changing the SoldAsVacant column to only "Yes" and "No" -- 
SELECT DISTINCT(SoldAsVacant),COUNT (SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 -- Yes and No are a lot more used, but 399 N and 52 Y

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END 
FROM NashvilleHousing 

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                        END 
                -- This worked when I ran the previous SELECT statement after running this
                -- Because we're not splitting columns, just altering words within the same column,
                -- we don't have to do ALTER TABLE and add a new column with just "Yes" and "No"
                -- It is possible to do that though, but not necessary




    -- Removing Duplicates -- 
WITH RowNumCTE AS(
SELECT *,
  ROW_NUMBER() OVER(
  PARTITION BY ParcelID,
               PropertyAddress,
               SalePrice,
               SaleDate,
               LegalReference
               ORDER BY UniqueID
               ) AS row_num
FROM PortfolioProject..NashvilleHousing )
                   -- row_num column has been added, and everytime there is a COMPLETE duplicate
                   -- all the way across the row, the row_num will be 2 instead of 1
                   -- Our goal to get rid of the 2nd copies
DELETE              -- Remember to run the SELECT query first with the CTE creation query to double-check
FROM RowNumCTE      -- Then change the SELECT to DELETE; remember to use DELETE cautiously
WHERE row_num > 1
                   -- After you delete, run the SELECT statement again including the
                   -- CTE creation query; if nothing comes up, then it worked




    -- Deleting Unused Columns -- 
-- Remember, don't delete from the raw data! This is just an example
-- The columns we're deleting will be the old PropertyAddress and OwnerAddress columns, 
-- since we created the separated columns for them

SELECT *
FROM NashvilleHousing -- Looking at columns before altering

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate  -- Also getting rid of SaleDate since we have SaleDateConverted

SELECT *
FROM NashvilleHousing -- Now these columns are gone


                        -- END OF DATA CLEANING PORTFOLIO PROJECT --








                

