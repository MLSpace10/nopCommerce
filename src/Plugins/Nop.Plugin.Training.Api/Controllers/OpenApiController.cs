using System.Reflection;
using System.Text;
using Microsoft.AspNetCore.Mvc;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class OpenApiController : ControllerBase
{
    [HttpGet("/api/openapi.yaml")]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        await using var stream = Assembly.GetExecutingAssembly()
            .GetManifestResourceStream("Nop.Plugin.Training.Api.openapi.yaml");
        if (stream is null)
            return NotFound();

        using var reader = new StreamReader(stream, Encoding.UTF8);
        var content = await reader.ReadToEndAsync(cancellationToken);
        return Content(content, "application/yaml", Encoding.UTF8);
    }
}
