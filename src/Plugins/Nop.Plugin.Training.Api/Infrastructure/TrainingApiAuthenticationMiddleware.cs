using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;

namespace Nop.Plugin.Training.Api.Infrastructure;

public sealed class TrainingApiAuthenticationMiddleware
{
    public const string HeaderName = "X-Training-Api-Key";

    private readonly RequestDelegate _next;

    public TrainingApiAuthenticationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Path.StartsWithSegments("/api") ||
            context.Request.Path.Equals("/api/health") ||
            context.Request.Path.Equals("/api/openapi.yaml"))
        {
            await _next(context);
            return;
        }

        var configuredKey = Environment.GetEnvironmentVariable("TRAINING_API_KEY");
        if (string.IsNullOrWhiteSpace(configuredKey))
        {
            context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
            await context.Response.WriteAsJsonAsync(new { code = "api_key_not_configured" }, context.RequestAborted);
            return;
        }

        var suppliedKey = context.Request.Headers[HeaderName].ToString();
        var configuredHash = SHA256.HashData(Encoding.UTF8.GetBytes(configuredKey));
        var suppliedHash = SHA256.HashData(Encoding.UTF8.GetBytes(suppliedKey));

        if (!CryptographicOperations.FixedTimeEquals(configuredHash, suppliedHash))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsJsonAsync(new { code = "invalid_api_key" }, context.RequestAborted);
            return;
        }

        await _next(context);
    }
}
