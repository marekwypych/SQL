USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_NotySadyT_ROC]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2021-10-15
-- Description:	Procedura generujaca raport z wypłat za ostatnie siedem dni dla zdefiniowanych sądów dla not
-- =============================================
CREATE PROCEDURE [dbo].[Raport_NotySadyT_ROC]
AS
BEGIN
	declare @DataOd date 
	declare @DataDo date
	declare @Offset int
	declare @data date
	DECLARE @Numer varchar(15)
	DECLARE @NazwyRachunkow nvarchar(4000) = ''
	declare @NazwaRachunku varchar(150)

	SET @data = GETDATE()
	SET @Offset = -DATEPART(weekday, @data) + 2
	SET @DataOd = DATEADD(day, -7 + @Offset, @data) 
	SET @DataDo = DATEADD(day, -1 + @Offset, @data)

	--SELECT @DataOd = '2022-03-01', @DataDo = '2022-03-13'

	DECLARE Rachunki CURSOR FOR	
		SELECT distinct wad.AccountNumber, wd.Name
		  FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd
		  join [ROCDB_RAP].[Monetia_PROD].[dbo].WithdrawalAccountDict wad on wd.WithdrawalAccountDictId = wad.id
		  join [ROCDB_RAP].[Monetia_PROD].[dbo].AgencyWithdrawalDict aw on wd.Id = aw.WithdrawalDefinitionId
		  join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on aw.AgencyId = a.Id
		  join [ROCDB_RAP].[Monetia_PROD].[dbo].Withdrawal w on wd.Id = w.DefinitionId
		  where 
			CONVERT(date, w.CreatedAt) between @DataOd and @DataDo
			and w.WithdrawalStatusId = 1
			--and wd.CreditingTypesForWithdrawalDictId = 1
			and (a.AgencyNumber in (2739,2738,2719,2681,2682,2680,2685,2716,2718,2177,2264,2593,2478,1986,2674,2592,2405,2447,2719,2079,2411,2471,2595,2684,2614,2409,2685,2601,2615,2646,2278,2679,2683,2683) or wad.AccountNumber in ('000000000225','000000000402','000000000437','000000000242', '000000000221', '000000000351'))
			and wd.id not in (199, 225, 242,321, 85)
			
			order by 1

	OPEN Rachunki
	FETCH NEXT FROM Rachunki INTO @Numer, @NazwaRachunku
	WHILE @@FETCH_STATUS = 0 
	BEGIN	
		SET @NazwyRachunkow = @NazwyRachunkow + ',' + '''' + @NazwaRachunku + '''' 

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
				 CONVERT(date, w.CreatedAt) between @DataOd and @DataDo
				 and w.WithdrawalStatusId = 1
				 and wad.AccountNumber = @Numer
				order by 1

			--index na potrzeby sortowania wyniku 
			CREATE CLUSTERED INDEX i1 ON #TEMP ([Data dyspozycji] ASC)

			SELECT * FROM #TEMP 
				UNION ALL
				SELECT '','','','','Łącznie:', ISNULL(SUM(Kwota), 0), '' FROM #TEMP

			DROP TABLE #TEMP

		--pobieramy następny wiersz
		FETCH NEXT FROM Rachunki INTO @Numer, @NazwaRachunku
	END 
	CLOSE Rachunki
	DEALLOCATE Rachunki

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100), @Command nvarchar(4000)
	SELECT @temat = '''Raport wypłat - noty tygodniowe: ' + CONVERT(varchar(10), @DataOd) + ' - ' + CONVERT(varchar(10), @DataDo) + ''''
	SELECT @tresc = ''''''
	SELECT @NazwaPliku = '''Raport_wypłat_noty_tygodniowe_' + CONVERT(varchar, CONVERT(date, GETDATE())) + ''''
	SELECT @Command = 'SELECT ' + @Temat + ' AS temat, ' + @tresc + ' AS tresc, ' + @NazwaPliku + @NazwyRachunkow;
	EXECUTE sp_executesql @Command
	
END
GO
