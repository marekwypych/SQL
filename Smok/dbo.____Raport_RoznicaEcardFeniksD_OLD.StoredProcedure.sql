USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[____Raport_RoznicaEcardFeniksD_OLD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2019-10-19
-- Description:	Raport zwraca różnicę pomiędzy x a y do rozliczenia dnia dla płatności bezgotówkowych
-- =============================================
CREATE PROCEDURE [dbo].[____Raport_RoznicaEcardFeniksD_OLD]
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @data datetime 
	SET @data = GETDATE()
	--SET @data = '2021-08-16'

	DECLARE @Poczatek INT = -3 -- (SELECT [RaportIleDniWstecz] FROM [TERMINALE].[dbo].[Parametry]) 

	DECLARE @DataStart date = DATEADD(day, @Poczatek, @data)
	DECLARE @DataKoniec date = DATEADD(day, -1, @data)

	DECLARE @DataStartE date = DATEADD(day, 1, @DataStart)
	DECLARE @DataKoniecE date = DATEADD(day, 1, @DataKoniec)

	SELECT tid.numerAgencji, CONVERT(Date, DateTime) AS Data, SUM(tr.Amount) AS Kwota 
		INTO #te
		FROM TERMINALE.dbo.TransakcjeECard tr
		inner join TERMINALE.dbo.PrzelewyECard pe ON pe.IDRaportu = tr.IDRaportu
		left join TERMINALE.dbo.tbTID tid ON tid.TID = tr.POSId
		WHERE CONVERT(Date, pe.DataPrzelewu) BETWEEN @DataStartE AND @DataKoniecE
		and TransactionType not like '%obciążenie%'
		GROUP BY tid.numerAgencji, CONVERT(Date, DateTime)

	--wypłaty cahsback
	select a.AgencyNumber NumerAgencji, CONVERT(date, w.CreatedAt) Data, SUM(amount) Kwota
		INTO #tf1
		from [ROCDB_RAP].[Monetia_PROD].[dbo].[Withdrawal] w
		join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on ts.Id = w.TellerSessionId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on a.Id = ts.AgencyId
			where DefinitionID = 321
			and CONVERT(date, w.CreatedAt) BETWEEN @DataStart AND @DataKoniec
			group by a.AgencyNumber, CONVERT(date, w.CreatedAt)

	--transakcje z ROCa
	INSERT INTO #tf1
		select  a.AgencyNumber Agencja,
			CONVERT(date, dc.CartDate) Data,
			CONVERT(money, SUM(isnull(Amount, 0) + isnull(d.Commision, 0) + isnull(CardCommision, 0))) Kwota
		from [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		join [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc on dc.id = d.DepositCartId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on ts.Id = dc.TellerSessionId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on a.Id = ts.AgencyId
			where CONVERT(date, dc.CartDate) BETWEEN @DataStart AND @DataKoniec
			and d.DepositStatusDictId <> 2
			and d.CardPayment = 1
			group by a.AgencyNumber, CONVERT(date, dc.CartDate)

	-- transakcje opłatomatów
	INSERT INTO #tf1
		SELECT Agencja, CONVERT(date, Data) Data, SUM(DoZaplaty) Kwota
			FROM [WSPOLNA].[dbo].[OPL_TRX] t
			JOIN [WSPOLNA].[dbo].[OPL_MASZYNY] m ON m.ID = t.Maszyna
				where CONVERT(Date, Data) BETWEEN @DataStart AND @DataKoniec
					and SposobWyplaty = 'terminal'
					and Status = 'paid'
				group by Agencja,  CONVERT(date, Data)

	SELECT NumerAgencji, Data,  Sum(kwota) AS Kwota 
		INTO #tf
			FROM #tf1
				GROUP BY NumerAgencji, Data

	--transakcje SIX
	SELECT *, e.Kwota-f.Kwota AS roznica FROM 
		#te e left join #tf f ON e.numerAgencji = f.NumerAgencji AND f.Data = e.Data
		WHERE (e.Kwota-f.Kwota)<>0 OR f.Kwota is null
		ORDER BY e.Data, e.numerAgencji
	
	--transakcje ROC
	SELECT * FROM #tf f
		WHERE NOT EXISTS (select 1 from #te e where e.numerAgencji = f.NumerAgencji and e.Data = f.Data)

	DROP TABLE #te
	DROP TABLE #tf

	--brakujące TIDY
	SELECT DISTINCT POSId
		FROM TERMINALE.dbo.TransakcjeECard tr
		WHERE PosID NOT IN (SELECT Tid FROM TERMINALE.dbo.tbTID WHERE TID IS NOT NULL)
		AND PosID<>0
		AND TransactionType not like '%obciążenie%'

	--Przelewy eCard
	SELECT * FROM TERMINALE.dbo.PrzelewyECard pe	
		WHERE CONVERT(Date, pe.DataPrzelewu) BETWEEN @DataStartE AND @DataKoniecE

	--transakceje SIX i ecard
	SELECT tid.numerAgencji, tr.POSId, tr.DateTime, tr.Amount AS Kwota, tr.Brand, tr.TransactionType
		FROM TERMINALE.dbo.TransakcjeECard tr
		inner join TERMINALE.dbo.PrzelewyECard pe ON pe.IDRaportu = tr.IDRaportu
		left join TERMINALE.dbo.tbTID tid ON tid.TID = tr.POSId
		WHERE CONVERT(Date, pe.DataPrzelewu) BETWEEN @DataStartE AND @DataKoniecE
		and POSId not in(0)
		ORDER BY tid.numerAgencji, CONVERT(Date, DateTime)

	--wpłaty bezgotówkowe ROC
	select  a.AgencyNumber Agencja,
			CONVERT(datetime, dc.CartDate) Data,
			d.Sender Nadawca,
			d.Recipient Odbiorca,
			CONVERT(money, isnull(Amount, 0) + isnull(d.Commision, 0) + isnull(CardCommision, 0)) Kwota,
			dsd.Name Status
		from [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		join [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc on dc.id = d.DepositCartId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on ts.Id = dc.TellerSessionId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on a.Id = ts.AgencyId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].DepositStatusDict dsd on dsd.Id = d.DepositStatusDictId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].[TerminalTypeDict] ttd on ttd.Id = d.TerminalTypeDictID
			where CONVERT(date, dc.CartDate) BETWEEN @DataStart AND @DataKoniec
			and d.CardPayment = 1
				ORDER BY 2

	-- suma transakcji per uzytkownik w danej agencji
	select  CONVERT(date, dc.CartDate) Data,
			a.AgencyNumber Agencja, 
			u.Login Użytkownik, 
			SUM(isnull(Amount, 0) + isnull(d.Commision, 0) + isnull(CardCommision, 0)) SumaBezgotowkowych
		from [ROCDB_RAP].[Monetia_PROD].[dbo].Deposit d
		join [ROCDB_RAP].[Monetia_PROD].[dbo].DepositCart dc on dc.id = d.DepositCartId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].TellerSession ts on ts.Id = dc.TellerSessionId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a on a.Id = ts.AgencyId
		join [ROCDB_RAP].[Monetia_PROD].[dbo].Users u on u.Id = d.TellerId
			where CONVERT(date, dc.CartDate) BETWEEN @DataStart AND @DataKoniec
			and d.DepositStatusDictId in(1,3,4,5)
			and d.CardPayment = 1
				group by CONVERT(date, dc.CartDate), a.AgencyNumber, u.Login
					order by 1, 2

	 --obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport różnic Six<->ROC: ' + CONVERT(varchar(10), @DataStart)
	  SELECT @tresc = ''

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Raport_różnic_SIX-ROC_' + CONVERT(varchar(10), @DataStart),
		'eCard_six brak ROC',
		'ROC brak eCard_six',
		'Brak TID',
		'Przelewy eCard_six',
		'Transakcje eCard_six',
		'Transakcje ROC',
		'Transakcje per user'
END
GO
