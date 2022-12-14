USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_WyplatyMOPSRybnikD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-01-22
-- Description:	Raport tygodniowy z wypłat dla agencji i numerów kont
-- =============================================
CREATE PROCEDURE [dbo].[Raport_WyplatyMOPSRybnikD]
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @dataP date, @dataK date 
	SET @dataK = DATEADD(day, -1, GETDATE())
	
	IF(DATEPART(WEEKDAY, @dataK) = 1)
		SET @dataP = DATEADD(day, -2, @dataK)
	ELSE
		SET @DataP = @dataK

		SELECT	0, --CONVERT(varchar, w.NumerAgencji) Agencja, 
			CONVERT(varchar, w.CreatedAt, 23) Data, 
			w.Amount, 
			w.Recipient Wypłacający, 
			w.Title Tytułem,
			w.DocumentNo IDDokumentu,
			w.ListNo
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Withdrawal] w
		  WHERE CONVERT(Date, w.CreatedAt) BETWEEN @dataP AND @DataK
			AND w.DefinitionId = 111
	UNION
		SELECT '','Łącznie kwota', SUM(Amount), 'Liczba', CONVERT(varchar, COUNT(*)), '',''
			FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Withdrawal] w
			  WHERE CONVERT(Date, w.CreatedAt) BETWEEN @dataP AND @DataK
				AND w.DefinitionId = 111
	ORDER BY 1 DESC
		  
	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	SELECT @temat = 'Raport wypłat MOPS Rybnik ' +  CONVERT(varchar, CONVERT(date, @dataP))
	SELECT @tresc = 'Okres: ' + CONVERT(varchar(10), CONVERT(varchar(10), @dataP)) + ' - ' + CONVERT(varchar(10), CONVERT(varchar(10), @dataK))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Raport_wypłat_MOPSRybnik_' + CONVERT(varchar, CONVERT(date, @dataP)),
		'Wypłaty'

END
GO
