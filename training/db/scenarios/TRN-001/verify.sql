SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-001' AND State = N'Applied')
    THROW 51001, 'TRN-001 scenario is not applied.', 1;

SELECT ScenarioId, State, AppliedUtc FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-001';
