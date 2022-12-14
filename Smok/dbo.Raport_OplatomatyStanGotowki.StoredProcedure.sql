USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyStanGotowki]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-04-02
-- Description:	Zestawienie stanów gotówki w opłatomatach  
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyStanGotowki]
AS
BEGIN

  	SET NOCOUNT ON;

	SELECT ag.AgencyNumber, ag.CustomaryName, cs.CashierStandId,
	(dys.Coin_01 * 0.01 +
	dys.Coin_02 * 0.02 +
	dys.Coin_05 * 0.05 +
	dys.Coin_10 * 0.1 +
	dys.Coin_20 * 0.2 +
	dys.Coin_50 * 0.5 +
	dys.Coin_1 * 1 +
	dys.Coin_2 * 2 +
	dys.Coin_5 * 5 +
	dys.Note_10 * 10 +
	dys.Note_20 * 20 + 
	dys.Note_50 * 50 +
	dys.Note_100 * 100 +
	dys.Note_200 * 200) dyspenser, 
	(akc.Coin_01 * 0.01 +
	akc.Coin_02 * 0.02 +
	akc.Coin_05 * 0.05 +
	akc.Coin_10 * 0.1 +
	akc.Coin_20 * 0.2 +
	akc.Coin_50 * 0.5 +
	akc.Coin_1 * 1 +
	akc.Coin_2 * 2 +
	akc.Coin_5 * 5 +
	akc.Note_10 * 10 +
	akc.Note_20 * 20 + 
	akc.Note_50 * 50 +
	akc.Note_100 * 100 +
	akc.Note_200 * 200) Akceptor,
	(dys.Coin_01 * 0.01 +
	dys.Coin_02 * 0.02 +
	dys.Coin_05 * 0.05 +
	dys.Coin_10 * 0.1 +
	dys.Coin_20 * 0.2 +
	dys.Coin_50 * 0.5 +
	dys.Coin_1 * 1 +
	dys.Coin_2 * 2 +
	dys.Coin_5 * 5 +
	dys.Note_10 * 10 +
	dys.Note_20 * 20 + 
	dys.Note_50 * 50 +
	dys.Note_100 * 100 +
	dys.Note_200 * 200) + 
	(akc.Coin_01 * 0.01 +
	akc.Coin_02 * 0.02 +
	akc.Coin_05 * 0.05 +
	akc.Coin_10 * 0.1 +
	akc.Coin_20 * 0.2 +
	akc.Coin_50 * 0.5 +
	akc.Coin_1 * 1 +
	akc.Coin_2 * 2 +
	akc.Coin_5 * 5 +
	akc.Note_10 * 10 +
	akc.Note_20 * 20 + 
	akc.Note_50 * 50 +
	akc.Note_100 * 100 +
	akc.Note_200 * 200) Stan,
	dys.Coin_01 [dys_1grosz],
	dys.Coin_05 [dys_5groszy],
	dys.Coin_1 [dys_1zloty],
	dys.Coin_2 [dys_2zlote],
	dys.Coin_5 [dys_5zlotych],
	dys.Note_10 [dys_10zlotych],
	dys.Note_20 [dys_20zlotych],
	dys.Note_50 [dys_50zlotych],
    akc.*
	  INTO #StanyGotowki
	  FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentMachine] pm
	  JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON cs.PaymentMachineId = pm.Id
	  JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON ag.Id = cs.AgencyId
	  JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DispenserState] dys ON dys.PaymentMachineId = pm.Id
	  JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[AcceptorState] akc ON akc.PaymentMachineId = pm.Id
	  	where cs.Active = 1
		and pm.CashPaymentAvailable = 1

	--alert dyspenserów
	select 
		AgencyNumber Agencja,
		CustomaryName NazwaOplatomatu,
		[dys_1grosz],
		[dys_5groszy],
		[dys_1zloty],
		[dys_2zlote],
		[dys_5zlotych],
		[dys_10zlotych],
		[dys_20zlotych],
		[dys_50zlotych]
		INTO #AlertyDysp
		FROM #StanyGotowki
		WHERE [dys_1grosz] < 100 OR
				[dys_5groszy] < 400 OR
				[dys_1zloty] < 200 OR
				[dys_20zlotych] < 70 OR
				[dys_50zlotych] < 70 OR
				([dys_5zlotych] < 100 AND PaymentMachineId in (2, 3, 4)) OR
				([dys_2zlote] < 150 AND PaymentMachineId not in (2, 3, 4)) OR
				([dys_10zlotych] < 100 AND PaymentMachineId not in (2, 3, 4, 6, 43, 44))

	--alert akceptorów
	SELECT AgencyNumber Agencja,
	 	   CustomaryName NazwaOplatomatu,
		   Akceptor,
		   (Note_10 + Note_20 + Note_50 + Note_100 + Note_200 + Note_500) liczba_banknotow 
		INTO #AlertyAkcep
		FROM #StanyGotowki
		where
			((Note_10 + Note_20 + Note_50 + Note_100 + Note_200 + Note_500) > 900) OR
			Akceptor > 50000

	DECLARE @JestAlert INT
	IF EXISTS(select 1 from #AlertyDysp) OR EXISTS(SELECT 1 FROM #AlertyAkcep)
		SELECT @JestAlert = 1
	ELSE
		SELECT @JestAlert = 0

	--alerty dyspenserów
	SELECT * FROM #AlertyDysp

	--alerty akceptorów
	SELECT * FROM #AlertyAkcep

	--stany maszyn
	SELECT PaymentMachineId ID, ad.City + ', ' + ad.Street Adres, sd.* FROM 
		#StanyGotowki sd
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON ag.AgencyNumber = sd.AgencyNumber
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Address] ad ON ag.AddressId = ad.id

	--stan gotówki łącznie
	SELECT 'ROC' TypOplatomatu, 
			SUM(dyspenser) Suma_dyspensery,
			SUM(akceptor) Suma_akceptory,
			SUM(Stan) Suma_gotowki
  	    FROM #StanyGotowki

	--lista opłatomatów
	SELECT pm.ID [ID opłatomatu],
			ag.AgencyNumber, 
			ag.CustomaryName, 
			ad.City, 
			ad.Street, 
			pm.CashPaymentAvailable [Gotówkowy],
			pm.MaxPaymentAmount [Maksymalna wpłata],
			pm.ScanQRCodeAvailable QRKody,
			pm.StampTransactionAvailable [Znaki sądowe]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON cs.AgencyId = ag.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Address] ad ON ag.AddressId = ad.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentMachine] pm ON cs.PaymentMachineId = pm.Id
		WHERE cs.PaymentMachineid is not null
		AND cs.Active = 1
		ORDER BY 1

		DECLARE @TProgi TABLE (Nominal varchar(50), Prog int)
		INSERT INTO @TProgi
			VALUES
				('[dys_1grosz]',  100),
				('[dys_5groszy]', 400),
				('[dys_1zloty]', 200),
				('[dys_20zlotych]', 70),
				('[dys_50zlotych]', 70),
				('[dys_5zlotych]', 100),
				('[dys_2zlote]', 150),
				('[dys_10zlotych]', 100),
				('Akceptor wartość', 50000),
				('Akceptor liczba', 900)

	-- zwrot informacji o progach alarmowych
	  SELECT * FROM @TProgi

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  
	  IF @JestAlert = 1
	  BEGIN
		SELECT @tresc = 'UWAGA JEST ALERT W RAPORCIE!'
		SELECT @temat = 'WYMAGA UWAGI! - Raport gotówki w opłatomatach: ' + CONVERT(varchar(10), GETDATE(), 23)
  	  END
	  ELSE
	  BEGIN
		SELECT @tresc = 'Żaden opłatomat nie wymaga uwagi'
		SELECT @temat = 'Raport gotówki w opłatomatach: ' + CONVERT(varchar(10), GETDATE(), 23)
	  END
	  
	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Gotowka_oplatomaty_' + CONVERT(varchar(10), GETDATE(), 23),
		'Alerty dyspensery',
		'Alerty akceptory',
		'Stan maszyn',
		'Stan gotówki',
		'Lista opłatomatów',
		'Progi alarmowe'
END
GO
