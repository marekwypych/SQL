USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raporty_ListaDoWysylki]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2019-10-16
-- Description:	Procedura listująca raporty do wysłania
-- =============================================
CREATE PROCEDURE [dbo].[Raporty_ListaDoWysylki]
AS
BEGIN

	--bieżący czas i data w osobnych zmiennych
	DECLARE @DataWysylki date = CONVERT(date, GETDATE())
	--DECLARE @DataWysylki date = CONVERT(date, '2020-05-03') -- NA TESTY
	DECLARE @GodzinaWysylki time(0) = CONVERT(time(0), GETDATE())
	DECLARE @Offset int = IIF(DATEPART(WEEKDAY, @DataWysylki) = 2, 2, 0)
	DECLARE @t char(1) = IIF(DATEPART(WEEKDAY, @DataWysylki) = 2, 't', null)
	DECLARE @m char(1) = IIF(dbo.fCzyPierwszyDzienRoboczy(@DataWysylki) = 1, 'm', null)
	DECLARE @dzien int = DATEPART(dd, @DataWysylki)
	DECLARE @ABR bit = IIF(@DataWysylki <= (SELECT CONVERT(date, MAX(backup_finish_date)) FROM [ROCDB_RAP].msdb.dbo.backupset WHERE database_name = 'Monetia_PROD' AND recovery_model = 'FULL'), 1, 0)
	DECLARE @ARS bit = IIF(@DataWysylki <= (SELECT DataOstatniegoPrzetwarzania FROM TERMINALE.dbo.Parametry), 1, 0)
	DECLARE @Swieto bit = 0
	SELECT @Swieto = 1 from SWIETA WHERE Data = CONVERT(date, @DataWysylki)

	SELECT ID, Polecenie, Maile, Szablon, Pakuj, JedenExel, Procedura, Opis
		FROM RAPORTY_DEF rd	
		WHERE Aktywny = 1
		AND rd.Godzina <= @GodzinaWysylki
		AND rd.AktualnaBazaROC <= @ABR
		AND rd.AktualnaReplikaSIX <= @ARS
		AND rd.WysylajWSwieta >= @Swieto
		AND (rd.Czestotliwosc IN ('d', @t, @m) OR (rd.Czestotliwosc = 'o' AND rd.DzienWysylki BETWEEN @dzien-@Offset AND @dzien))
		AND NOT EXISTS (SELECT 1 FROM RAPORTY_LOG rl
							WHERE rl.IDRaportu = rd.ID AND 
								CONVERT(Date, rl.Data) = @DataWysylki)

END
GO
