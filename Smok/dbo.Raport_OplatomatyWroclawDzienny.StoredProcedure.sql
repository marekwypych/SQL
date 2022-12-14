USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyWroclawDzienny]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-07-01
-- Description:	Rapor dzienny opłatomatów ROC
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyWroclawDzienny]
	@ID INT
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

	DECLARE @NazwaSadu varchar(50), @Rachunki VARCHAR(500)

	--Sąd okręgowy Wrocław
	IF(@ID) = 1
		BEGIN
			SET @NazwaSadu = 'Sąd Okręgowy we Wrocławiu'
			SET @Rachunki = '82101016740032611398000000,45101016740032612231000000,15113010330018816198200001'
		END

	-- Sąd rejonowy Wrocław Śródmieście
	IF(@ID) = 2
		BEGIN
			SET @NazwaSadu = 'Sąd Rejonowy dla Wrocławia – Śródmieście we Wrocławiu'
			SET @Rachunki = '80101016740033331398000000,43101016740033332231000000,16113010330018816068200001'
		END

	-- Sąd rejonowy Wrocław 
	IF(@ID) = 3
		BEGIN
			SET @NazwaSadu = 'Sąd Rejonowy dla Wrocław - Krzyki we Wrocławiu'
			SET @Rachunki = '10101016740077931398000000,70101016740077932231000000,20113010330018816518200001'
		END
	
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
			WHERE d.TellerId IN (3452, 3453)
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND d.AccountNumber IN (SELECT value FROM string_split(@Rachunki, ','))
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
			WHERE d.TellerId IN (3452, 3453)
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND d.AccountNumber IN (SELECT value FROM string_split(@Rachunki, ','))
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport wpłat w opłatomatach: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = 'Sąd: ' + @NazwaSadu

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wpłaty_opłatomaty_' + CONVERT(varchar(10), @dataP),
		'Wpłaty'
END
GO
