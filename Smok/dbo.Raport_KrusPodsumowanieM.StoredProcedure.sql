USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_KrusPodsumowanieM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2019-12-11
-- Description:	Raport miesięczny z podsumowaniem transakcji przetwarzanych z KRUS Białystok
-- =============================================
CREATE PROCEDURE [dbo].[Raport_KrusPodsumowanieM]
	@IDKrus INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Rok int, @Miesiac int
	DECLARE @NazwaKrus VARCHAR(50) 
	SELECT @NazwaKrus = Nazwa FROM [KRUS].[dbo].[KRUS] WHERE ID = @IDKrus

	SELECT @Rok = DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))	
	SELECT @Miesiac = DATEPART(mm, GETDATE()-DATEPART(dd, GETDATE()))	

	SELECT CONVERT(varchar, ROW_NUMBER() OVER(ORDER BY DataUtworzenia ASC)) AS LP, 
			CONVERT(varchar, pl.DataUtworzenia, 23) AS [Data utworzenia], 
			CASE
				WHEN pk.Status = 0 THEN 'Zrealizowane'
				WHEN pk.Status = 1 THEN 'Anulowane'
			END AS Status,
			COUNT(*) AS [Liczba przekazów], 
			CASE
				WHEN pk.Status = 0 THEN SUM(pk.KW)
				WHEN pk.Status = 1 THEN SUM(pk.KW)*-1
			END AS Kwota
		FROM [KRUS].[dbo].[Pliki] pl
		INNER JOIN [KRUS].[dbo].[Przekazy] pk ON pl.ID = pk.IDPlikuWej
			WHERE DATEPART(yyyy, pl.DataUtworzenia) = @Rok
			AND DATEPART(mm, pl.DataUtworzenia) = @Miesiac
			AND pl.IDKrus = @IDKrus
			GROUP BY pk.Status, pl.DataUtworzenia
	UNION ALL
	SELECT '', 'Łącznie',
			CASE
				WHEN pk.Status = 0 THEN 'Zrealizowane'
				WHEN pk.Status = 1 THEN 'Anulowane'
			END AS Status,
			COUNT(*) AS [Liczba przekazów], 
			CASE
				WHEN pk.Status = 0 THEN SUM(pk.KW)
				WHEN pk.Status = 1 THEN SUM(pk.KW)*-1
			END AS Kwota
		FROM [KRUS].[dbo].[Pliki] pl
		INNER JOIN [KRUS].[dbo].[Przekazy] pk ON pl.ID = pk.IDPlikuWej
			WHERE DATEPART(yyyy, pl.DataUtworzenia) = @Rok
			AND DATEPART(mm, pl.DataUtworzenia) = @Miesiac
			AND pl.IDKrus = @IDKrus
			GROUP BY pk.Status
	

	  --obowiązkowa ostatnia tabela z parametrami maila
	  --obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Podsumowanie miesiąca ' + CONVERT(varchar, @Rok) + '-' + FORMAT(@Miesiac, '00') + ' - ' +@NazwaKrus 
	  SELECT @tresc = 'Raport przedstawia liczbę zrealizwoanych przekazów dla ' + @NazwaKrus

	  SELECT 
		@Temat AS Temat,
		@tresc AS Tresc,
		'Raport_miesięcznyKrus_' + CONVERT(varchar, @Rok) + '-' + FORMAT(@Miesiac, '00')+ '-' +@NazwaKrus,
		'RaportMiesięczny'
END
GO
