USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_FakturaBeneficjentaMLB2]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-02-26
-- Description:	Raport miesięczny wypłat dla agencji i klienta
-- =============================================
CREATE PROCEDURE [dbo].[Raport_FakturaBeneficjentaMLB2]
  @Klient varchar(500)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--wpłaty lb1
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota,
						Nadawca,
						Tytułem,
						Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=1 AND Prow_ben>0
					UNION ALL
					SELECT '''', '''', ''Łącznie'', ISNULL(SUM(Kwota), 0), ''Liczba'', CONVERT(varchar, COUNT(*)), ISNULL(ROUND(SUM(Prow_Ben), 2), 0) 
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=1 AND Prow_ben>0'
					
	EXECUTE sp_executesql @Command
	
	--wpłaty lb2
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota,
						Nadawca,
						Tytułem,
						Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=2 AND Prow_ben>0
					UNION ALL
					SELECT '''', '''', ''Łącznie'', ISNULL(SUM(Kwota), 0), ''Liczba'', CONVERT(varchar, COUNT(*)), ROUND(SUM(Prow_Ben), 2) 
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=2 AND Prow_ben>0'
					
	EXECUTE sp_executesql @Command

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br> ' + @Klient
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'wpłaty w siedzibie',
		'agencje zewnętrzne'


END
GO
