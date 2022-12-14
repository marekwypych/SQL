USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_ZestawienieWyplat]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2022-03-22
-- Description:	Procedura zwraca zestawienie wypłat dla danego numeru konta oraz numeru listy
-- =============================================
CREATE PROCEDURE [dbo].[Listy_ZestawienieWyplat]
	@NumerListy VARCHAR(10),
	@Konto VARCHAR(15)
AS
BEGIN

	set nocount on
	SELECT 
		w.CreatedAt,
		w.Recipient, 
		w.Title, 
		w.Amount, 
		w.ListNo,
		w.ID,
		'4' + wad.AccountNumber AccountNumber
	INTO #WYP_ROC
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Withdrawal w
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalDefinition] wd ON wd.id = w.Definitionid
	JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[WithdrawalAccountDict] wad ON wad.id = wd.WithdrawalAccountDictId
		WHERE w.WithdrawalStatusID = 1
		AND w.ListNo is NOT NULL
		AND wad.AccountNumber = SUBSTRING(@Konto, 2, 12)
		AND w.Createdat > '2022-01-01 00:00:00'

	--uaktualnienie o korekty
	UPDATE #WYP_ROC SET ListNo = lk.NumerListy, Amount = lk.Kwota
		FROM #WYP_ROC wt JOIN [dbo].[LISTS_KOREKTY] lk ON wt.[ID] = lk.IDWyplaty
			WHERE lk.Akcja = 'update'

	INSERT INTO #WYP_ROC SELECT '1900-01-01', 'KOREKTA', ' KOREKTA', [Kwota], [NumerListy], IDWyplaty, [NrRachunkuWystawcy] FROM [WSPOLNA].[dbo].[LISTS_KOREKTY] lk WHERE lk.Akcja = 'insert'

	SELECT 
		CONVERT(varchar, DataRejestracji, 120) Data,
		Odbiorca, 
		Tytul, 
		FORMAT(Kwota, 'C', 'pl-PL') Kwota, 
		NumerListy
	FROM [dbo].[LISTS_WYPLATY]
	WHERE 
		NrRachWystawcy = @Konto AND 
		NumerListy = @NumerListy
	UNION ALL
	SELECT 		
		CONVERT(varchar, w.CreatedAt, 120) Data,
		w.Recipient Odbiorca, 
		w.Title Tytul, 
		FORMAT(w.Amount, 'C', 'pl-PL') Kwota, 
		w.ListNo NumerListy
	FROM #WYP_ROC w
	WHERE
		w.ListNo = @NumerListy AND 
		w.AccountNumber = @Konto
	ORDER BY 1


END
GO
