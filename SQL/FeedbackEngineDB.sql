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
	[SlackNotify] TINYINT NOT NULL DEFAULT 1,
	[DefaultDaily] TINYINT NOT NULL DEFAULT 0
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

	select @personID = [PersonID] from [fe].[tblPeople] where [Email] = @Email
	select @featureID = [FeatureID] from [fe].[tblFeatures] where [FeatureName] = @FeatureName

	if @personID = -1 or @featureID = -1 
	begin 
		select -1
		return
	end 
	else
	begin 
		insert into [fe].[tblPeopleFeatureMaps] ([PersonID],[FeatureID]) values (@personID,@featureID)
		select @@IDENTITY
	end 
END 

CREATE PROCEDURE [fe].[spMapServiceFeature]
	@ServiceName VARCHAR(50),
	@FeatureName VARCHAR(50),
	@FeatureDescription VARCHAR(250)
AS
BEGIN
	declare @ServiceID INT = -1

	select @ServiceID = [ServiceID] from [fe].[tblServices] where [ServiceName] = @ServiceName

	if @ServiceID = -1  
	begin 
		select -1
		return
	end 
	else
	begin 
		insert into [fe].[tblFeatures] ([ServiceID],[FeatureName],[FeatureDescription]) values (@ServiceID,@FeatureName,@FeatureDescription)
		select @@IDENTITY
	end 
END 

CREATE PROCEDURE [fe].[spMapFeatureKeywords]
	@FeatureName VARCHAR(50),
	@Keyword VARCHAR(50),
	@KeywordMapRank FLOAT
AS
BEGIN
	declare @FeatureID INT = -1

	select @FeatureID = [FeatureID] from [fe].[tblFeatures] where [FeatureName] = @FeatureName

	if @FeatureID = -1  
	begin 
		select -1
		return
	end 
	else
	begin 
		insert into [fe].[tblKeywordMaps] ([FeatureID],[Keyword],[KeywordMapRank]) values (@FeatureID,@Keyword,@KeywordMapRank)
		select @@IDENTITY
	end 
END 

-- Load meta data

-- Load Services
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('Web','Service - Web')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('Mobile ','Service - Mobile ')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('Logic Apps','Service - Logic Apps')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('API App','Service - API App')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('API Management','Service - API Management')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('Notification Hubs','Service - Notification Hubs')
insert into [fe].[tblServices] ([ServiceName] ,[ServiceDescription]) values ('Redis Cache','Service - Redis Cache')


-- Load Features  
exec [fe].[spMapServiceFeature] 'Web','Stacks','feature : Stacks'
exec [fe].[spMapServiceFeature] 'Web','Slots','feature : Slots'
exec [fe].[spMapServiceFeature] 'Web','Custom Domain ','feature : Custom Domain '
exec [fe].[spMapServiceFeature] 'Web','Backup','feature : Backup'
exec [fe].[spMapServiceFeature] 'Web','Security ','feature : Security '
exec [fe].[spMapServiceFeature] 'Web','ASE','feature : ASE'
exec [fe].[spMapServiceFeature] 'Web','Ibiza','feature : Ibiza'
exec [fe].[spMapServiceFeature] 'Web','Supportability ','feature : Supportability '
exec [fe].[spMapServiceFeature] 'Web','OSS','feature : OSS'
exec [fe].[spMapServiceFeature] 'Web','Gallery/CMS','feature : Gallery/CMS'
exec [fe].[spMapServiceFeature] 'Web','Java','feature : Java'
exec [fe].[spMapServiceFeature] 'Mobile','Mobile-SDK','feature : Mobile-SDK'
exec [fe].[spMapServiceFeature] 'Mobile','Mobile-NET ','feature : Mobile-NET '
exec [fe].[spMapServiceFeature] 'Mobile','Mobile-Node','feature : Mobile-Node'
exec [fe].[spMapServiceFeature] 'Web','CI','feature : CI'
exec [fe].[spMapServiceFeature] 'Web','Hybrid-Connectivity','feature : Hybrid-Connectivity'
exec [fe].[spMapServiceFeature] 'Web','EasyAuth','feature : EasyAuth'
exec [fe].[spMapServiceFeature] 'Web','WebJob','feature : WebJob'
exec [fe].[spMapServiceFeature] 'Notification Hubs','Notification ','feature : Notification '
exec [fe].[spMapServiceFeature] 'API App','API App','feature : API App'
exec [fe].[spMapServiceFeature] 'Logic Apps','Logic App','feature : Logic App'
exec [fe].[spMapServiceFeature] 'Web','WebApp','feature : WebApp'
exec [fe].[spMapServiceFeature] 'API Management','APIM','feature : APIM'
exec [fe].[spMapServiceFeature] 'Logic Apps','Scheduler','feature : Scheduler'
exec [fe].[spMapServiceFeature] 'Redis Cache','Redis Cache','feature : Redis Cache'

-- Load Maps
exec [fe].[spMapFeatureKeywords] 'Slots','Staging ',0.7
exec [fe].[spMapFeatureKeywords] 'Backup','Backup ',1
exec [fe].[spMapFeatureKeywords] 'Backup','Restore ',1
exec [fe].[spMapFeatureKeywords] 'Hybrid-Connectivity','Hybrid Connection ',1
exec [fe].[spMapFeatureKeywords] 'Hybrid-Connectivity','VNET ',1
exec [fe].[spMapFeatureKeywords] 'Hybrid-Connectivity','VLAN ',1
exec [fe].[spMapFeatureKeywords] 'ASE','ASE ',1
exec [fe].[spMapFeatureKeywords] 'ASE','App Service Environment',1
exec [fe].[spMapFeatureKeywords] 'CI','Web Deploy',1
exec [fe].[spMapFeatureKeywords] 'CI','WebDeploy',1
exec [fe].[spMapFeatureKeywords] 'CI','Git ',0.7
exec [fe].[spMapFeatureKeywords] 'CI','GitHub',0.7
exec [fe].[spMapFeatureKeywords] 'CI','BitBucket ',0.7
exec [fe].[spMapFeatureKeywords] 'CI','DropBox ',0.7
exec [fe].[spMapFeatureKeywords] 'CI','OneDrive ',0.7
exec [fe].[spMapFeatureKeywords] 'Security','SSL',0.8
exec [fe].[spMapFeatureKeywords] 'Custom Domain ','Domain ',0.7
exec [fe].[spMapFeatureKeywords] 'Mobile-SDK','Xamarin ',1
exec [fe].[spMapFeatureKeywords] 'Mobile-SDK','iOS',1
exec [fe].[spMapFeatureKeywords] 'Mobile-SDK','cordova ',1
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','MySQL',0.7
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','WordPress ',1
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','Joomla ',1
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','Drupal ',1
exec [fe].[spMapFeatureKeywords] 'Notification','Push ',1
exec [fe].[spMapFeatureKeywords] 'EasyAuth','Auth ',0.7
exec [fe].[spMapFeatureKeywords] 'EasyAuth','Facebook',0.8
exec [fe].[spMapFeatureKeywords] 'EasyAuth','Microsoft Account ',0.8
exec [fe].[spMapFeatureKeywords] 'EasyAuth','Google Account',0.8
exec [fe].[spMapFeatureKeywords] 'Stacks','Try App Service',0.9
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','Moodle ',1
exec [fe].[spMapFeatureKeywords] 'Stacks','.NET',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','PHP',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','Java',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','Node.js',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','Node',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','Python ',0.7
exec [fe].[spMapFeatureKeywords] 'Stacks','Django ',0.8
exec [fe].[spMapFeatureKeywords] 'Stacks','MVC',0.8
exec [fe].[spMapFeatureKeywords] 'Stacks','APS.NET',0.7
exec [fe].[spMapFeatureKeywords] 'Slots','Slot',0.8
exec [fe].[spMapFeatureKeywords] 'Slots','Prod',0.6
exec [fe].[spMapFeatureKeywords] 'Custom Domain ','GoDaddy',1
exec [fe].[spMapFeatureKeywords] 'WebJob','Queue',0.8
exec [fe].[spMapFeatureKeywords] 'Gallery/CMS','ClearDB',0.9
exec [fe].[spMapFeatureKeywords] 'EasyAuth','Authentication ',0.8
exec [fe].[spMapFeatureKeywords] 'WebApp','Website',0.6
exec [fe].[spMapFeatureKeywords] 'WebApp','App Service Plan',0.7
exec [fe].[spMapFeatureKeywords] 'WebApp','App Pool',0.7
exec [fe].[spMapFeatureKeywords] 'WebApp','Web Hosting Plan',0.8
exec [fe].[spMapFeatureKeywords] 'Stacks','DB',0.6
exec [fe].[spMapFeatureKeywords] 'Stacks','SQL',0.5
exec [fe].[spMapFeatureKeywords] 'Stacks','SQL Databases',0.6
exec [fe].[spMapFeatureKeywords] 'Stacks','Visual Studio',0.6
exec [fe].[spMapFeatureKeywords] 'Stacks','VS',0.6
exec [fe].[spMapFeatureKeywords] 'WebApp','OnPrem',0.8
exec [fe].[spMapFeatureKeywords] 'WebApp','AzureStack',0.9
exec [fe].[spMapFeatureKeywords] 'WebApp','Katal',0.9
exec [fe].[spMapFeatureKeywords] 'Redis Cache','Redis',1
exec [fe].[spMapFeatureKeywords] 'Redis Cache','Cache',0.4

-- Load Sources 
insert into [fe].[tblQuestionSources] ([QuestionSourceName],[QuestionSourceUrlStem],[QuestionSourceDescription]) values ('MSDN','https://social.msdn.microsoft.com/Forums/','MSDN Forum')
insert into [fe].[tblQuestionSources] ([QuestionSourceName],[QuestionSourceUrlStem],[QuestionSourceDescription]) values ('SO','http://stackoverflow.com/questions/','StackOverflow')

-- Load People 
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Ahmed Elnably','aelnably@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Chris Anderson (ZUMO)','chrande@microsoft.com','chrisanderson',2,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('David Justice','david.justice@microsoft.com','justice',2,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Jeff Fritz','jefritz@microsoft.com','jfritz',2,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Nazim Lala','Nazim.Lala@microsoft.com','',2,1,0,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Vladimir Vinogradsky','vlvinogr@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Kevin Lam','Kevin.Lam@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Jim Becker (TECH EDITOR)','jimbe@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Wade Pickett','wpickett@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Mandi Ohlinger','Mandi.Ohlinger@microsoft.com','',2,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Andrew Westgarth','anwestg@microsoft.com','apwestgarth',3,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Chris Compy','ccompy@microsoft.com','',3,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Donna Malayeri','donnam@microsoft.com','donnam',3,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Nir Mashkowski','Nir.Mashkowski@microsoft.com','nirma',3,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Yochay Kiriaty','yochayk@microsoft.com','',3,1,0,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Prashant Kumar (AZURE)','prkumar@microsoft.com','prashant',3,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Mike Wasson','mwasson@microsoft.com','',3,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Cam Soper','Cam.Soper@microsoft.com','',3,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Rick Saling','Rick.Saling@microsoft.com','',3,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Anton Babadjanov','antonba@microsoft.com','antonba',4,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Chris Sfanos','Chris.Sfanos@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Eduardo Laureano','Eduardo.Laureano@microsoft.com','',4,1,0,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Mads Kristensen','Madsk@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Pranav Rastogi','Pranav.Rastogi@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Anurag Dalmia','andalmia@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Mimi Xu','yuaxu@microsoft.com','yuaxu',4,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Rajesh Ramabathiran','rajram@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Rick Anderson','Rick.Anderson@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('David Wrede','David.Wrede@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Steve Danielson','Steve.Danielson@microsoft.com','',4,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Apurva Joshi (AJ)','Apurva.Joshi@microsoft.com','',5,1,0,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Cory Fowler','cfowler@microsoft.com','cfowler',5,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Matthew Henderson','Matthew.Henderson@microsoft.com','mahender',5,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Rowan Miller','rowmil@microsoft.com','',5,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Guru Venkataraman','Guru.Venkataraman@microsoft.com','',5,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Sameer Chabungbam','sameerch@microsoft.com','sameerch',5,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Robert McMurray','robmcm@microsoft.com','',5,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Deon Herbert','deonhe@microsoft.com','',5,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Wesley McSwain','wesmc@microsoft.com','',5,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Barry Dorrans','Barry.Dorrans@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Damian Edwards','damian.edwards@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Glenn Condron','glennc@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Miao Jiang','mijiang@microsoft.com','miaojiang',6,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Kirill Gavrylyuk','kirillg@microsoft.com','kirillg',6,1,1,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Sayed Hashimi','sayedha@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Jeff Hollan','Jeff.Hollan@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Stephen Siciliano','stepsic@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Tom Archer','Tom.Archer@microsoft.com','',6,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Glenn Gailey','Glenn.Gailey@microsoft.com','ggailey777',6,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Brady Gaster','bradyg@microsoft.com','bradyg',7,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Daniel Roth','Daniel.Roth@microsoft.com','',7,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Guang Yang (AZURE)','Guang.Yang@microsoft.com','guangyang',7,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Stefan Schackow','stefsch@microsoft.com','',7,1,0,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Jon Fancey','jonfan@microsoft.com','jonfancey',7,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Cephas Lin','Cephas.Lin@microsoft.com','cephalin',7,1,1,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Tom Dykstra','tdykstra@microsoft.com','',7,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Julia Kornich','juliako@microsoft.com','',7,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Byron Tardif','byvinyal@microsoft.com','btardif',1,1,1,1)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Daria Grigoriu','dariac@microsoft.com','',1,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Mohit Srivastava','mohisri@microsoft.com','',1,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Sunitha Muthukrishna','sumuth@microsoft.com','',1,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Erik Reitan','Erik.Reitan@microsoft.com','',1,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Tom FitzMacken','tomfitz@microsoft.com','',1,1,0,0)
insert into [fe].[tblPeople] ([Name],[Email],[SlackUser],[DayOfWeek],[EmailNotify],[SlackNotify],[DefaultDaily]) values ('Krishnan Rangachari','Krishnan.R@microsoft.com','',1,1,0,0)

-- map features to people 
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Supportability'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','WebJob'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'aelnably@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'vlvinogr@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','Notification '
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','WebJob'
exec [fe].[spMapPersonFeature] 'chrande@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Kevin.Lam@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'Kevin.Lam@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'david.justice@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'jefritz@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Nazim.Lala@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'wpickett@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'Mandi.Ohlinger@microsoft.com','Notification '
exec [fe].[spMapPersonFeature] 'Mandi.Ohlinger@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Mandi.Ohlinger@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Mandi.Ohlinger@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'anwestg@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'ccompy@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'donnam@microsoft.com','Notification '
exec [fe].[spMapPersonFeature] 'donnam@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'donnam@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'donnam@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Nir.Mashkowski@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'yochayk@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'prkumar@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'prkumar@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'Cam.Soper@microsoft.com','Notification '
exec [fe].[spMapPersonFeature] 'Cam.Soper@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Cam.Soper@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Cam.Soper@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'Rick.Saling@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Rick.Saling@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Rick.Saling@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'antonba@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'Chris.Sfanos@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Eduardo.Laureano@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'Madsk@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Pranav.Rastogi@microsoft.com','WebJob'
exec [fe].[spMapPersonFeature] 'Pranav.Rastogi@microsoft.com','Redis Cache'
exec [fe].[spMapPersonFeature] 'andalmia@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'yuaxu@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'yuaxu@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'yuaxu@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'yuaxu@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'rajram@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'rajram@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Rick.Anderson@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'David.Wrede@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'David.Wrede@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'David.Wrede@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'David.Wrede@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'Steve.Danielson@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'Steve.Danielson@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Steve.Danielson@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Steve.Danielson@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Apurva.Joshi@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'cfowler@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'Matthew.Henderson@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Matthew.Henderson@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'Matthew.Henderson@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Matthew.Henderson@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Matthew.Henderson@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'rowmil@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'rowmil@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'sameerch@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'sameerch@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'robmcm@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'deonhe@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'deonhe@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'deonhe@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'deonhe@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'wesmc@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'wesmc@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'wesmc@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'wesmc@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'Barry.Dorrans@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'Barry.Dorrans@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'damian.edwards@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'damian.edwards@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'glennc@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'mijiang@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'kirillg@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'kirillg@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'kirillg@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'kirillg@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'sayedha@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Jeff.Hollan@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'stepsic@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'stepsic@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Tom.Archer@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'bradyg@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'bradyg@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'Daniel.Roth@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Daniel.Roth@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'Guang.Yang@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'Guang.Yang@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'stefsch@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'jonfan@microsoft.com','Logic App'
exec [fe].[spMapPersonFeature] 'jonfan@microsoft.com','Scheduler'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Cephas.Lin@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'tdykstra@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'juliako@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'juliako@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'juliako@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'juliako@microsoft.com','Mobile-Node'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'byvinyal@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'dariac@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'mohisri@microsoft.com','API App'
exec [fe].[spMapPersonFeature] 'mohisri@microsoft.com','APIM'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'sumuth@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'Erik.Reitan@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Stacks'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Security '
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','WebApp'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Hybrid-Connectivity'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','EasyAuth'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Java'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Slots'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Custom Domain '
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Backup'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','ASE'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Ibiza'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Supportability '
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','OSS'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','Gallery/CMS'
exec [fe].[spMapPersonFeature] 'tomfitz@microsoft.com','CI'
exec [fe].[spMapPersonFeature] 'Krishnan.R@microsoft.com','Notification'
exec [fe].[spMapPersonFeature] 'Krishnan.R@microsoft.com','Mobile-SDK'
exec [fe].[spMapPersonFeature] 'Krishnan.R@microsoft.com','Mobile-NET '
exec [fe].[spMapPersonFeature] 'Krishnan.R@microsoft.com','Mobile-Node'
