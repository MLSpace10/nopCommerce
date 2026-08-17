SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Key nvarchar(128) = N'$(IdempotencyKey)';
DECLARE @OrderCount int =
(
    SELECT COUNT(*) FROM dbo.[Order]
    WHERE CustomValuesXml LIKE N'%<IdempotencyKey>' + @Key + N'</IdempotencyKey>%'
);

IF @OrderCount <> 1
    THROW 51012, 'Expected exactly one order for the idempotency key.', 1;

SELECT @Key AS IdempotencyKey, @OrderCount AS OrderCount;
