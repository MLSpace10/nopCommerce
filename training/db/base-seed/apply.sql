SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.TrainingScenarioState', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrainingScenarioState
    (
        Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_TrainingScenarioState PRIMARY KEY,
        ScenarioId nvarchar(32) NOT NULL,
        State nvarchar(32) NOT NULL,
        AppliedUtc datetime2(3) NOT NULL,
        CONSTRAINT UQ_TrainingScenarioState_ScenarioId UNIQUE (ScenarioId)
    );
END;

IF OBJECT_ID(N'dbo.TrainingAuditEvent', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrainingAuditEvent
    (
        Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_TrainingAuditEvent PRIMARY KEY,
        EventType nvarchar(100) NOT NULL,
        SubjectId nvarchar(100) NULL,
        Payload nvarchar(max) NULL,
        OccurredUtc datetime2(3) NOT NULL
    );
END;

IF OBJECT_ID(N'dbo.TrainingIntegrationMessage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrainingIntegrationMessage
    (
        Id uniqueidentifier NOT NULL CONSTRAINT PK_TrainingIntegrationMessage PRIMARY KEY,
        MessageType nvarchar(200) NOT NULL,
        Payload nvarchar(max) NOT NULL,
        State nvarchar(32) NOT NULL,
        AttemptCount int NOT NULL,
        CreatedUtc datetime2(3) NOT NULL,
        ProcessedUtc datetime2(3) NULL
    );
END;

MERGE dbo.TrainingScenarioState AS target
USING (VALUES (N'BASE', N'Applied', CONVERT(datetime2(3), '2026-01-15T10:00:00.000'))) AS source(ScenarioId, State, AppliedUtc)
ON target.ScenarioId = source.ScenarioId
WHEN MATCHED THEN UPDATE SET State = source.State, AppliedUtc = source.AppliedUtc
WHEN NOT MATCHED THEN INSERT (ScenarioId, State, AppliedUtc) VALUES (source.ScenarioId, source.State, source.AppliedUtc);

IF NOT EXISTS (SELECT 1 FROM dbo.TrainingAuditEvent WHERE EventType = N'lab.bootstrap')
BEGIN
    INSERT dbo.TrainingAuditEvent (EventType, SubjectId, Payload, OccurredUtc)
    VALUES (N'lab.bootstrap', N'commerce-engineering-lab', N'{"source":"synthetic","containsPersonalData":false}', '2026-01-15T10:00:00.000');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.TrainingIntegrationMessage WHERE Id = '11111111-1111-1111-1111-111111111111')
BEGIN
    INSERT dbo.TrainingIntegrationMessage (Id, MessageType, Payload, State, AttemptCount, CreatedUtc, ProcessedUtc)
    VALUES ('11111111-1111-1111-1111-111111111111', N'Lab.Bootstrapped', N'{"lab":"Commerce Engineering Lab"}', N'Pending', 0, '2026-01-15T10:00:00.000', NULL);
END;

COMMIT TRANSACTION;

