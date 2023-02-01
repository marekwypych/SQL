﻿USE [WSPOLNA]
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

	IF(not exists (select 1 from sys.credentials where name = 'https://xxx.blob.core.windows.net/xxx'))
	BEGIN
		CREATE CREDENTIAL [https://xxx.blob.core.windows.net/xxx] 
		   WITH IDENTITY = 'SHARED ACCESS SIGNATURE',  
			SECRET = 'tu podaj klucz dostępu do contenera'
	END

	DECLARE @FileName varchar(1000);
	DECLARE @AzureContainer varchar(500) 

	SET @AzureContainer = 'https://xxx.blob.core.windows.net/xxx'

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
