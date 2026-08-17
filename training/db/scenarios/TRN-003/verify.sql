SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-003' AND State = N'Applied')
    THROW 51003, 'TRN-003 scenario is not applied.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Product WHERE Id = 1 AND Deleted = 0 AND Gtin IS NULL)
    THROW 51003, 'TRN-003 nullable GTIN fixture is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Product_Category_Mapping WHERE ProductId = 1)
    THROW 51003, 'TRN-003 category fixture is missing.', 1;

SELECT p.Id, p.Sku, p.Gtin, COUNT(pcm.Id) AS CategoryCount
FROM dbo.Product p
JOIN dbo.Product_Category_Mapping pcm ON pcm.ProductId = p.Id
WHERE p.Id = 1
GROUP BY p.Id, p.Sku, p.Gtin;
