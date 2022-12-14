USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Opl_ZliczWydrukiD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2022-08-17
-- Description:	Procedura dodaje do tabeli liczbę wydruków w opłatomatach za dany dzień i zwraca info o średnioej i szacunkowym wyczerpaniu.
-- =============================================
CREATE PROCEDURE [dbo].[Opl_ZliczWydrukiD]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DlugoscRolki INT = 299
	DECLARE @Alert BIT = 0
	DECLARE @ALertPo INT = 6

	DECLARE @dataP date, @dataK date, @DataMaks date, @data date
		
	SET @dataK = DATEADD(day, -1, GETDATE())
	SELECT @DataMaks = MAX(DataDo) FROM [dbo].[OPL_WYDRUKI]
	SELECT @DataP = DATEADD(dd, 1, @DataMaks)

	--uzupełnienie tabeli z wydrukami od ostatniego uruchomienia procedury
	IF(@dataP<=@dataK)
		INSERT INTO OPL_WYDRUKI
			SELECT cs.id, 
					@dataP DataOd, 
					@dataK DataDo, 
					ISNULL([all].Conut, 0) [All], 
					ISNULL([card].Conut, 0) [Card], 
					ISNULL([stamps].Count, 0) [stamps]
				FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag 
				JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON ag.id = cs.AgencyID
				LEFT JOIN 
				(SELECT cs1.id, COUNT(*) Conut 
					FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
					JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs1 on d.CashierStandID = cs1.id
					WHERE CONVERT(date, d.Createdat) BETWEEN @dataP AND @dataK
					AND cs1.PaymentMachineID is not null
						GROUP BY cs1.ID) [all] ON [all].id = cs.id	
				LEFT JOIN (SELECT cs1.id, COUNT(*) Conut 
					FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
					JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs1 on d.CashierStandID = cs1.id
					WHERE CONVERT(date, d.Createdat) BETWEEN @dataP AND @dataK
					AND cs1.PaymentMachineID is not null
					AND d.CardPayment = 1
						GROUP BY cs1.ID) [card] ON [card].id = cs.id	
				LEFT JOIN
					(select cs1.ID, COUNT(*) Count
					from [ROCDB_RAP].[Monetia_PROD].[dbo].[RevenueStamp] rs
					JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs1 on rs.CashierStandID = cs1.id
					where cs1.PaymentMachineID is not null 
					and convert(date, rs. ActivationDate) BETWEEN @dataP AND @dataK
					group by cs1.id) [stamps] on [stamps].id = cs.id
				WHERE cs.PaymentMachineid is not null
				AND ag.StatusAgId = 2
				AND cs.Active = 1
				ORDER BY 1

	-- wyliczenie szcunków

	SELECT w.id,
		ROUND(AVG(CONVERT(float, (w.[all] * wp.DL_POTW + w.Card * wp.DL_KARTA + w.Stamps * wp.DL_ZNAK))/100), 4) Zuzycie_srednie_m
		INTO #WydrSr
		FROM [dbo].[OPL_WYDRUKI] w
		CROSS JOIN [dbo].[OPL_WYDRUKI_PARAM] wp
		WHERE w.DataOd > DATEADD(mm, -2, GETDATE())
		GROUP BY w.id
		ORDER BY 1

	SELECT ww.[CS_ID] id, ww.data_wymiany,
		SUM(CONVERT(float, (w.[all] * wp.DL_POTW + w.Card * wp.DL_KARTA + w.Stamps * wp.DL_ZNAK))/100) Zuzycie_od_wymiany
		INTO #WydrOdWymiany
		FROM opl_wydruki w
		JOIN opl_wydruki_wymiana ww on w.[id] = ww.[CS_ID] AND w.Dataod >= ww.data_wymiany
		CROSS JOIN [dbo].[OPL_WYDRUKI_PARAM] wp
		group by ww.[CS_ID], ww.data_wymiany
		order by 1, 2

	select	ws.id [ID stanowiska ROC],
			ag.AgencyNumber [Numer agencji], 
			ag.CustomaryName [Opłatomat], 
			STUFF(ad.ZipCode, 3, 0, '-') + ' ' + ad.City + ', ' + ad.Street [Adres],
			ws.Zuzycie_srednie_m [Średni dzienne zużycie],
			ww.data_wymiany [Data wymiany], 
			ww.Zuzycie_od_wymiany [Zużycie od wymiany], 
			ROUND(@DlugoscRolki - ww.Zuzycie_od_wymiany, 3) [Pozostało papieru], 
			ROUND((@DlugoscRolki - ww.Zuzycie_od_wymiany)/iif(ws.Zuzycie_srednie_m>0, ws.Zuzycie_srednie_m, 0.01), 2) [Za ile dni się skończy]
		from #WydrSr ws
		join #WydrOdWymiany ww on ws.id = ww.id
		join [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs On ww.id = cs.id
		join [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON cs.AgencyID = ag.ID
		join [ROCDB_RAP].[Monetia_PROD].[dbo].[Address] ad ON ag.AddressID = ad.ID
		order by 9

	--sprawdzenie czy jest alert
	IF(select top 1 ROUND((@DlugoscRolki - ww.Zuzycie_od_wymiany)/iif(ws.Zuzycie_srednie_m>0, ws.Zuzycie_srednie_m, 0.01), 2) [Za ile dni się skończy]
		from #WydrSr ws
		join #WydrOdWymiany ww on ws.id = ww.id
		order by 1) <= @ALertPo
	BEGIN
		SELECT @Alert = 1
	END

	drop table #WydrOdWymiany
	drop table #WydrSr

	DECLARE @temat varchar(100), @tresc varchar(100)
	SELECT @temat = 'Raport zużycia papieru w opłatomatach'
	IF(@Alert = 1) 
		SELECT  @temat = 'ALERT!!! - ' + @temat
	ELSE
		SELECT  @temat = 'JEST OK - ' + @temat
	SELECT @tresc = 'To jest prototyp raportu zużcia papieru w opłatomatach. Wymaga weryfikacji czy szacunki będą zgodne z alertami z urządzeń.' 
	
	SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wydruki_' + CONVERT(varchar, GETDATE(), 23),
		'Wydruki'
END
GO
