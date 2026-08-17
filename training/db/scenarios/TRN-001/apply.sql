SET NOCOUNT ON;
SET XACT_ABORT ON;

MERGE dbo.TrainingScenarioState AS target
USING (VALUES (N'TRN-001', N'Applied', SYSUTCDATETIME())) AS source(ScenarioId, State, AppliedUtc)
ON target.ScenarioId = source.ScenarioId
WHEN MATCHED THEN UPDATE SET State = source.State, AppliedUtc = source.AppliedUtc
WHEN NOT MATCHED THEN INSERT (ScenarioId, State, AppliedUtc) VALUES (source.ScenarioId, source.State, source.AppliedUtc);
