USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_BNPLuban_3]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-10-28
-- Description:	Raport miesięczny wypłat BNP lubań - część 1
-- =============================================
CREATE PROCEDURE [dbo].[Raport_BNPLuban_3]
AS
BEGIN
	SET NOCOUNT ON;
	declare @DataOd date 
	declare @DataDo date
	declare @Offset int
	declare @data date
	DECLARE @IDRachunku int
	DECLARE @NazwyRachunkow nvarchar(4000) = ''
	declare @NazwaRachunku varchar(31)

	SET @data = GETDATE()
	set @DataOd = DATEADD(MM, -1, DATEADD(dd, -DAY(@data)+1, @data))
	set @DataDo = DATEADD(dd, -DAY(@data), @data)

	DECLARE Rachunki CURSOR FOR	
		SELECT wd.id, wd.Name
		  FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd
		  join [ROCDB_RAP].[Monetia_PROD].[dbo].WithdrawalAccountDict wad on wd.WithdrawalAccountDictId = wad.id
		  where 
			wad.AccountNumber in ('000000000380')
			order by 1
	OPEN Rachunki
	FETCH NEXT FROM Rachunki INTO @IDRachunku, @NazwaRachunku
	WHILE @@FETCH_STATUS = 0 
	BEGIN	
		SET @NazwyRachunkow = @NazwyRachunkow + ',' + '''' + @NazwaRachunku + '''' 
		SELECT w.Sender Nadawca,
			   CONVERT(varchar, w.CreatedAt, 20) [Data dyspozycji],
			   CONVERT(varchar, a.AgencyNumber) + ', ' + adr.City + ', ' + adr.Street Agencja,
			   ISNULL(w.Recipient, '') Odbiorca,
			   ISNULL(w.Title, '') [Tytuł],
			   w.Amount Kwota,
				ISNULL(w.DocumentNo, '') AS [Identyfikator]
			INTO #TEMP
			from [ROCDB_RAP].[Monetia_PROD].[dbo].Withdrawal w 
			join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on w.TellerSessionID = ts.id
			join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on ts.AgencyId = a.Id
			join [ROCDB_RAP].[Monetia_PROD].[dbo].Address adr on a.AddressId = adr.Id 
			where 
				 CONVERT(date, w.CreatedAt) between @DataOd and @DataDo
				and w.DefinitionId = @IDRachunku
				and w.WithdrawalStatusID = 1
				order by 1

			--index na potrzeby sortowania wyniku 
			CREATE CLUSTERED INDEX i1 ON #TEMP ([Data dyspozycji] ASC)

			SELECT * FROM #TEMP 
				UNION ALL
				SELECT '','','','','Łącznie:', ISNULL(SUM(Kwota), 0), '' FROM #TEMP

			DROP TABLE #TEMP

		--pobieramy następny wiersz
		FETCH NEXT FROM Rachunki INTO @IDRachunku, @NazwaRachunku
	END 
	CLOSE Rachunki
	DEALLOCATE Rachunki

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100), @Command nvarchar(4000)
	SELECT @temat = '''Raport wypłat: ' + CONVERT(varchar(10), @DataOd) + ' - ' + CONVERT(varchar(10), @DataDo) + ''''
	SELECT @tresc = ''''''
	SELECT @NazwaPliku = '''Raport_wypłat_' + CONVERT(varchar, CONVERT(date, GETDATE())) + ''''
	SELECT @Command = 'SELECT ' + @Temat + ' AS temat, ' + @tresc + ' AS tresc, ' + @NazwaPliku + @NazwyRachunkow;
	EXECUTE sp_executesql @Command
	
END
GO
