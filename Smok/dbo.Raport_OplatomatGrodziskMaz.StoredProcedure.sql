USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatGrodziskMaz]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-07-01
-- Description:	Rapor dzienny opłatomatów ROC
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatGrodziskMaz]
AS
BEGIN

  	SET NOCOUNT ON;
	
	DECLARE @dataP date, @dataK date, @Data date, @TellerID int
	SET @data = GETDATE()
	SET @dataK = DATEADD(day, -1, @data)
	SET @TellerID = 3056  --id usera dla grodziska
	
	IF(DATEPART(WEEKDAY, @dataK) = 1)
		SET @dataP = DATEADD(day, -2, @dataK)
	ELSE
		SET @DataP = @dataK

	SELECT 
			CONVERT(date,dc.CartDate) [DataWplaty],
			d.Amount [Kwota],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytul],
			ISNULL(d.Title_Part2, '') [Kod],
			ISNULL(TRIM(d.Title_Part3), '') + ';' + ISNULL(TRIM(d.Title_Part4), '') + ';' + ISNULL(TRIM(d.Title_Part5), '') [DaneDodatkowe]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId = @TellerID
			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK
			ORDER BY 1

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport wpłat w opłatomacie: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = 'Opłatomat: Grodzisk Mazowiecki' 

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wpłaty_opłatomat_' + CONVERT(varchar(10), @dataP),
		'Wpłaty'
END
GO
