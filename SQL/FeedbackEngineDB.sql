--CREATE SCHEMA fe

-- features and keywords

CREATE TABLE [fe].[tblServices]
(
	[ServiceID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [ServiceName] VARCHAR(50) NOT NULL, 
    [ServiceDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblFeatures]
(
	[FeatureID] INT NOT NULL PRIMARY KEY IDENTITY, 
    [ServiceID] INT NOT NULL, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [FeatureName] VARCHAR(50) NOT NULL, 
    [FeatureDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblKeywordMaps]
(
	[KeywordMapID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[FeatureID] INT NOT NULL, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [Keyword] VARCHAR(50) NOT NULL, 
    [KeywordMapRank] FLOAT 
)

-- people and features 

CREATE TABLE [fe].[tblPeople]
(
	[PersonID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
	[DayOfWeek] INT NOT NULL DEFAULT -1,
	[Email] VARCHAR(50) NOT NULL,
	[Name] VARCHAR (100) NOT NULL,
	[SlackUser]	VARCHAR (50),
	[EmailNotify] TINYINT NOT NULL DEFAULT 0, 
	[SlackNotify] TINYINT NOT NULL DEFAULT 1
)

CREATE TABLE [fe].[tblPeopleKeywordMaps]
(
	[MapID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[PersonID] INT NOT NULL, 
	[FeatureID] INT, 
    [KeywordMapID] INT,
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate()
)

--  Questions and history 
-- need a view for a user and how many open questions they have 

CREATE TABLE [fe].[tblQuestionSources]
(
	[QuestionSourceID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [QuestionSourceName] VARCHAR(50) NOT NULL, 
    [QuestionSourceDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblQuestionActivities]
(
	[QuestionSourceID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [QuestionSourceName] VARCHAR(50) NOT NULL, 
    [QuestionSourceDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblQuestionHistory]
(
	[QuestionHistoryID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[QuestionActivityID] INT NOT NULL, 
	[PersonID] INT NOT NULL, 
	[ActivityDate] DATETIME NOT NULL DEFAULT Getdate(),
    [ActivityDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblQuestions]
(
	[QuestionID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[QuestionSourceID] INT NOT NULL,
	[FeatureID]	INT NOT NULL,
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
	[QuestionTitle] VARCHAR(2500) NOT NULL,
	[QuestionUrl] VARCHAR(2500) NOT NULL,
	[QuestionText] VARCHAR(MAX) NOT NULL
)

-- sprocs

CREATE PROCEDURE [fe].[spAddQuestion]
	@QuestionSourceName VARCHAR(50),
	@FeatureName VARCHAR(50),
	@QuestionTitle VARCHAR(2500),
	@QuestionUrl VARCHAR(2500),
	@QuestionText VARCHAR
AS
BEGIN
	declare @QuestionSourceID int = -1
	declare @FeatureID int = -1

	-- Get Question Source ID 
	select @QuestionSourceID =  QuestionSourceID from [fe].[tblQuestionSources] where [QuestionSourceName] = @QuestionSourceName
	-- Get Feature ID 
	select @FeatureID =  FeatureID from [fe].[tblFeatures] where [FeatureName] = @FeatureName


END 