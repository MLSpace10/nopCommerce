using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Nop.Core.Infrastructure;

namespace Nop.Plugin.Training.Api.Infrastructure;

public sealed class TrainingApiStartup : INopStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<TrainingFaultState>();
    }

    public void Configure(IApplicationBuilder application)
    {
        application.UseMiddleware<TrainingApiAuthenticationMiddleware>();
    }

    public int Order => 510;
}
