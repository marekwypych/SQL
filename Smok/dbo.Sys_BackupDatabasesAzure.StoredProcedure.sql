USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Sys_BackupDatabasesAzure]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2022-08-29
-- Description:	Procedura wykonuje bekap baz do azura 
-- =============================================
CREATE PROCEDURE [dbo].[Sys_BackupDatabasesAzure]
AS
BEGIN

	IF(not exists (select 1 from sys.credentials where name = 'https://monestore001.blob.core.windows.net/dbbackup'))
	BEGIN
		CREATE CREDENTIAL [https://monestore001.blob.core.windows.net/dbbackup] 
		   WITH IDENTITY = 'SHARED ACCESS SIGNATURE',  
			SECRET = 'sp=racwdl&st=2022-09-01T13:40:35Z&se=2029-09-01T21:40:35Z&spr=https&sv=2021-06-08&sr=c&sig=ngyL3aNbbc%2F5i2rc705VpdCZDroCxEIRIZpob4jIgck%3D'
	END

	DECLARE @FileName varchar(1000);
	DECLARE @AzureContainer varchar(500) 

	SET @AzureContainer = 'https://monestore001.blob.core.windows.net/dbbackup'

	SET @FileName = @AzureContainer + '/KRUS_' + CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE KRUS TO URL = @filename WITH FORMAT;

	SET @FileName = @AzureContainer + '/WSPOLNA_' + CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE WSPOLNA TO URL = @filename WITH FORMAT;

	SET @FileName = @AzureContainer + '/TERMINALE_' + CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE TERMINALE TO URL = @filename WITH FORMAT;

	SET @FileName = @AzureContainer + '/Automaty2022_' + CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE Automaty2022 TO URL = @filename WITH FORMAT

END
GO
