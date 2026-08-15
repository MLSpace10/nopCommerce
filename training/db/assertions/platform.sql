SET NOCOUNT ON;

IF DB_NAME() <> N'$(TrainingDatabase)'
    THROW 51000, 'Refusing verification outside the configured training database.', 1;

IF OBJECT_ID(N'dbo.TrainingScenarioState', N'U') IS NULL
    THROW 51001, 'TrainingScenarioState is missing.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.TrainingScenarioState WHERE ScenarioId = N'BASE' AND State = N'Applied')
    THROW 51002, 'BASE scenario is not applied.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.Customer)
    THROW 51003, 'nopCommerce customer seed is empty.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.Product)
    THROW 51004, 'nopCommerce product seed is empty.', 1;

SELECT
    DB_NAME() AS DatabaseName,
    (SELECT COUNT_BIG(*) FROM dbo.Customer) AS CustomerCount,
    (SELECT COUNT_BIG(*) FROM dbo.Product) AS ProductCount,
    (SELECT COUNT_BIG(*) FROM dbo.TrainingAuditEvent) AS TrainingAuditEventCount,
    (SELECT COUNT_BIG(*) FROM dbo.TrainingIntegrationMessage) AS TrainingIntegrationMessageCount;
