USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_SMGrudziadz]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 202-02-26
-- Description:	Raport miesięczny SM Gurdziądz
-- =============================================
CREATE PROCEDURE [dbo].[Raport_SMGrudziadz]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--czynsze
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota, Nadawca, Tytułem, Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek = ''93102050400000660200252239'' OR rachunek LIKE ''__102050402001%'' )
						AND LB = 2
					UNION ALL
					SELECT '''', '''', ''Łącznie'', ISNULL(ROUND(SUM(Kwota), 2), 0), '''', '''', ISNULL(ROUND(SUM(Prow_Ben), 2), 0)
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek = ''93102050400000660200252239'' OR rachunek LIKE ''__102050402001%'' )
						AND LB = 2'
						
	EXECUTE sp_executesql @Command

		--Usługi telekomunikacyjne
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota, Nadawca, Tytułem, Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek = ''48102050400000690200253484'' OR rachunek LIKE ''__102050402002%'')
						AND LB = 2
					UNION ALL
					SELECT '''', '''', ''Łącznie'', ISNULL(ROUND(SUM(Kwota), 2), 0), '''', '''', ISNULL(ROUND(SUM(Prow_Ben), 2), 0)
					FROM  ' + @ORDERS + '
						WHERE 
						(Rachunek = ''48102050400000690200253484'' OR rachunek LIKE ''__102050402002%'')
						AND LB = 2'
						
	EXECUTE sp_executesql @Command

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: SM Grudziądz'
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Czynsze',
		'Usł. telekom'
		
END
GO
