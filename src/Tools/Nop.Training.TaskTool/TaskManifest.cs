using YamlDotNet.Serialization;

namespace Nop.Training.TaskTool;

public sealed class TaskManifest
{
    public int SchemaVersion { get; set; }

    public string Id { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty;

    public string Difficulty { get; set; } = string.Empty;

    public int EstimatedMinutes { get; set; }

    public List<string> Prerequisites { get; set; } = [];

    public string BaselineBranch { get; set; } = string.Empty;

    public string ScenarioSeed { get; set; } = string.Empty;

    public List<string> AffectedApi { get; set; } = [];

    public List<string> RequiredServices { get; set; } = [];

    public string ReproduceCommand { get; set; } = string.Empty;

    public string VisibleVerificationCommand { get; set; } = string.Empty;

    public string HiddenVerificationCommand { get; set; } = string.Empty;

    public string ResetCommand { get; set; } = string.Empty;

    public List<string> CompatibilityConstraints { get; set; } = [];

    public List<string> LearningObjectives { get; set; } = [];
}

public sealed record ValidationIssue(string Path, string Message)
{
    public override string ToString() => $"{Path}: {Message}";
}
