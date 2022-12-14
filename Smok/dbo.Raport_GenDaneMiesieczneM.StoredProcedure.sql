USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_GenDaneMiesieczneM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-12-01
-- Description:	Procedura wykonuje generowanie danych miesięcznych
-- =============================================
CREATE PROCEDURE [dbo].[Raport_GenDaneMiesieczneM]
AS
BEGIN

	SET NOCOUNT ON;

	EXEC [ZRZUT_TMP].[dbo].[GenerujDaneMiesieczne] 

	SELECT * FROM [ZRZUT_TMP].[dbo].[Log]

		--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Zrzut danych ROC: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Zrzut wygenerowany prawidłwo: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @NazwaPliku = 'Log_zrzut_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Log'

END
GO
