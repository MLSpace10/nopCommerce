using Nop.Services.Common;
using Nop.Services.Helpers;
using Nop.Services.Plugins;

namespace Nop.Plugin.Training.Api;

public sealed class TrainingApiPlugin : BasePlugin, IMiscPlugin
{
    private readonly IWebHelper _webHelper;

    public TrainingApiPlugin(IWebHelper webHelper)
    {
        _webHelper = webHelper;
    }

    public override string GetConfigurationPageUrl()
    {
        return $"{_webHelper.GetStoreLocation()}api/openapi.yaml";
    }
}
