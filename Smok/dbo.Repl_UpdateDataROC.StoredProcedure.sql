USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Repl_UpdateDataROC]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-07-08
-- Description:	Procedura uaktualnia datę ostatniego 
-- =============================================
CREATE PROCEDURE [dbo].[Repl_UpdateDataROC]
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE [dbo].[REPL_PARAM] SET [DataOstatniejReplikacji] = 
		(SELECT CONVERT(date, MAX(backup_finish_date)) Last_backup
			FROM [ROCDB_RAP].msdb.dbo.backupset 
				WHERE database_name = 'Monetia_PROD'
				AND recovery_model = 'FULL')

END
GO
