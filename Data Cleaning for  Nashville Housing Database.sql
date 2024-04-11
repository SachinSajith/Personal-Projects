-- Clean data in SQL queries.

-- 1. Display the current data in the table.
SELECT *
FROM public.nashville_housing;

-- 2. Standardize the Date Format.
-- Selecting and displaying the saledate column with standardized date format.
SELECT saledate::date
FROM public.nashville_housing;

-- 3. Update the saledate column in the table to have standardized date format.
ALTER TABLE public.nashville_housing
    ADD saledate_new DATE;

UPDATE public.nashville_housing
SET saledate_new = saledate::date;

-- 4. Populate Property Address Data.
SELECT a.propertyaddress, b.propertyaddress, 
    CASE 
        WHEN a.propertyaddress IS NULL THEN b.propertyaddress 
        ELSE a.propertyaddress 
    END AS propertyaddress
FROM public.nashville_housing a
JOIN public.nashville_housing b
    ON a.parcelid = b.parcelid AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS NULL;

UPDATE public.nashville_housing
SET propertyaddress = 
    CASE 
        WHEN a.propertyaddress IS NULL THEN b.propertyaddress 
        ELSE a.propertyaddress 
    END
FROM public.nashville_housing a
JOIN public.nashville_housing b
    ON a.parcelid = b.parcelid AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS NULL;

-- 5. Breaking out the address into individual columns (Address, City, State)
SELECT 
    SUBSTRING(propertyaddress, 1, STRPOS(propertyaddress, ',') - 1) AS Address,
    SUBSTRING(propertyaddress, STRPOS(propertyaddress, ',') + 1, LENGTH(propertyaddress)) AS Address2
FROM public.nashville_housing;

ALTER TABLE public.nashville_housing
    ADD propertysplitaddress TEXT;

UPDATE public.nashville_housing
SET propertysplitaddress = SUBSTRING(propertyaddress, 1, STRPOS(propertyaddress, ',') - 1);

ALTER TABLE public.nashville_housing
    ADD propertysplitcity TEXT;

UPDATE public.nashville_housing
SET propertysplitcity = SUBSTRING(propertyaddress, STRPOS(propertyaddress, ',') + 1, LENGTH(propertyaddress));

-- Breaking out the Owner-address.
SELECT 
    SPLIT_PART(owneraddress, ',', 1) AS address,
    SPLIT_PART(owneraddress, ',', 2) AS city,
    SPLIT_PART(owneraddress, ',', 3) AS state
FROM public.nashville_housing;

ALTER TABLE public.nashville_housing
    ADD ownersplitaddress TEXT;

UPDATE public.nashville_housing
SET ownersplitaddress = SPLIT_PART(owneraddress, ',', 1);

ALTER TABLE public.nashville_housing
    ADD ownersplitcity TEXT;

UPDATE public.nashville_housing
SET ownersplitcity = SPLIT_PART(owneraddress, ',', 2);

ALTER TABLE public.nashville_housing
    ADD ownersplitstate TEXT;

UPDATE public.nashville_housing
SET ownersplitstate = SPLIT_PART(owneraddress, ',', 3);

-- Change Y and N to 'Yes' and 'No' in the field 'Sold as Vacant' field.
SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM public.nashville_housing
GROUP BY soldasvacant;

SELECT 
    soldasvacant,
    CASE 
        WHEN soldasvacant = 'N' THEN 'No'
        WHEN soldasvacant = 'Y' THEN 'Yes'
        ELSE soldasvacant
    END AS sold
FROM public.nashville_housing;

UPDATE public.nashville_housing
SET soldasvacant = 
    CASE 
        WHEN soldasvacant = 'N' THEN 'No' 
        WHEN soldasvacant = 'Y' THEN 'Yes' 
        ELSE soldasvacant 
    END;

-- Remove Duplicates
DELETE FROM public.nashville_housing
WHERE uniqueid IN (
    SELECT uniqueid
    FROM (
        SELECT uniqueid,
            ROW_NUMBER() OVER (
                PARTITION BY parcelid,
                             propertyaddress,
                             saleprice,
                             saledate,
                             legalreference
                ORDER BY uniqueid
            ) AS row_num
        FROM public.nashville_housing
    ) AS subquery
    WHERE row_num > 1
);

-- Delete Unused Columns 
SELECT *
FROM public.nashville_housing;

ALTER TABLE public.nashville_housing
    DROP COLUMN owneraddress,
    DROP COLUMN taxdistrict,
    DROP COLUMN propertyaddress,
    DROP COLUMN saledate_new;
