USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_AgentSzczegolowyM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-01-24
-- Description:	Raport szczegółowy miesięczny dla Agenta
-- =============================================
CREATE PROCEDURE [dbo].[Raport_AgentSzczegolowyM]
	@IDAgenta INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')
	DECLARE @Kolumny VARCHAR(500) = ''
	DECLARE @Agencja INT
	DECLARE @Command nvarchar(1500)

	--tabela tymczasowa z numerami agencji agenta na których były obroty w danycm miesiącu
	CREATE TABLE #AGENCIES (Agencja INT)
	SET @Command = 'SELECT DISTINCT Agencja FROM ' + @ORDERS + ' WHERE Agencja IN(SELECT AgencyNumber FROM [ROCDB_RAP].[Monetia_PROD].dbo.Agency WHERE AgentID = ' + CONVERT(NVARCHAR, @IDAgenta) + ')'
	INSERT INTO #AGENCIES EXEC sp_executesql @Command

	DECLARE Agencje CURSOR FOR SELECT Agencja FROM #AGENCIES ORDER BY Agencja
	OPEN Agencje
	FETCH NEXT FROM Agencje INTO @Agencja

	WHILE @@FETCH_STATUS = 0 
	BEGIN
		SET @Command = 
			'SELECT ' +
				CONVERT(varchar, @Agencja) + ' Agencja, 	
				ISNULL(klient, ''Razem w agencji:'') [Rodzaj wpłaty], 
				COUNT(*) [Liczba wpłat], 
				SUM(kwota) [Saldo wpłat w agencji], 
				SUM(Prow_Kl) [Saldo pobranej prowizji], 
				ROUND(SUM(Wynagr_agenta), 2) [Wysokość wynagrodzenia]
			FROM ' + @ORDERS + '
				WHERE Agencja = ' + CONVERT(varchar, @Agencja) +'
				GROUP BY Klient WITH ROLLUP'
		
		EXECUTE sp_executesql @Command
		SELECT @Kolumny = @Kolumny + ','''  + CONVERT(varchar, @Agencja) + ''''
		FETCH NEXT FROM Agencje INTO @Agencja
	END
	CLOSE Agencje
	DEALLOCATE Agencje
	
	--ostatnia tabela z podsumowaniem na agencje
	SET @Command = 
		'SELECT  
			ISNULL(CONVERT(varchar, Agencja), ''Podsumowanie'') Agencja,
			COUNT(*) [Liczba wpłat], 
			ROUND(SUM(kwota), 2) [Saldo wpłat w agencji], 
			ROUND(SUM(Prow_Kl), 2) [Saldo pobranej prowizji], 
			ROUND(SUM(Wynagr_agenta), 2) [Wysokość wynagrodzenia]
		FROM ' + @ORDERS + ' o
			WHERE o.Agencja IN (SELECT Agencja FROM #AGENCIES)
			GROUP BY o.Agencja WITH ROLLUP'

	EXECUTE sp_executesql @Command
	SELECT @Kolumny = @Kolumny + ',''Podsumowanie' + ''''

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @Tresc VARCHAR(1000), @NazwaPliku VARCHAR(100), @Agent varchar(100) 
	SELECT @Agent = ShortName FROM [ROCDB_RAP].[Monetia_PROD].dbo.Agents WHERE ID = @IDAgenta

	SELECT @Temat = '''Miesięczny raport szczegółowy agenta: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) +''''
	SELECT @tresc = '''Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Agent: ' + @Agent + ''''
	SELECT @NazwaPliku = '''Raport_szczegolowy_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + ''''
 	SELECT @Command = 'SELECT ' + @Temat + ' AS temat, ' + @tresc + ' AS tresc, ' + @NazwaPliku + @Kolumny;
	EXECUTE sp_executesql @Command

END
GO
