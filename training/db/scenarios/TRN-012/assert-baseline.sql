SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Key nvarchar(128) = N'$(IdempotencyKey)';
DECLARE @OrderCount int =
(
    SELECT COUNT(*) FROM dbo.[Order]
    WHERE CustomValuesXml LIKE N'%<IdempotencyKey>' + @Key + N'</IdempotencyKey>%'
);

IF @OrderCount < 2
    THROW 51012, 'TRN-012 baseline defect was not reproduced: expected duplicate orders.', 1;

SELECT @Key AS IdempotencyKey, @OrderCount AS DuplicateOrderCount;
