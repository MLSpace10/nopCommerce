using AwesomeAssertions;
using Nop.Training.TaskTool;
using NUnit.Framework;

namespace Nop.Tests.Nop.Training.TaskTool.Tests;

[TestFixture]
public class TaskManifestValidatorTests
{
    private string _repositoryRoot;
    private string _taskDirectory;
    private string _manifestPath;
    private TaskManifestValidator _validator;

    [SetUp]
    public void SetUp()
    {
        _repositoryRoot = Path.Combine(Path.GetTempPath(), "commerce-lab-task-tool", Guid.NewGuid().ToString("N"));
        _taskDirectory = Path.Combine(_repositoryRoot, "training", "tasks", "TRN-900");
        _manifestPath = Path.Combine(_taskDirectory, "manifest.yaml");
        _validator = new TaskManifestValidator();

        Directory.CreateDirectory(Path.Combine(_taskDirectory, "visible-tests"));
        Directory.CreateDirectory(Path.Combine(_repositoryRoot, "training", "db", "scenarios", "TRN-900"));
        File.WriteAllText(Path.Combine(_repositoryRoot, "AGENTS.md"), "test repository");
        File.WriteAllText(Path.Combine(_taskDirectory, "student-ticket.md"), "ticket");
        File.WriteAllText(Path.Combine(_taskDirectory, "reproduce.ps1"), "Write-Host reproduce");
        File.WriteAllText(Path.Combine(_taskDirectory, "expected-evidence.md"), "evidence");
        File.WriteAllText(Path.Combine(_taskDirectory, "visible-tests", "verify.ps1"), "Write-Host verify");
        foreach (var operation in new[] { "apply", "reset", "verify" })
            File.WriteAllText(Path.Combine(_repositoryRoot, "training", "db", "scenarios", "TRN-900",
                $"{operation}.sql"), "SELECT 1;");
        File.WriteAllText(_manifestPath, ValidManifest());
    }

    [TearDown]
    public void TearDown()
    {
        if (Directory.Exists(_repositoryRoot))
            Directory.Delete(_repositoryRoot, recursive: true);
    }

    [Test]
    public void ValidStudentTaskPasses()
    {
        _validator.Validate(_manifestPath).Should().BeEmpty();
    }

    [Test]
    public void RepositoryValidationReadsNestedTaskManifest()
    {
        File.WriteAllText(_manifestPath, ValidManifest().Replace("task/TRN-900-baseline", "task/wrong"));

        var issues = _validator.ValidateRepository(_repositoryRoot);

        issues.Should().Contain(issue => issue.Message.Contains("baselineBranch"));
    }

    [Test]
    public void MissingVisibleTestsFails()
    {
        Directory.Delete(Path.Combine(_taskDirectory, "visible-tests"), recursive: true);

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("visible-tests"));
    }

    [Test]
    public void MentorArtifactInStudentTreeFails()
    {
        File.WriteAllText(Path.Combine(_taskDirectory, "solution.patch"), "mentor only");

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("mentor-only"));
    }

    [Test]
    public void LocalHiddenVerificationPathFails()
    {
        File.WriteAllText(_manifestPath,
            ValidManifest().Replace("mentor-verify TRN-900", "pwsh ./hidden-tests/verify.ps1"));

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("opaque mentor-verify"));
    }

    [Test]
    public void MissingScenarioOperationFails()
    {
        File.Delete(Path.Combine(_repositoryRoot, "training", "db", "scenarios", "TRN-900", "reset.sql"));

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("reset.sql"));
    }

    [Test]
    public void UnknownYamlPropertyFailsParsing()
    {
        File.AppendAllText(_manifestPath, "unexpectedProperty: true\n");

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("invalid YAML"));
    }

    [Test]
    public void NullAndDuplicateCollectionsReturnValidationIssues()
    {
        var manifest = ValidManifest()
            .Replace("requiredServices:\n  - core", "requiredServices:")
            .Replace("  - GET /api/products", "  - GET /api/products\n  - GET /api/products");
        File.WriteAllText(_manifestPath, manifest);

        var issues = _validator.Validate(_manifestPath);

        issues.Should().Contain(issue => issue.Message.Contains("requiredServices must not be empty"));
        issues.Should().Contain(issue => issue.Message.Contains("affectedApi must not contain duplicates"));
    }

    private static string ValidManifest() => """
        schemaVersion: 1
        id: TRN-900
        title: Synthetic validator fixture
        type: bug
        difficulty: intermediate
        estimatedMinutes: 90
        prerequisites:
          - phase-2
        baselineBranch: task/TRN-900-baseline
        scenarioSeed: TRN-900
        affectedApi:
          - GET /api/products
        requiredServices:
          - core
        reproduceCommand: pwsh ./training/tasks/TRN-900/reproduce.ps1
        visibleVerificationCommand: pwsh ./training/tasks/TRN-900/visible-tests/verify.ps1
        hiddenVerificationCommand: mentor-verify TRN-900
        resetCommand: pwsh ./training/scripts/scenario.ps1 reset TRN-900
        compatibilityConstraints:
          - Preserve the public response contract.
        learningObjectives:
          - Trace a request through the existing application flow.
        """;
}
