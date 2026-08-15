using AwesomeAssertions;
using Microsoft.AspNetCore.Http;
using Nop.Plugin.Training.Api.Infrastructure;
using NUnit.Framework;

namespace Nop.Tests.Nop.Plugin.Training.Api.Tests;

[TestFixture]
public class TrainingApiInfrastructureTests
{
    private const string EnvironmentVariableName = "TRAINING_API_KEY";
    private string _originalApiKey;

    [SetUp]
    public void SetUp()
    {
        _originalApiKey = Environment.GetEnvironmentVariable(EnvironmentVariableName);
        Environment.SetEnvironmentVariable(EnvironmentVariableName, "unit-test-key");
    }

    [TearDown]
    public void TearDown()
    {
        Environment.SetEnvironmentVariable(EnvironmentVariableName, _originalApiKey);
    }

    [Test]
    public async Task HealthEndpointDoesNotRequireAuthentication()
    {
        var called = false;
        var middleware = new TrainingApiAuthenticationMiddleware(_ =>
        {
            called = true;
            return Task.CompletedTask;
        });
        var context = new DefaultHttpContext();
        context.Request.Path = "/api/health";

        await middleware.InvokeAsync(context);

        called.Should().BeTrue();
    }

    [Test]
    public async Task ProtectedEndpointRejectsInvalidKey()
    {
        var middleware = new TrainingApiAuthenticationMiddleware(_ => Task.CompletedTask);
        var context = new DefaultHttpContext();
        context.Request.Path = "/api/products";
        context.Request.Headers[TrainingApiAuthenticationMiddleware.HeaderName] = "wrong";
        context.Response.Body = new MemoryStream();

        await middleware.InvokeAsync(context);

        context.Response.StatusCode.Should().Be(StatusCodes.Status401Unauthorized);
    }

    [Test]
    public async Task ProtectedEndpointAcceptsConfiguredKey()
    {
        var called = false;
        var middleware = new TrainingApiAuthenticationMiddleware(_ =>
        {
            called = true;
            return Task.CompletedTask;
        });
        var context = new DefaultHttpContext();
        context.Request.Path = "/api/products";
        context.Request.Headers[TrainingApiAuthenticationMiddleware.HeaderName] = "unit-test-key";

        await middleware.InvokeAsync(context);

        called.Should().BeTrue();
    }

    [TestCase("none")]
    [TestCase("database-transient")]
    [TestCase("http-timeout")]
    [TestCase("connection-reset")]
    public void FaultStateAcceptsKnownProfiles(string profile)
    {
        var state = new TrainingFaultState();

        state.TrySet(profile).Should().BeTrue();
        state.Profile.Should().Be(profile);
    }

    [Test]
    public void FaultStateRejectsUnknownProfile()
    {
        var state = new TrainingFaultState();

        state.TrySet("production-outage").Should().BeFalse();
        state.Profile.Should().Be("none");
    }
}
