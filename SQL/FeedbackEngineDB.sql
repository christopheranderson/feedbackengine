CREATE SCHEMA fe

-- features and keywords

CREATE TABLE [fa].[tblFeatures]
(
	[FeatureID] INT NOT NULL PRIMARY KEY IDENTITY, 
    [ServiceID] INT NOT NULL, 
    [FeatureName] VARCHAR(50) NOT NULL, 
    [FeatureDescription] VARCHAR(250) NULL
)

CREATE TABLE [fa].[tblServices]
(
	[ServiceID] INT NOT NULL PRIMARY KEY IDENTITY, 
    [ServiceName] VARCHAR(50) NOT NULL, 
    [ServiceDescription] VARCHAR(250) NULL
)

CREATE TABLE [fa].[tblKeywordMaps]
(
	[KeywordMapID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[FeatureID] INT NOT NULL, 
    [Keyword] VARCHAR(50) NOT NULL, 
    [KeywordMapRank] FLOAT 
)

-- people and features 

CREATE TABLE [fa].[tblPeople]
(
	[PersonID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[Email] VARCHAR(50) NOT NULL,
	[Name] VARCHAR (100) NOT NULL,
	[SlackUser]	VARCHAR (50),
	[EmailNotify] TINYINT NOT NULL DEFAULT 0, 
	[SlackNotify] TINYINT NOT NULL DEFAULT 1
)

CREATE TABLE [fa].[tblPeopleKeywordMaps]
(
	[MapID] INT NOT NULL PRIMARY KEY IDENTITY, 
	[PersonID] INT NOT NULL, 
	[FeatureID] INT, 
    [KeywordMapID] INT 
)

--  Questions and history 
