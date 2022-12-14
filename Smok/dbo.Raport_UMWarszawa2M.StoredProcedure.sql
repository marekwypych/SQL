USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_UMWarszawa2M]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 202-02-26
-- Description:	Raport miesięczny UM Warszawa 
-- =============================================
CREATE PROCEDURE [dbo].[Raport_UMWarszawa2M]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--dodajemy dane do bazy zrzutu
	declare @data_do date,  @data_od date, @data date
	set @data = GETDATE()
	set @data_do = DATEADD(dd, -DAY(@data)+1, @data)
	set @data_od = DATEADD(MM, -1, @data_do)

	SELECT 
		CONVERT(varchar, ag.AgencyNumber) Agencja,
		CONVERT(varchar, dc.CartDate, 20) Data,
		d.AccountNumber Rachunek,
		d.Amount Kwota,
		d.Sender Nadawca,
		d.Title Tytuł
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
		AND dc.CartDate BETWEEN @data_od AND @data_do
		AND d.DepositStatusDictId = 4
		AND (d.AccountNumber  IN ('26103015080000000550001144') OR d.AccountNumber LIKE '%103019447519%')
	UNION ALL
	SELECT '', '', 'Łącznie', SUM(d.Amount), 'Liczba', CONVERT(varchar, COUNT(*))
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
			AND dc.CartDate BETWEEN @data_od AND @data_do
			AND d.DepositStatusDictId = 4
			AND (d.AccountNumber  IN ('26103015080000000550001144') OR d.AccountNumber LIKE '%103019447519%')

	SELECT 
		CONVERT(varchar, ag.AgencyNumber) Agencja,
		CONVERT(varchar, dc.CartDate, 20) Data,
		d.AccountNumber Rachunek,
		d.Amount Kwota,
		d.Sender Nadawca,
		d.Title Tytuł
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
		AND dc.CartDate BETWEEN @data_od AND @data_do
		AND d.DepositStatusDictId = 4
		AND (d.AccountNumber IN ('70103015080000000550001128'))
	UNION ALL
	SELECT '', '', 'Łącznie', SUM(d.Amount), 'Liczba', CONVERT(varchar, COUNT(*))
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
			AND dc.CartDate BETWEEN @data_od AND @data_do
			AND d.DepositStatusDictId = 4
			AND (d.AccountNumber IN ('70103015080000000550001128'))

	SELECT 
		CONVERT(varchar, ag.AgencyNumber) Agencja,
		CONVERT(varchar, dc.CartDate, 20) Data,
		d.AccountNumber Rachunek,
		d.Amount Kwota,
		d.Sender Nadawca,
		d.Title Tytuł
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
		AND dc.CartDate BETWEEN @data_od AND @data_do
		AND d.DepositStatusDictId = 4
		AND (d.AccountNumber IN ('21103015080000000550000070'))
	UNION ALL
	SELECT '', '', 'Łącznie', SUM(d.Amount), 'Liczba', CONVERT(varchar, COUNT(*))
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
			AND dc.CartDate BETWEEN @data_od AND @data_do
			AND d.DepositStatusDictId = 4
			AND (d.AccountNumber IN ('21103015080000000550000070'))

	SELECT 
		CONVERT(varchar, ag.AgencyNumber) Agencja,
		CONVERT(varchar, dc.CartDate, 20) Data,
		d.AccountNumber Rachunek,
		d.Amount Kwota,
		d.Sender Nadawca,
		d.Title Tytuł
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
		AND dc.CartDate BETWEEN @data_od AND @data_do
		AND d.DepositStatusDictId = 4
		AND (d.AccountNumber IN ('23103015080000000550001004'))
	UNION ALL
	SELECT '', '', 'Łącznie', SUM(d.Amount), 'Liczba', CONVERT(varchar, COUNT(*))
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc ON dc.id = d.DepositCartId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].CashierStand cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Agency ag ON ag.Id = cs.AgencyId
		WHERE ag.AgencyNumber = 2748
			AND dc.CartDate BETWEEN @data_od AND @data_do
			AND d.DepositStatusDictId = 4
			AND (d.AccountNumber  IN ('23103015080000000550001004'))

	--obowiązkowa ostatnia tabela z parametrami maila
	DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000), @NazwaPliku VARCHAR(100)
	SELECT @Temat = 'Miesięczny raport wpłat: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))
	SELECT @tresc = 'Raport za miesiąc: ' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + ' ' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))) + '<br>Kontrahent: UM Warszawa'
	SELECT @NazwaPliku = 'Raport_miesięczny_' + FORMAT(GETDATE()-DATEPART(dd, GETDATE()), 'MMMM', 'pl') + '_' + CONVERT(varchar, DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE())))

	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		@NazwaPliku,
		'Podatki',
		'Egzekucje',
		'Opłata skarbowa',
		'Odpisy'
		
END
GO
