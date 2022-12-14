USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_KsiegowoscM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2020-04-01
-- Description:	Zestawienia dla księgowiści na potrzeby wystawiania faktur
-- =============================================
CREATE PROCEDURE [dbo].[Raport_KsiegowoscM]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')
	DECLARE @Rok int = DATEPART(yyyy, @DataRaportu)	
	DECLARE @Miesiac int = DATEPART(mm, @DataRaportu)

	exec Raport_FakturaBeneficjentaPomocniczaM 'KSM'
	
	--KSM wypłaty
		SELECT 
		CONVERT(varchar, Numer_Agencji) Agencja,
		CONVERT(varchar, Data_wypłaty, 23) Data,
		Kwota,
		Wyplacajacy Wypłacający,
		Tytułem
		FROM [ORDERS].[dbo].[Wypłaty]
		WHERE [numer konta] = '4000000000419'
		AND Status = 'Zrealizowana'
		AND DATEPART(yyyy, Data_wypłaty) = @Rok
		AND DATEPART(mm, Data_wypłaty) = @Miesiac
	UNION ALL
		SELECT 
		'','Łącznie', ISNULL(SUM(Kwota), 0), 'Liczba:', CONVERT(varchar, COUNT(*))	
		FROM [ORDERS].[dbo].[Wypłaty]
		WHERE [numer konta] = '4000000000419'
		AND Status = 'Zrealizowana'
		AND DATEPART(yyyy, Data_wypłaty) = @Rok
		AND DATEPART(mm, Data_wypłaty) = @Miesiac
	ORDER BY 2

	exec Raport_FakturaBeneficjentaPomocniczaM 'SM Łódź Czerwony Rynek'
	exec Raport_FakturaBeneficjentaPomocniczaM 'SM Mielec'
	
	--sm mielec zbiorcze
	SET @Command = 'SELECT CONVERT(date, [Data_wpłaty]) Data, COUNT(*) Liczba, SUM(Kwota) Kwota, SUM(Prow_ben) Prowizja
					FROM  ' + @ORDERS + ' WHERE Klient = ''sm mielec'' AND lb = 1 GROUP BY [data_wpłaty] ORDER BY Data'
	EXECUTE sp_executesql @Command
	
	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Beneficjenci - dane do faktur: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @NazwaPliku = 'Beneficjenci_faktury_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'KSM wpłaty',
		'KSM wypłaty',
		'SM Łódź Czerwony Rynek',
		'SM Mielec',
		'SM Mielec zbiorcze'
END
GO
