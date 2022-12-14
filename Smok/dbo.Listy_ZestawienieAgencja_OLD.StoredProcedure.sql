USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_ZestawienieAgencja_OLD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-12-02
-- Description:	Zwraca listy przypisane dla danej agencji ze statusami
-- =============================================
CREATE PROCEDURE [dbo].[Listy_ZestawienieAgencja_OLD]
	@NumerAgencji INT
AS
BEGIN
	SET NOCOUNT ON;

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
	LEFT JOIN (select NumerListy, NrRachWystawcy, SUM(Kwota) AS kwota from [dbo].[WITHDRAWAL] WHERE Status = 1 GROUP BY NumerListy, NrRachWystawcy) wyp ON wyp.NumerListy = l.LIST_NO AND wyp.NrRachWystawcy = l.ACCOUNT
	WHERE wd.id in (select awd.WithdrawalDefinitionId from 
							[ROCDB_RAP].[Monetia_PROD].[dbo].[AgencyWithdrawalDict] awd
							JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] a ON a.id = awd. AgencyID
							WHERE a.AgencyNumber = @NumerAgencji)
	ORDER BY 7, 2 DESC

END
GO
