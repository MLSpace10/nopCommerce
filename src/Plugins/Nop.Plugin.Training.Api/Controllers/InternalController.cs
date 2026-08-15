using Microsoft.AspNetCore.Mvc;
using Nop.Data;
using Nop.Plugin.Training.Api.Models;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class InternalController : ControllerBase
{
    private readonly INopDataProvider _dataProvider;

    public InternalController(INopDataProvider dataProvider)
    {
        _dataProvider = dataProvider;
    }

    [HttpGet("/api/internal/outbox")]
    public async Task<ActionResult<IReadOnlyList<OutboxMessageResponse>>> GetOutbox(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var messages = await _dataProvider.QueryAsync<OutboxMessageResponse>("""
            SELECT TOP (100) Id, MessageType, Payload, State, AttemptCount, CreatedUtc, ProcessedUtc
            FROM dbo.TrainingIntegrationMessage
            ORDER BY CreatedUtc, Id
            """);
        return Ok(messages);
    }
}
