-- ==============================
-- Nashville Housing Data Cleaning
-- ==============================

-- 1. Inspect Original Data
SELECT *
FROM PortfolioProjects..[Nashville Housing];

---------------------------------------------------
-- 2. Standardize SaleDate Format
---------------------------------------------------

SELECT SaleDate, CONVERT(Date, SaleDate) AS Date_Fixed
FROM PortfolioProjects..[Nashville Housing];

UPDATE [Nashville Housing]
SET SaleDate = CONVERT(Date, SaleDate);

ALTER TABLE [Nashville Housing]
ALTER COLUMN SaleDate Date;

---------------------------------------------------
-- 3. Populate Missing Property Addresses
---------------------------------------------------

SELECT *
FROM PortfolioProjects..[Nashville Housing]
ORDER BY ParcelID ASC;

SELECT T1.ParcelID, T1.PropertyAddress, T2.ParcelID, T2.PropertyAddress, 
       ISNULL(T1.PropertyAddress, T2.PropertyAddress)
FROM PortfolioProjects..[Nashville Housing] AS T1
JOIN PortfolioProjects..[Nashville Housing] AS T2
  ON T1.ParcelID = T2.ParcelID
  AND T1.[UniqueID] <> T2.[UniqueID]
WHERE T1.PropertyAddress IS NULL;


UPDATE T1
SET PropertyAddress = ISNULL(T1.PropertyAddress, T2.PropertyAddress)
FROM PortfolioProjects..[Nashville Housing] AS T1
JOIN PortfolioProjects..[Nashville Housing] AS T2
  ON T1.ParcelID = T2.ParcelID
  AND T1.[UniqueID] <> T2.[UniqueID]
WHERE T1.PropertyAddress IS NULL;

---------------------------------------------------
-- 4. Split Property Address into Components
---------------------------------------------------

SELECT PropertyAddress
FROM PortfolioProjects..[Nashville Housing];

ALTER TABLE [Nashville Housing] ADD PropertySplitAddress NVARCHAR(255);
ALTER TABLE [Nashville Housing] ADD Property_Split_City NVARCHAR(255);

UPDATE [Nashville Housing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

UPDATE [Nashville Housing]
SET Property_Split_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

---------------------------------------------------
-- 5. Split Owner Address into Components
---------------------------------------------------

SELECT OwnerAddress
FROM PortfolioProjects..[Nashville Housing];

ALTER TABLE [Nashville Housing] ADD OwnerSplitAddress NVARCHAR(255);
ALTER TABLE [Nashville Housing] ADD OwnerSplitCity NVARCHAR(255);
ALTER TABLE [Nashville Housing] ADD OwnerSplitState NVARCHAR(255);

UPDATE [Nashville Housing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE [Nashville Housing]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE [Nashville Housing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

---------------------------------------------------
-- 6. Standardize SoldAsVacant Field
---------------------------------------------------
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProjects..[Nashville Housing]
GROUP BY SoldAsVacant
ORDER BY 2;

UPDATE [Nashville Housing]
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

---------------------------------------------------
-- 7. Remove Duplicate Rows
---------------------------------------------------
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, LegalReference, SaleDate
               ORDER BY UniqueID
           ) AS Row_num
    FROM PortfolioProjects..[Nashville Housing]
)
DELETE FROM CTE
WHERE Row_num > 1;

---------------------------------------------------
-- 8. Drop Unnecessary Columns
---------------------------------------------------
ALTER TABLE PortfolioProjects..[Nashville Housing]
DROP COLUMN PropertyAddress, TaxDistrict, OwnerAddress;

---------------------------------------------------
-- 9. Final Cleaned Data
---------------------------------------------------
SELECT *
FROM PortfolioProjects..[Nashville Housing];















