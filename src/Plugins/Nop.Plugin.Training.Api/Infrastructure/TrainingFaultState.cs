namespace Nop.Plugin.Training.Api.Infrastructure;

public sealed class TrainingFaultState
{
    private static readonly HashSet<string> _allowedProfiles = new(StringComparer.OrdinalIgnoreCase)
    {
        "none",
        "database-transient",
        "database-permanent",
        "order-response-timeout",
        "http-timeout",
        "connection-reset"
    };

    private int _attempts;
    private string _profile = "none";

    public int Attempts => Volatile.Read(ref _attempts);

    public string Profile => Volatile.Read(ref _profile);

    public bool TrySet(string profile)
    {
        if (!_allowedProfiles.Contains(profile))
            return false;

        Interlocked.Exchange(ref _attempts, 0);
        Interlocked.Exchange(ref _profile, profile.ToLowerInvariant());
        return true;
    }

    public void BeforeProductRead()
    {
        switch (Profile)
        {
            case "database-transient":
                if (Interlocked.Increment(ref _attempts) <= 2)
                    throw new TrainingTransientDatabaseException("Controlled transient database timeout.");
                break;
            case "database-permanent":
                Interlocked.Increment(ref _attempts);
                throw new TrainingPermanentDatabaseException("Controlled permanent database failure.");
        }
    }

    public async Task DelayOrderResponseAsync()
    {
        if (Profile == "order-response-timeout" && Interlocked.Increment(ref _attempts) == 1)
            await Task.Delay(TimeSpan.FromSeconds(2.5), CancellationToken.None);
    }
}
