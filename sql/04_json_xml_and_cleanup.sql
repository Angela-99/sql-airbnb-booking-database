-- JSON and XML handling, plus duplicate clean-up. Run after 01_restore_database.sql.
-- Changes data: run on a scratch copy if you want to keep the original state.
USE project;

-- 1. Read nested JSON fields from the review Analysis column
SELECT ReviewID,
       JSON_EXTRACT(Analysis, '$.sentiment_score')            AS sentiment,
       JSON_UNQUOTE(JSON_EXTRACT(Analysis, '$.aspects.cleanliness')) AS cleanliness
FROM reviews
LIMIT 5;

-- 2. Modify JSON: add a key, change a value, remove a key
UPDATE reviews
SET Analysis = JSON_SET(Analysis, '$.reviewed', TRUE)
WHERE ReviewID = 1;

UPDATE reviews
SET Analysis = JSON_SET(Analysis, '$.sentiment_score', 0.9)
WHERE ReviewID = 1;

UPDATE reviews
SET Analysis = JSON_REMOVE(Analysis, '$.reviewed')
WHERE ReviewID = 1;

-- 3. XML kept in a TEXT column (MySQL has no native XML type): edit with string functions
UPDATE propertytype
SET TypeDetails_XML = '<propertyType><name>Villa</name><features><luxury>true</luxury><bedrooms>5</bedrooms></features></propertyType>'
WHERE PropertyType = 'Villa' AND TypeDetails_XML IS NULL;

UPDATE propertytype
SET TypeDetails_XML = REPLACE(TypeDetails_XML, '</features>', '<hasGym>true</hasGym></features>')
WHERE PropertyType = 'Villa' AND TypeDetails_XML NOT LIKE '%hasGym%';

SELECT PropertyTypeID, PropertyType, ExtractValue(TypeDetails_XML, '/propertyType/features/bedrooms') AS bedrooms
FROM propertytype
WHERE TypeDetails_XML IS NOT NULL;

-- 4. Find duplicate property types (the dump has repeated Loft, Cabin and Apartment rows)
SELECT PropertyType, COUNT(*) AS copies, MIN(PropertyTypeID) AS keep_id
FROM propertytype
GROUP BY PropertyType
HAVING COUNT(*) > 1;

-- 5. Repoint properties to the row we keep, then remove the duplicates
--    (foreign keys use ON DELETE CASCADE, so repoint first or properties would be deleted)
UPDATE properties p
JOIN propertytype t  ON t.PropertyTypeID = p.PropertyTypeID
JOIN (SELECT PropertyType, MIN(PropertyTypeID) AS keep_id
      FROM propertytype GROUP BY PropertyType) k ON k.PropertyType = t.PropertyType
SET p.PropertyTypeID = k.keep_id
WHERE p.PropertyTypeID <> k.keep_id;

DELETE t
FROM propertytype t
JOIN (SELECT PropertyType, MIN(PropertyTypeID) AS keep_id
      FROM propertytype GROUP BY PropertyType) k ON k.PropertyType = t.PropertyType
WHERE t.PropertyTypeID <> k.keep_id;
