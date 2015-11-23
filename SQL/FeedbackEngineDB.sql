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


select * from [fe].[tblPeople]