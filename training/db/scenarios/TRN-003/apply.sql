SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Product WHERE Id = 1 AND Deleted = 0)
    THROW 51003, 'TRN-003 requires synthetic product 1.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.Product_Category_Mapping WHERE ProductId = 1)
    THROW 51003, 'TRN-003 requires product 1 category data.', 1;

MERGE dbo.TrainingScenarioState AS target
USING (VALUES (N'TRN-003', N'Applied', SYSUTCDATETIME())) AS source(ScenarioId, State, AppliedUtc)
ON target.ScenarioId = source.ScenarioId
WHEN MATCHED THEN UPDATE SET State = source.State, AppliedUtc = source.AppliedUtc
WHEN NOT MATCHED THEN INSERT (ScenarioId, State, AppliedUtc) VALUES (source.ScenarioId, source.State, source.AppliedUtc);
