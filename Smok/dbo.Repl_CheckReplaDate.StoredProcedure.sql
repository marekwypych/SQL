USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Repl_CheckReplaDate]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-07-08
-- Description:	Procedura uaktualnia datę ostatniego 
-- =============================================
CREATE PROCEDURE [dbo].[Repl_CheckReplaDate]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Data Date
	SELECT @Data = CONVERT(date, MAX(backup_finish_date))
			FROM [ROCDB_RAP].msdb.dbo.backupset 
				WHERE database_name = 'Monetia_PROD'
				AND recovery_model = 'FULL'
	SELECT @Data DataBazy

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	
	IF(@Data = CONVERT(date, GETDATE()))
	BEGIN
		SELECT @temat = 'Monetia_PROD - aktualna'
		SELECT @tresc = 'Data bazy: '  + CONVERT(varchar, @Data)
	END
	ELSE
	BEGIN
		SELECT @temat = 'Monetia_PROD - nieaktualna!'
		SELECT @tresc = 'Data bazy: '  + CONVERT(varchar, @Data) + '<br>' + 'Piszcie do Oktaby i do Oskar Dębowski oskar.debowski@aplitt.pl - to jest admin SQLi'
	END

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'DataBazy',
		'DataBazy'
END
GO
