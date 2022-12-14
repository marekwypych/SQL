USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Sys_BackupDatabasesLocal]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sys_BackupDatabasesLocal]
AS
BEGIN

	DECLARE @FileName varchar(1000);

	SET @FileName = 'C:\_BACKUP\KRUS_'+CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE KRUS TO DISK=@filename WITH FORMAT;

	SET @FileName = 'C:\_BACKUP\WSPOLNA_'+CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE WSPOLNA TO DISK=@filename WITH FORMAT;

	SET @FileName = 'C:\_BACKUP\TERMINALE_'+CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE TERMINALE TO DISK=@filename WITH FORMAT;

	SET @FileName = 'C:\_BACKUP\Automaty2022_'+CONVERT(varchar, GETDATE(), 112)+'.bak';
	BACKUP DATABASE Automaty2022 TO DISK=@filename WITH FORMAT;

END
GO
