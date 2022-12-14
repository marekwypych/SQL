USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_SMOdrodzenieM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 202-02-26
-- Description:	Raport miesięczny SM Warszawa Marysin
-- =============================================
CREATE PROCEDURE [dbo].[Raport_SMOdrodzenieM]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--wpłaty
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						SUM(Kwota) Kwota
					FROM  ' + @ORDERS + '
						WHERE Agencja in (2909, 2910)
						AND (Rachunek =''98102036390000840200025692'' OR rachunek LIKE ''__102036392007%'')
						AND LB = 1
					GROUP BY Agencja, Data_Wpłaty, Rachunek
					UNION ALL
					SELECT '''', '''', ''Łącznie'', SUM(Kwota)
					FROM  ' + @ORDERS + '
						WHERE Agencja in (2909, 2910)
						AND (Rachunek =''98102036390000840200025692'' OR rachunek LIKE ''__102036392007%'')
						AND LB = 1'
						
	EXECUTE sp_executesql @Command

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: SM Odrodzenie'
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Zestawienie wpłat'
		
END
GO
