USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_ZestawienieWszystkie]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2022-03-21
-- Description:	Zwraca wszystkie listy ze statusami
-- =============================================
CREATE PROCEDURE [dbo].[Listy_ZestawienieWszystkie]
AS
BEGIN
	SET NOCOUNT ON;

	--tymczasowa tabla wypłat z ROCa
	SELECT w.ListNo NumerListy, '4'+wad.AccountNumber NrRachWystawcy, w.Amount kwota, w.ID
		INTO #WYP_TEMP
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Withdrawal w
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd ON wd.id = w.Definitionid
			JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalAccountDict] wad ON wad.id = wd.WithdrawalAccountDictId
			WHERE w.WithdrawalStatusID = 1
			AND w.ListNo IS NOT NULL
			AND w.Createdat > '2022-01-01 00:00:00'

	--uaktualnienie o korekty
	UPDATE #WYP_TEMP SET NumerListy = lk.NumerListy, kwota = lk.Kwota
		FROM #WYP_TEMP wt JOIN [dbo].[LISTS_KOREKTY] lk ON wt.ID = lk.IDWyplaty
			WHERE lk.Akcja = 'update'

	INSERT INTO #WYP_TEMP SELECT [NumerListy], [NrRachunkuWystawcy], [Kwota], IDWyplaty FROM [WSPOLNA].[dbo].[LISTS_KOREKTY] lk WHERE lk.Akcja = 'insert'

	--return
		
	--tymczasowa tabela z sumami na poszczególne listy i numery kont wypłat
	SELECT [NumerListy] ,[NrRachWystawcy], SUM(kwota) [kwota]
		INTO #SUM_TEMP
		FROM (SELECT NumerListy, NrRachWystawcy, SUM(Kwota) AS kwota 
				FROM [dbo].[LISTS_WYPLATY] 
				GROUP BY NumerListy, NrRachWystawcy
			  UNION ALL
			  SELECT NumerListy ,NrRachWystawcy, SUM(kwota) kwota FROM #WYP_TEMP
					GROUP BY NumerListy, NrRachWystawcy) wplisty
			GROUP BY [NumerListy] ,[NrRachWystawcy]
	
	SELECT 
		wd.name, 
		CONVERT(varchar, l.List_date, 23) Data,
		l.list_no, 
		FORMAT(l.ammount, 'C', 'pl-PL') Kwota,
		FORMAT(ISNULL(wyp.kwota, 0), 'C', 'pl-PL') Kwota_w, 
		l.account,
		CASE 
			WHEN ROUND(l.ammount,2) = ROUND(ISNULL(wyp.kwota, 0), 2) THEN 'Zamknięta'
			WHEN ROUND(l.ammount,2) > ROUND(ISNULL(wyp.kwota, 0), 2) THEN 'Otwarta'
			WHEN ROUND(l.ammount,2) < ROUND(ISNULL(wyp.kwota, 0), 2) THEN ' Przekroczona kwota wypłat !!! '
		END Status
	FROM lists l
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalAccountDict] wad on l.ACCOUNT = '4'+wad.AccountNumber
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd on wad.id = wd.WithdrawalAccountDictId
	LEFT JOIN (SELECT [NumerListy] ,[NrRachWystawcy], [kwota] FROM #SUM_TEMP) wyp ON wyp.NumerListy = l.LIST_NO AND wyp.NrRachWystawcy = l.ACCOUNT
	WHERE wd.id in (select awd.WithdrawalDefinitionId from 
							[ROCDB_RAP].[Monetia_PROD].[dbo].[AgencyWithdrawalDict] awd
							JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] a ON a.id = awd. AgencyID WHERE a.AgencyTypeId = 1 and a.StatusAgID=2)
	ORDER BY 7, 2 DESC, 6

END
GO
