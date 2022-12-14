USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyProblemReszty]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-10-07
-- Description:	Zestawienie wpłat z problemem wydania reszty
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyProblemReszty]
AS
BEGIN

	DECLARE @dataP date, @dataK date, @Data date
	SET @data = GETDATE()
	SET @dataK = DATEADD(day, -1, @data)
	
	IF(DATEPART(WEEKDAY, @dataK) = 1)
		SET @dataP = DATEADD(day, -2, @dataK)
	ELSE
		SET @DataP = @dataK

	SELECT	d.ID IDWpłaty,
			d.Amount + d.Commision [Kwota wpłaty],
			d.[Paid] Wpłacone,
			d.[Rest] [Reszta wyliczona],
			d.[DispensedRest] [Reszta wydana],
			d.[Rest] - d.[DispensedRest] [Niewydana reszta],
			dsd.Name [Status wpłaty],
			ag.AgencyNumber [Agencja],
			ag.CustomaryName [Lokalizacja],
			cs.CashierStandId,
			CONVERT(datetime, dc.CartDate, 1) [Data wpłaty],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytuł],
			CASE
				WHEN pt.PaymentName IS NOT NULL THEN pt.PaymentName 
				ELSE 'Płatność kodem lub wpłata dowolna'
			END [Wybrana pozycja]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON ag.Id = cs.AgencyId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositStatusDict] dsd ON d.DepositStatusDictId = dsd.ID
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId in (select UserID FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[UserRoles] where RoleID = 10)
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK
			AND d.[Rest] <> d.[DispensedRest]
				ORDER BY 1

	SELECT	'brak' IDWpłaty,
			d.Amount + d.Commision [Kwota wpłaty],
			d.[Paid] Wpłacone,
			d.[Rest] [Reszta wyliczona],
			d.[DispensedRest] [Reszta wydana],
			d.[Rest] - d.[DispensedRest] [Niewydana reszta],
			'Brak w ROC' [Status wpłaty],
			ag.AgencyNumber [Agencja],
			ag.CustomaryName [Lokalizacja],
			cs.CashierStandId,
			CONVERT(datetime, d.CreateAt, 1) [Data wpłaty],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytuł],
			CASE
				WHEN pt.PaymentName IS NOT NULL THEN pt.PaymentName 
				ELSE 'Płatność kodem lub wpłata dowolna'
			END [Wybrana pozycja]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositDraft] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON cs.id = d.CashierStandId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON ag.Id = cs.AgencyId
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId in (select UserID FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[UserRoles]	where RoleID = 10)
			AND CONVERT(date, d.CreateAt) BETWEEN @dataP AND @dataK
			AND d.[Rest] <> d.[DispensedRest]
				ORDER BY 1

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport niewydanej reszty: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = ''

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'opłatomaty_problem_reszty_' + CONVERT(varchar(10), @dataP),
		'Wpłaty zarejestrowane',
		'Brak w systemie'

END
GO
