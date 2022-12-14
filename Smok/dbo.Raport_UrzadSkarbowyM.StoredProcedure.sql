USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_UrzadSkarbowyM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-01-29
-- Description:	Miesięczny raport wpłat i wypłat dla urzędów skarbowych
-- =============================================
CREATE PROCEDURE [dbo].[Raport_UrzadSkarbowyM]
	@Klient varchar(100),
	@KontoWyplat varchar(20)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Rok int, @Miesiac int
	SELECT @Rok = DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))	
	SELECT @Miesiac = DATEPART(mm, GETDATE()-DATEPART(dd, GETDATE()))
	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--wpłaty
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota,
						Nadawca,
						Tytułem
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND Prow_Ben >0
					UNION ALL
					SELECT '''', '''', ''Łącznie'', SUM(Kwota), ''Liczba'', CONVERT(varchar, COUNT(*))
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND Prow_Ben > 0'
						
	EXECUTE sp_executesql @Command

	--wypłaty
	SELECT 
		CONVERT(varchar, Numer_Agencji) Agencja,
		CONVERT(varchar, Data_wypłaty, 23) Data,
		Kwota,
		Wyplacajacy Wypłacający,
		Tytułem
		FROM [ORDERS].[dbo].[Wypłaty]
		WHERE [numer konta] = @KontoWyplat
		AND Status = 'Zrealizowana'
		AND DATEPART(yyyy, Data_wypłaty) = @Rok
		AND DATEPART(mm, Data_wypłaty) = @Miesiac
	UNION ALL
		SELECT 
		'','Łącznie', ISNULL(SUM(Kwota), 0), 'Liczba:', CONVERT(varchar, COUNT(*))	
		FROM [ORDERS].[dbo].[Wypłaty]
		WHERE [numer konta] = @KontoWyplat
		AND Status = 'Zrealizowana'
		AND DATEPART(yyyy, Data_wypłaty) = @Rok
		AND DATEPART(mm, Data_wypłaty) = @Miesiac
	ORDER BY 2

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat i wypłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: ' + @Klient
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Wpłaty',
		'Wypłaty'
END
GO
