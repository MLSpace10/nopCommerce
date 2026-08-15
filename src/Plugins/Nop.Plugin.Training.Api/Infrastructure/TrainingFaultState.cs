namespace Nop.Plugin.Training.Api.Infrastructure;

public sealed class TrainingFaultState
{
    private static readonly HashSet<string> _allowedProfiles = new(StringComparer.OrdinalIgnoreCase)
    {
        "none",
        "database-transient",
        "http-timeout",
        "connection-reset"
    };

    private string _profile = "none";

    public string Profile => Volatile.Read(ref _profile);

    public bool TrySet(string profile)
    {
        if (!_allowedProfiles.Contains(profile))
            return false;

        Interlocked.Exchange(ref _profile, profile.ToLowerInvariant());
        return true;
    }
}
