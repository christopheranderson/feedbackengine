--CREATE SCHEMA fe

/*
drop table script in case needed 

DROP TABLE [fe].[tblFeatures]
DROP TABLE [fe].[tblKeywordMaps]
DROP TABLE [fe].[tblPeople]
DROP TABLE [fe].[tblPeopleKeywordMaps]
DROP TABLE [fe].[tblQuestionActivities]
DROP TABLE [fe].[tblQuestionHistory]
DROP TABLE [fe].[tblQuestions]
DROP TABLE [fe].[tblQuestionSources]
DROP TABLE [fe].[tblServices]
DROP PROCEDURE  [fe].[spAddQuestion]
DROP PROCEDURE [fe].[spSetQuestionState]

 */

-- features and keywords

CREATE TABLE [fe].[tblServices]
(
	[ServiceID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [ServiceName] VARCHAR(50) UNIQUE NOT NULL, 
    [ServiceDescription] VARCHAR(250) NULL
)
CREATE UNIQUE INDEX AK_tblServices_ServiceName 
    ON [fe].[tblServices]([ServiceName]);


CREATE TABLE [fe].[tblFeatures]
(
	[FeatureID] INT NOT NULL PRIMARY KEY IDENTITY, 
    [ServiceID] INT NOT NULL, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [FeatureName] VARCHAR(50) UNIQUE NOT NULL, 
    [FeatureDescription] VARCHAR(250) NULL
)
CREATE UNIQUE INDEX AK_tblFeatures_FeatureName 
    ON [fe].[tblFeatures]([FeatureName]);
	

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
	[Email] VARCHAR(50) UNIQUE NOT NULL,
	[Name] VARCHAR (100) NOT NULL,
	[SlackUser]	VARCHAR (50),
	[EmailNotify] TINYINT NOT NULL DEFAULT 0, 
	[SlackNotify] TINYINT NOT NULL DEFAULT 1
)

CREATE UNIQUE INDEX AK_tblPeople_Email 
    ON [fe].[tblPeople]([Email]);


CREATE TABLE [fe].[tblPeopleFeatureMaps] 
(
	[MapID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[PersonID] INT NOT NULL, 
	[FeatureID] INT, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate()
)

--  Questions and history 
-- need a view for a user and how many open questions they have 

CREATE TABLE [fe].[tblQuestionSources]
(
	[QuestionSourceID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [QuestionSourceName] VARCHAR(50) UNIQUE NOT NULL,
    [QuestionSourceUrlStem] VARCHAR(250) UNIQUE NOT NULL, -- used to shorten actual question URLs, perhaps later for a test environment
    [QuestionSourceDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblQuestionActivities]
(
	[QuestionActivityID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
    [QuestionActivityName] VARCHAR(50) UNIQUE NOT NULL, 
    [QuestionActivityDescription] VARCHAR(250) NULL
)
CREATE UNIQUE INDEX AK_tblQuestionActivities_QuestionActivityName 
    ON [fe].[tblQuestionActivities]([QuestionActivityName]);


CREATE TABLE [fe].[tblQuestionHistory]
(
	[QuestionHistoryID] INT NOT NULL PRIMARY KEY IDENTITY,
	[QuestionID] INT NOT NULL, 
	[QuestionActivityID] INT NOT NULL, 
	[PersonID] INT NOT NULL, 
	[ActivityDate] DATETIME NOT NULL DEFAULT Getdate(),
    [ActivityDescription] VARCHAR(250) NULL
)

CREATE TABLE [fe].[tblQuestions]
(
	[QuestionID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[QuestionSourceID] INT NOT NULL,
	[ServiceID]	INT NOT NULL,
	[CreationDate] DATETIME NOT NULL DEFAULT Getdate(),
	[QuestionTitle] VARCHAR(1700) NOT NULL,
	[QuestionUrl] VARCHAR(1700) NOT NULL,
	[QuestionText] VARCHAR(MAX) NOT NULL
)

-- index 
CREATE UNIQUE INDEX AK_tblQuestions_QuestionUrl 
    ON [fe].[tblQuestions]([QuestionUrl]);

-- sprocs

CREATE PROCEDURE [fe].[spAddQuestion]
	@QuestionSourceName VARCHAR(50),
	@ServiceName VARCHAR(50),
	@QuestionTitle VARCHAR(2500),
	@QuestionUrl VARCHAR(2500),
	@QuestionText VARCHAR (MAX)
AS
BEGIN
	declare @QuestionSourceID int = -1
	declare @ServiceID int = -1
	declare @QuestionUrlStem VARCHAR(250)

	-- Get Question Source ID 
	select @QuestionSourceID =  QuestionSourceID from [fe].[tblQuestionSources] where [QuestionSourceName] = @QuestionSourceName
	if @QuestionSourceID = -1
	begin
		select -1
		return 
	end 
	else 
	begin 
		-- Get Feature ID 
		select @ServiceID =  ServiceID from [fe].[tblServices] where [ServiceName] = @ServiceName

		-- Clean up the URL stem
		select @QuestionUrlStem =  [QuestionSourceUrlStem] from [fe].[tblQuestionSources] where [QuestionSourceID] = @QuestionSourceID
		set @QuestionUrl = right(@QuestionUrl,len(@QuestionUrl) - len(@QuestionUrlStem))

		insert into [fe].[tblQuestions] ([QuestionSourceID],[ServiceID],[QuestionTitle],[QuestionUrl],[QuestionText]) values (@QuestionSourceID,@ServiceID,@QuestionTitle,@QuestionUrl,@QuestionText)

		select @@IDENTITY
	end 
END 

CREATE PROCEDURE [fe].[spSetQuestionState]
	@QuestionID INT,
	@PersonID INT,
	@QuestionActivity VARCHAR(50),
	@QuestionActivityDescription VARCHAR(250)
AS
BEGIN
	declare @QuestionActivityID int = -1

	-- Get Question Activity ID
	select @QuestionActivityID =  [QuestionActivityID] from [fe].[tblQuestionActivities] where [QuestionActivityName] = @QuestionActivity
	if @QuestionActivityID = -1
	begin 
		select -1
		return
	end 
	else
	begin 
		insert into [fe].[tblQuestionHistory] ([QuestionID],[QuestionActivityID],[PersonID],[ActivityDescription]) values (@QuestionID,@QuestionActivityID,@PersonID,@QuestionActivityDescription)
		select @@IDENTITY
	end 

END 

CREATE PROCEDURE [fe].[spMapPersonFeature]
	@Email VARCHAR(50),
	@FeatureName VARCHAR(50)
AS
BEGIN
	declare @personID INT = -1
	declare @featureID INT = -1

END 
-- Load meta data

-- Load Services


-- Load Features  

-- Load Sources 

-- Load People 