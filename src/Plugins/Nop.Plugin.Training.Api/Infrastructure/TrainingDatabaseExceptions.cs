namespace Nop.Plugin.Training.Api.Infrastructure;

public sealed class TrainingTransientDatabaseException : TimeoutException
{
    public TrainingTransientDatabaseException(string message) : base(message)
    {
    }
}

public sealed class TrainingPermanentDatabaseException : InvalidOperationException
{
    public TrainingPermanentDatabaseException(string message) : base(message)
    {
    }
}
