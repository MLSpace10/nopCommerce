SET NOCOUNT ON;

IF DB_NAME() <> N'CommerceEngineeringLab'
    THROW 51100, 'Refusing API verification outside CommerceEngineeringLab.', 1;

DECLARE @OrderId int = $(OrderId);

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.[Order]
    WHERE Id = @OrderId
      AND OrderStatusId = 40
      AND PaymentStatusId = 30
      AND LEN(CustomOrderNumber) > 0
)
    THROW 51101, 'Expected cancelled, paid training order was not persisted.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.OrderItem WHERE OrderId = @OrderId AND Quantity > 0)
    THROW 51102, 'Expected training order item was not persisted.', 1;

SELECT o.Id AS OrderId,
       o.OrderStatusId,
       o.PaymentStatusId,
       o.OrderTotal,
       COUNT_BIG(oi.Id) AS OrderItemCount
FROM dbo.[Order] o
JOIN dbo.OrderItem oi ON oi.OrderId = o.Id
WHERE o.Id = @OrderId
GROUP BY o.Id, o.OrderStatusId, o.PaymentStatusId, o.OrderTotal;
