USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_FakturaInnogy]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-02-26
-- Description:	Raport miesięczny wypłat dla agencji i klienta
-- =============================================
CREATE PROCEDURE [dbo].[Raport_FakturaInnogy]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--wpłaty Innogy Polska
	SET @Command = 'SELECT 
						Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						CONVERT(money, Kwota) Kwota,
						Nadawca,
						Tytułem,
						CONVERT(money, Prow_Ben) Prowizja
					FROM  ' + @ORDERS + '
						WHERE Klient = ''Innogy Polska'' AND LB=1 AND Agencja IN(1643, 938, 972)'
					
	EXECUTE sp_executesql @Command

	SET @Command = 'SELECT 
						ISNULL(CONVERT(varchar(50), Agencja), ''Wszytskie'') Agencja,
						CASE [typ transakcji]
							WHEN 0 THEN ''Gotówka''
							WHEN 1 THEN ''Karta''
							ELSE ''Razem''
						END	[Płatność],
						COUNT(*) [Liczba wpłat],
						SUM(CONVERT(money, Kwota)) [Suma wpłat],
						SUM(CONVERT(money, Prow_Ben)) [Suma prowizji]
					FROM  ' + @ORDERS + '
						WHERE Klient = ''Innogy Polska'' AND LB=1 AND Agencja IN(1643, 938, 972)
						GROUP BY CUBE (Agencja, [typ transakcji])
						ORDER BY 1, 2'
					
	EXECUTE sp_executesql @Command
	
	--wpłaty Innogy Polska
	SET @Command = 'SELECT 
						Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						CONVERT(money, Kwota) Kwota,
						Nadawca,
						Tytułem,
						CONVERT(money, Prow_Ben) Prowizja
					FROM  ' + @ORDERS + '
						WHERE Klient = ''Innogy Stoen Operator'' AND LB=1 AND Agencja IN(1643, 938, 972)'
					
	EXECUTE sp_executesql @Command

	SET @Command = 'SELECT 
						ISNULL(CONVERT(varchar(50), Agencja), ''Wszytskie'') Agencja,
						CASE [typ transakcji]
							WHEN 0 THEN ''Gotówka''
							WHEN 1 THEN ''Karta''
							ELSE ''Razem''
						END	[Płatność],
						COUNT(*) [Liczba wpłat],
						SUM(CONVERT(money, Kwota)) [Suma wpłat],
						SUM(CONVERT(money, Prow_Ben)) [Suma prowizji]
					FROM  ' + @ORDERS + '
						WHERE Klient = ''Innogy Stoen Operator'' AND LB=1 AND Agencja IN(1643, 938, 972)
						GROUP BY CUBE (Agencja, [typ transakcji])
						ORDER BY 1, 2'
					
	EXECUTE sp_executesql @Command

	--agencje
	SELECT
		ag.AgencyNumber Agencja,
		adr.City Miasto,
		adr.Street Adres
	FROM [ROCDB_RAP].[Monetia_PROD].dbo.Agency ag
	JOIN [ROCDB_RAP].[Monetia_PROD].dbo.Address adr ON ag.AddressId = adr.Id 
		WHERE AgencyNumber IN(1643, 938, 972)

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport wpłat w agencjach Monetii za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) 
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Innogy Polska',
		'Innogy Polska - podsumowanie',
		'Innogy Stoen',
		'Innogy Stoen - podsumowanie',
		'Agencje'

END
GO
