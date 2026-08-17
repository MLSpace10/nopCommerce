SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.TrainingIdempotencyRecord', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrainingIdempotencyRecord
    (
        IdempotencyKey nvarchar(128) NOT NULL CONSTRAINT PK_TrainingIdempotencyRecord PRIMARY KEY,
        RequestHash char(64) NOT NULL,
        OrderId int NOT NULL,
        ResponseStatus int NOT NULL,
        ResponseBody nvarchar(max) NOT NULL,
        CreatedUtc datetime2(3) NOT NULL
    );
END;

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

MERGE dbo.TrainingScenarioState AS target
USING (VALUES (N'TRN-012', N'Applied', SYSUTCDATETIME())) AS source(ScenarioId, State, AppliedUtc)
ON target.ScenarioId = source.ScenarioId
WHEN MATCHED THEN UPDATE SET State = source.State, AppliedUtc = source.AppliedUtc
WHEN NOT MATCHED THEN INSERT (ScenarioId, State, AppliedUtc) VALUES (source.ScenarioId, source.State, source.AppliedUtc);

COMMIT TRANSACTION;
