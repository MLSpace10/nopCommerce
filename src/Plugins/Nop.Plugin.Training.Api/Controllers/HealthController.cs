using Microsoft.AspNetCore.Mvc;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class HealthController : ControllerBase
{
    [HttpGet("/api/health")]
    public IActionResult Get()
    {
        return Ok(new { status = "healthy", service = "training-api" });
    }
}
