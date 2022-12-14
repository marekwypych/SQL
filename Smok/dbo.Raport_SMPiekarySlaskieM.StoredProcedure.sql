USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_SMPiekarySlaskieM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 202-02-26
-- Description:	Raport miesięczny SM Piekary Śląskie
-- =============================================
CREATE PROCEDURE [dbo].[Raport_SMPiekarySlaskieM]
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
						Kwota, nadawca, Tytułem, Prow_Ben
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek =''47102023680000290200223149'' OR rachunek LIKE ''37102023680000200200269845'' OR rachunek LIKE ''36102023680000200200270348'' OR rachunek LIKE ''__102023682884%'')
						AND LB = 1
					UNION ALL
					SELECT '''', '''', ''Łącznie'', SUM(Kwota), '''', '''', SUM(Prow_Ben)
					FROM  ' + @ORDERS + '
						WHERE 
						 (Rachunek =''47102023680000290200223149'' OR rachunek LIKE ''37102023680000200200269845'' OR rachunek LIKE ''36102023680000200200270348'' OR rachunek LIKE ''__102023682884%'')
						AND LB = 1'
						
	EXECUTE sp_executesql @Command

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: SM Piekary Śląskie'
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Zestawienie wpłat'
		
END
GO
