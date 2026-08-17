SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.TrainingIdempotencyRecord', N'U') IS NOT NULL
    DELETE FROM dbo.TrainingIdempotencyRecord WHERE IdempotencyKey LIKE N'trn012-%';

DECLARE @Restock int =
(
    SELECT COALESCE(SUM(oi.Quantity), 0)
    FROM dbo.OrderItem oi
    JOIN dbo.[Order] o ON o.Id = oi.OrderId
    WHERE o.CustomValuesXml LIKE N'%<IdempotencyKey>trn012-%'
      AND oi.ProductId = 1
);

UPDATE dbo.Product SET StockQuantity = StockQuantity + @Restock WHERE Id = 1;
DELETE oi FROM dbo.OrderItem oi JOIN dbo.[Order] o ON o.Id = oi.OrderId
WHERE o.CustomValuesXml LIKE N'%<IdempotencyKey>trn012-%';
DELETE FROM dbo.[Order] WHERE CustomValuesXml LIKE N'%<IdempotencyKey>trn012-%';
DELETE FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-012';

COMMIT TRANSACTION;
