using Microsoft.AspNetCore.Mvc;
using Nop.Plugin.Training.Api.Models;
using Nop.Services.Orders;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class PaymentsController : ControllerBase
{
    private readonly IOrderProcessingService _orderProcessingService;
    private readonly IOrderService _orderService;

    public PaymentsController(IOrderProcessingService orderProcessingService, IOrderService orderService)
    {
        _orderProcessingService = orderProcessingService;
        _orderService = orderService;
    }

    [HttpPost("/api/payments")]
    public async Task<ActionResult<OrderResponse>> Record(RecordPaymentRequest request, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var order = await _orderService.GetOrderByIdAsync(request.OrderId);
        if (order is null)
            return UnprocessableEntity(new { code = "order_not_found" });
        if (!_orderProcessingService.CanMarkOrderAsPaid(order))
            return Conflict(new { code = "order_cannot_be_marked_paid" });

        await _orderProcessingService.MarkOrderAsPaidAsync(order);
        return Ok(OrdersController.Map(order));
    }
}
