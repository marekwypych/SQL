USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatDziennyROCD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-07-01
-- Description:	Rapor dzienny opłatomatów ROC
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatDziennyROCD]
	@TellerID INT, @NazwaOplatomatu VARCHAR(100)
AS
BEGIN

  	SET NOCOUNT ON;
	
	DECLARE @dataP date, @dataK date, @Data date
	SET @data = GETDATE()
	SET @dataK = DATEADD(day, -1, @data)
	
	IF(DATEPART(WEEKDAY, @dataK) = 1)
		SET @dataP = DATEADD(day, -2, @dataK)
	ELSE
		SET @DataP = @dataK

	SELECT 
			CONVERT(varchar, d.Id) [ID wpłaty],
			CONVERT(varchar, dc.CartDate, 120) [Data wpłaty],
			CONVERT(money, d.Amount) [Kwota wpłaty],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytuł],
			CASE
				WHEN pt.PaymentName IS NOT NULL THEN pt.PaymentName
				WHEN d.Title = 'Zakup znaków sądowych' THEN 'Zakup znaków sądowych                                        '
				ELSE 'Płatność kodem lub wpłata dowolna                                        '
			END [Wybrana pozycja]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId = @TellerID
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK
	UNION ALL
		SELECT 
			'',
			'Suma wpłat:',
			SUM(CONVERT(money, d.Amount)),
			'',
			'',
			'',
			'',
			''
	FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId = @TellerID
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK


	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport wpłat w opłatomacie: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = 'Opłatomat: ' + @NazwaOplatomatu

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wpłaty_opłatomat_' + CONVERT(varchar(10), @dataP),
		'Wpłaty'
END
GO
