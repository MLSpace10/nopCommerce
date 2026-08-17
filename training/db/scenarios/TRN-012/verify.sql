SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.TrainingIdempotencyRecord', N'U') IS NULL
    THROW 51012, 'TRN-012 idempotency storage fixture is missing.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-012' AND State = N'Applied')
    THROW 51012, 'TRN-012 scenario is not applied.', 1;
IF EXISTS (SELECT 1 FROM dbo.[Order] WHERE CustomValuesXml LIKE N'%<IdempotencyKey>trn012-%')
    THROW 51012, 'TRN-012 scenario contains stale task orders.', 1;
IF EXISTS (SELECT 1 FROM dbo.TrainingIdempotencyRecord WHERE IdempotencyKey LIKE N'trn012-%')
    THROW 51012, 'TRN-012 scenario contains stale idempotency records.', 1;

SELECT ScenarioId, State, AppliedUtc FROM dbo.TrainingScenarioState WHERE ScenarioId = N'TRN-012';
