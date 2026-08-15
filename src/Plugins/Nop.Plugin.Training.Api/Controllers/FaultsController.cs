using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using Nop.Plugin.Training.Api.Infrastructure;
using Nop.Plugin.Training.Api.Models;

namespace Nop.Plugin.Training.Api.Controllers;

[ApiController]
public sealed class FaultsController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;
    private readonly TrainingFaultState _faultState;

    public FaultsController(IWebHostEnvironment environment, TrainingFaultState faultState)
    {
        _environment = environment;
        _faultState = faultState;
    }

    [HttpPost("/api/internal/training/faults/{profile}")]
    public ActionResult<FaultProfileResponse> Set(string profile)
    {
        if (!_environment.IsDevelopment())
            return NotFound();
        if (!_faultState.TrySet(profile))
            return BadRequest(new { code = "unknown_fault_profile" });

        return Ok(new FaultProfileResponse(_faultState.Profile));
    }
}
