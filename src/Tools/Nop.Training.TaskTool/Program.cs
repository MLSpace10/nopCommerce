using Nop.Training.TaskTool;
using YamlDotNet.Core;
using YamlDotNet.RepresentationModel;

return Run(args);

static int Run(string[] args)
{
    var repositoryRoot = FindRepositoryRoot(Environment.CurrentDirectory);
    if (repositoryRoot is null)
    {
        Console.Error.WriteLine("Could not find repository root containing AGENTS.md.");
        return 2;
    }

    var validator = new TaskManifestValidator();
    var command = args.FirstOrDefault() ?? "validate";
    IReadOnlyList<ValidationIssue> issues;

    switch (command)
    {
        case "validate":
            issues = validator.ValidateRepository(repositoryRoot);
            break;
        case "validate-manifest" when args.Length == 2:
            issues = validator.Validate(Path.GetFullPath(args[1]), requireStudentArtifacts: false);
            break;
        case "validate-yaml" when args.Length == 2:
            return ValidateYaml(Path.GetFullPath(args[1]));
        case "list":
            return ListTasks(repositoryRoot);
        default:
            Console.Error.WriteLine("Usage: task-tool [validate|validate-manifest <path>|validate-yaml <path>|list]");
            return 2;
    }

    foreach (var issue in issues)
        Console.Error.WriteLine(issue);

    if (issues.Count > 0)
        return 1;

    Console.WriteLine(command == "validate" ? "Task manifests: PASS" : "Manifest: PASS");
    return 0;
}

static int ValidateYaml(string path)
{
    if (!File.Exists(path))
    {
        Console.Error.WriteLine($"YAML file does not exist: {path}");
        return 1;
    }

    try
    {
        using var reader = File.OpenText(path);
        var yaml = new YamlStream();
        yaml.Load(reader);
        Console.WriteLine("YAML syntax: PASS");
        return 0;
    }
    catch (YamlException exception)
    {
        Console.Error.WriteLine($"Invalid YAML in {path}: {exception.Message}");
        return 1;
    }
}

static int ListTasks(string repositoryRoot)
{
    var tasksRoot = Path.Combine(repositoryRoot, "training", "tasks");
    if (!Directory.Exists(tasksRoot))
    {
        Console.WriteLine("No task baselines are present.");
        return 0;
    }

    var taskDirectories = Directory.EnumerateDirectories(tasksRoot).OrderBy(path => path).ToList();
    if (taskDirectories.Count == 0)
    {
        Console.WriteLine("No task baselines are present.");
        return 0;
    }

    foreach (var taskDirectory in taskDirectories)
        Console.WriteLine(Path.GetFileName(taskDirectory));
    return 0;
}

static string? FindRepositoryRoot(string startDirectory)
{
    var current = new DirectoryInfo(startDirectory);
    while (current is not null)
    {
        if (File.Exists(Path.Combine(current.FullName, "AGENTS.md")))
            return current.FullName;
        current = current.Parent;
    }

    return null;
}
