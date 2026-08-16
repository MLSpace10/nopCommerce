using System.Text.RegularExpressions;
using YamlDotNet.Core;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace Nop.Training.TaskTool;

public sealed partial class TaskManifestValidator
{
    private static readonly string[] RequiredStudentFiles =
    [
        "student-ticket.md",
        "reproduce.ps1",
        "expected-evidence.md"
    ];

    private static readonly HashSet<string> ForbiddenStudentNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "mentor-notes.md",
        "solution.patch",
        "hidden-tests",
        "review-checklist.md",
        "hints"
    };

    private static readonly HashSet<string> SupportedTypes = new(StringComparer.Ordinal)
    {
        "bug",
        "feature",
        "investigation",
        "database-change",
        "integration",
        "operational-audit"
    };

    private static readonly HashSet<string> SupportedDifficulties = new(StringComparer.Ordinal)
    {
        "beginner",
        "intermediate",
        "advanced"
    };

    private readonly IDeserializer _deserializer = new DeserializerBuilder()
        .WithNamingConvention(CamelCaseNamingConvention.Instance)
        .Build();

    public IReadOnlyList<ValidationIssue> Validate(string manifestPath, bool requireStudentArtifacts = true)
    {
        var issues = new List<ValidationIssue>();
        var fullManifestPath = Path.GetFullPath(manifestPath);
        if (!File.Exists(fullManifestPath))
            return [new ValidationIssue(fullManifestPath, "manifest.yaml does not exist")];

        TaskManifest? manifest;
        try
        {
            manifest = _deserializer.Deserialize<TaskManifest>(File.ReadAllText(fullManifestPath));
        }
        catch (YamlException exception)
        {
            return [new ValidationIssue(fullManifestPath, $"invalid YAML: {exception.Message}")];
        }

        if (manifest is null)
            return [new ValidationIssue(fullManifestPath, "manifest is empty")];

        ValidateFields(fullManifestPath, manifest, issues);
        if (requireStudentArtifacts)
            ValidateStudentDirectory(fullManifestPath, manifest, issues);

        return issues;
    }

    public IReadOnlyList<ValidationIssue> ValidateRepository(string repositoryRoot)
    {
        var issues = new List<ValidationIssue>();
        var tasksRoot = Path.Combine(Path.GetFullPath(repositoryRoot), "training", "tasks");
        if (!Directory.Exists(tasksRoot))
            return issues;

        foreach (var taskDirectory in Directory.EnumerateDirectories(tasksRoot))
        {
            var directoryName = Path.GetFileName(taskDirectory);
            if (!TaskIdPattern().IsMatch(directoryName))
                issues.Add(new ValidationIssue(taskDirectory, "task directory must match TRN-###"));
            var manifestPath = Path.Combine(taskDirectory, "manifest.yaml");
            if (!File.Exists(manifestPath))
                issues.Add(new ValidationIssue(taskDirectory, "task directory is missing manifest.yaml"));
            else
                issues.AddRange(Validate(manifestPath));
        }

        return issues;
    }

    private static void ValidateFields(string path, TaskManifest manifest, ICollection<ValidationIssue> issues)
    {
        Require(manifest.SchemaVersion == 1, path, "schemaVersion must be 1", issues);
        Require(TaskIdPattern().IsMatch(manifest.Id ?? string.Empty), path, "id must match TRN-###", issues);
        RequireNotBlank(manifest.Title, path, "title", issues);
        Require(manifest.Type is not null && SupportedTypes.Contains(manifest.Type), path,
            "type is not supported", issues);
        Require(manifest.Difficulty is not null && SupportedDifficulties.Contains(manifest.Difficulty), path,
            "difficulty is not supported", issues);
        Require(manifest.EstimatedMinutes is >= 15 and <= 960, path,
            "estimatedMinutes must be between 15 and 960", issues);
        Require(manifest.BaselineBranch == $"task/{manifest.Id}-baseline", path,
            $"baselineBranch must be task/{manifest.Id}-baseline", issues);
        Require(manifest.ScenarioSeed == manifest.Id, path, "scenarioSeed must equal id", issues);
        Require(manifest.RequiredServices is { Count: > 0 }, path, "requiredServices must not be empty", issues);
        Require(manifest.CompatibilityConstraints is { Count: > 0 }, path,
            "compatibilityConstraints must not be empty", issues);
        Require(manifest.LearningObjectives is { Count: > 0 }, path,
            "learningObjectives must not be empty", issues);
        RequireUnique(manifest.Prerequisites, path, "prerequisites", issues);
        RequireUnique(manifest.AffectedApi, path, "affectedApi", issues);
        RequireUnique(manifest.RequiredServices, path, "requiredServices", issues);

        Require(manifest.ReproduceCommand == $"pwsh ./training/tasks/{manifest.Id}/reproduce.ps1", path,
            "reproduceCommand must use the standard student entrypoint", issues);
        Require(manifest.VisibleVerificationCommand ==
                $"pwsh ./training/tasks/{manifest.Id}/visible-tests/verify.ps1", path,
            "visibleVerificationCommand must use the standard visible-test entrypoint", issues);
        Require(manifest.HiddenVerificationCommand == $"mentor-verify {manifest.Id}", path,
            "hiddenVerificationCommand must be an opaque mentor-verify command", issues);
        Require(manifest.ResetCommand == $"pwsh ./training/scripts/scenario.ps1 reset {manifest.Id}", path,
            "resetCommand must use the guarded scenario entrypoint", issues);
    }

    private static void ValidateStudentDirectory(string path, TaskManifest manifest,
        ICollection<ValidationIssue> issues)
    {
        var taskDirectory = Path.GetDirectoryName(path)!;
        Require(Path.GetFileName(taskDirectory) == manifest.Id, path,
            "manifest id must match its task directory", issues);

        foreach (var file in RequiredStudentFiles)
            Require(File.Exists(Path.Combine(taskDirectory, file)), path, $"missing student artifact {file}", issues);

        var visibleTests = Path.Combine(taskDirectory, "visible-tests");
        Require(Directory.Exists(visibleTests), path, "missing visible-tests directory", issues);
        if (Directory.Exists(visibleTests))
            Require(Directory.EnumerateFiles(visibleTests, "*.ps1", SearchOption.AllDirectories).Any(), path,
                "visible-tests must contain at least one PowerShell test", issues);

        foreach (var entry in Directory.EnumerateFileSystemEntries(taskDirectory, "*", SearchOption.AllDirectories))
        {
            if (ForbiddenStudentNames.Contains(Path.GetFileName(entry)))
                issues.Add(new ValidationIssue(entry, "mentor-only artifact is forbidden in the student task tree"));
        }

        var repositoryRoot = FindRepositoryRoot(taskDirectory);
        if (repositoryRoot is null)
            return;

        var scenarioDirectory = Path.Combine(repositoryRoot, "training", "db", "scenarios", manifest.Id);
        foreach (var operation in new[] { "apply", "reset", "verify" })
            Require(File.Exists(Path.Combine(scenarioDirectory, $"{operation}.sql")), path,
                $"missing deterministic scenario {manifest.Id}/{operation}.sql", issues);
    }

    private static string? FindRepositoryRoot(string startDirectory)
    {
        var current = new DirectoryInfo(startDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, ".git")) ||
                File.Exists(Path.Combine(current.FullName, "AGENTS.md")))
                return current.FullName;
            current = current.Parent;
        }

        return null;
    }

    private static void RequireNotBlank(string value, string path, string field,
        ICollection<ValidationIssue> issues) =>
        Require(!string.IsNullOrWhiteSpace(value), path, $"{field} must not be blank", issues);

    private static void RequireUnique(IEnumerable<string>? values, string path, string field,
        ICollection<ValidationIssue> issues)
    {
        if (values is null)
            return;

        var items = values.ToList();
        Require(items.Count == items.Distinct(StringComparer.Ordinal).Count(), path,
            $"{field} must not contain duplicates", issues);
    }

    private static void Require(bool condition, string path, string message, ICollection<ValidationIssue> issues)
    {
        if (!condition)
            issues.Add(new ValidationIssue(path, message));
    }

    [GeneratedRegex("^TRN-[0-9]{3}$", RegexOptions.CultureInvariant)]
    private static partial Regex TaskIdPattern();
}
