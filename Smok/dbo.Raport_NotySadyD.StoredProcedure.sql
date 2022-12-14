USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_NotySadyD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2021-10-15
-- Description:	Procedura generujaca raport z wypłat za ostatnie siedem dni dla zdefiniowanych sądów dla not
-- =============================================
CREATE PROCEDURE [dbo].[Raport_NotySadyD]
AS
BEGIN

	DECLARE @Numer varchar(15)
	DECLARE @dataP date, @dataK date, @Data date
	DECLARE @SaWplaty BIT = 0

	SET @data = GETDATE()
	SET @dataK = DATEADD(day, -1, @data)
	
	IF(DATEPART(WEEKDAY, @dataK) = 1)
		SET @dataP = DATEADD(day, -2, @dataK)
	ELSE
		SET @DataP = @dataK

	SELECT w.Sender Nadawca,
			CONVERT(varchar, w.CreatedAt, 20) [Data dyspozycji],
			CONVERT(varchar, a.AgencyNumber) + ', ' + adr.City + ', ' + adr.Street Agencja,
			ISNULL(w.Recipient, '') Odbiorca,
			ISNULL(w.Title, '') [Tytuł],
			w.Amount Kwota,
			ISNULL(w.DocumentNo, '') AS [Konto]
		INTO #TEMP
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Withdrawal w on wd.Id = w.DefinitionId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].WithdrawalAccountDict wad on wd.WithdrawalAccountDictId = wad.id
		join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on w.TellerSessionID = ts.id
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on ts.AgencyId = a.Id
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Address adr on a.AddressId = adr.Id 
		join [ROCDB_RAP].[Monetia_PROD].[dbo].AgencyTypeDict at on a.AgencyTypeId = at.Id 
		where 
			CONVERT(date, w.CreatedAt) between @dataP and @dataK
			and w.WithdrawalStatusId = 1
			and wad.AccountNumber = '000000000404'
		order by 1

		IF (@@ROWCOUNT > 0)
			SET @SaWplaty = 1 

			--index na potrzeby sortowania wyniku 
		CREATE CLUSTERED INDEX i1 ON #TEMP ([Data dyspozycji] ASC)

		SELECT * FROM #TEMP 
			UNION ALL
			SELECT '','','','','Łącznie:', ISNULL(SUM(Kwota), 0), '' FROM #TEMP
	
	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100), @Command nvarchar(4000)
	IF(@SaWplaty = 1)
		BEGIN
			SELECT @temat = '''SĄ WYPŁATY! - noty Grudziądz: ' + CONVERT(varchar(10), @dataP) + ' - ' + CONVERT(varchar(10), @dataK) + ''''
			SELECT @tresc = '''Należy przygotować noty za poprzedni dzień'''
		END
		ELSE
		BEGIN
			SELECT @temat = '''BRAK WYPŁAT - noty Grudziądz: ' + CONVERT(varchar(10), @dataP) + ' - ' + CONVERT(varchar(10), @dataK) + ''''
			SELECT @tresc = ''''''
		END
	SELECT @NazwaPliku = '''Raport_wypłat_noty_Grudziądz_' + CONVERT(varchar, CONVERT(date, GETDATE())) + ''''
	SELECT @Command = 'SELECT ' + @Temat + ' AS temat, ' + @tresc + ' AS tresc, ' + @NazwaPliku + ', ''000000000404''';
	EXECUTE sp_executesql @Command
	
END
GO
