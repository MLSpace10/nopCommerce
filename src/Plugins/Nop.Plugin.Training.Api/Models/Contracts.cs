namespace Nop.Plugin.Training.Api.Models;

public sealed record CustomerResponse(int Id, string Email, bool Active, DateTime CreatedOnUtc, int? BillingAddressId);

public sealed record ProductResponse(int Id, string Name, string Sku, decimal Price, bool Published);

public sealed record InventoryResponse(int ProductId, string ManageInventoryMethod, int StockQuantity);

public sealed record OrderResponse(
    int Id,
    Guid OrderGuid,
    int CustomerId,
    string OrderStatus,
    string PaymentStatus,
    decimal Total,
    string CurrencyCode,
    DateTime CreatedOnUtc);

public sealed record CreateOrderRequest(int CustomerId, int ProductId, int Quantity);

public sealed record RecordPaymentRequest(int OrderId);

public sealed record FaultProfileRequest(string Profile);

public sealed record FaultProfileResponse(string Profile);

public sealed class OutboxMessageResponse
{
    public Guid Id { get; set; }

    public string MessageType { get; set; } = string.Empty;

    public string Payload { get; set; } = string.Empty;

    public string State { get; set; } = string.Empty;

    public int AttemptCount { get; set; }

    public DateTime CreatedUtc { get; set; }

    public DateTime? ProcessedUtc { get; set; }
}

public sealed record PagedResponse<T>(IReadOnlyList<T> Items, int PageIndex, int PageSize, int TotalCount);
