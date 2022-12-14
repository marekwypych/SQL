USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_SMMarcel]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 202-02-26
-- Description:	Raport miesięczny SM Gurdziądz
-- =============================================
CREATE PROCEDURE [dbo].[Raport_SMMarcel]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')
	--DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_202112' 

	--czynsze
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota, Nadawca, Tytułem, Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek in (''32102024720000630200213074'', ''10843600030101042502290002'', ''50102024720000650205966207'') OR rachunek LIKE ''__10202472233500000000%'' )
						AND LB = 1
					UNION ALL
					SELECT '''', '''', ''Łącznie'', ISNULL(ROUND(SUM(Kwota), 2), 0), '''', '''', ISNULL(ROUND(SUM(Prow_Ben), 2), 0)
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek in (''32102024720000630200213074'', ''10843600030101042502290002'', ''50102024720000650205966207'') OR rachunek LIKE ''__10202472233500000000%'' )
						AND LB = 1'
						
	EXECUTE sp_executesql @Command

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: SM Marcel'
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Wpłaty'
		
END
GO
