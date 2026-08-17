using System.Security;
using Microsoft.AspNetCore.Mvc;
using Nop.Core.Domain.Orders;
using Nop.Core.Domain.Payments;
using Nop.Core.Domain.Shipping;
using Nop.Core.Domain.Tax;
using Nop.Plugin.Training.Api.Models;
using Nop.Plugin.Training.Api.Infrastructure;
using Nop.Services.Catalog;
using Nop.Services.Customers;
using Nop.Services.Orders;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class OrdersController : ControllerBase
{
    private readonly ICustomNumberFormatter _customNumberFormatter;
    private readonly ICustomerService _customerService;
    private readonly IOrderProcessingService _orderProcessingService;
    private readonly IOrderService _orderService;
    private readonly IProductService _productService;
    private readonly TrainingFaultState _faultState;

    public OrdersController(
        ICustomNumberFormatter customNumberFormatter,
        ICustomerService customerService,
        IOrderProcessingService orderProcessingService,
        IOrderService orderService,
        IProductService productService,
        TrainingFaultState faultState)
    {
        _customNumberFormatter = customNumberFormatter;
        _customerService = customerService;
        _orderProcessingService = orderProcessingService;
        _orderService = orderService;
        _productService = productService;
        _faultState = faultState;
    }

    [HttpPost("/api/orders")]
    public async Task<ActionResult<OrderResponse>> Create(CreateOrderRequest request, CancellationToken cancellationToken)
    {
        if (request.Quantity is < 1 or > 100)
            return BadRequest(new { code = "invalid_quantity" });

        var idempotencyKey = Request.Headers["Idempotency-Key"].ToString();
        if (idempotencyKey.Length > 128)
            return BadRequest(new { code = "invalid_idempotency_key" });

        cancellationToken.ThrowIfCancellationRequested();
        var customer = await _customerService.GetCustomerByIdAsync(request.CustomerId);
        if (customer is null)
            return UnprocessableEntity(new { code = "customer_not_found" });
        if (customer.BillingAddressId is null)
            return UnprocessableEntity(new { code = "customer_billing_address_required" });

        var product = await _productService.GetProductByIdAsync(request.ProductId);
        if (product is null)
            return UnprocessableEntity(new { code = "product_not_found" });

        var total = product.Price * request.Quantity;
        var order = new Order
        {
            OrderGuid = Guid.NewGuid(),
            StoreId = 1,
            CustomerId = customer.Id,
            BillingAddressId = customer.BillingAddressId.Value,
            ShippingAddressId = customer.ShippingAddressId,
            OrderStatus = OrderStatus.Pending,
            ShippingStatus = product.IsShipEnabled ? ShippingStatus.NotYetShipped : ShippingStatus.ShippingNotRequired,
            PaymentStatus = PaymentStatus.Pending,
            PaymentMethodSystemName = "Payments.Manual",
            CustomerCurrencyCode = "USD",
            CurrencyRate = 1m,
            CustomerTaxDisplayType = TaxDisplayType.ExcludingTax,
            VatNumber = string.Empty,
            OrderSubtotalInclTax = total,
            OrderSubtotalExclTax = total,
            OrderTotal = total,
            TaxRates = string.Empty,
            CheckoutAttributeDescription = string.Empty,
            CheckoutAttributesXml = string.Empty,
            CustomerLanguageId = 1,
            CustomerIp = string.Empty,
            AuthorizationTransactionId = string.Empty,
            AuthorizationTransactionCode = string.Empty,
            AuthorizationTransactionResult = string.Empty,
            CaptureTransactionId = string.Empty,
            CaptureTransactionResult = string.Empty,
            SubscriptionTransactionId = string.Empty,
            ShippingMethod = string.Empty,
            ShippingRateComputationMethodSystemName = string.Empty,
            CustomValuesXml = string.IsNullOrWhiteSpace(idempotencyKey)
                ? string.Empty
                : $"<Training><IdempotencyKey>{SecurityElement.Escape(idempotencyKey)}</IdempotencyKey></Training>",
            CustomOrderNumber = string.Empty,
            CreatedOnUtc = DateTime.UtcNow
        };

        await _orderService.InsertOrderAsync(order);
        order.CustomOrderNumber = _customNumberFormatter.GenerateOrderCustomNumber(order);
        await _orderService.UpdateOrderAsync(order);

        await _orderService.InsertOrderItemAsync(new OrderItem
        {
            OrderItemGuid = Guid.NewGuid(),
            OrderId = order.Id,
            ProductId = product.Id,
            Quantity = request.Quantity,
            UnitPriceInclTax = product.Price,
            UnitPriceExclTax = product.Price,
            PriceInclTax = total,
            PriceExclTax = total,
            OriginalProductCost = product.ProductCost,
            AttributeDescription = string.Empty,
            AttributesXml = string.Empty,
            ItemWeight = product.Weight
        });

        await _productService.AdjustInventoryAsync(product, -request.Quantity, message: $"Training API order {order.Id}");
        cancellationToken.ThrowIfCancellationRequested();
        await _faultState.DelayOrderResponseAsync();

        return CreatedAtAction(nameof(GetById), new { orderId = order.Id }, Map(order));
    }

    [HttpGet("/api/orders/{orderId:int}")]
    public async Task<ActionResult<OrderResponse>> GetById(int orderId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var order = await _orderService.GetOrderByIdAsync(orderId);
        return order is null ? NotFound() : Ok(Map(order));
    }

    [HttpPost("/api/orders/{orderId:int}/cancel")]
    public async Task<ActionResult<OrderResponse>> Cancel(int orderId, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var order = await _orderService.GetOrderByIdAsync(orderId);
        if (order is null)
            return NotFound();
        if (!_orderProcessingService.CanCancelOrder(order))
            return Conflict(new { code = "order_cannot_be_cancelled" });

        await _orderProcessingService.CancelOrderAsync(order, notifyCustomer: false);
        return Ok(Map(order));
    }

    internal static OrderResponse Map(Order order)
    {
        return new OrderResponse(order.Id, order.OrderGuid, order.CustomerId, order.OrderStatus.ToString(),
            order.PaymentStatus.ToString(), order.OrderTotal, order.CustomerCurrencyCode, order.CreatedOnUtc);
    }
}
