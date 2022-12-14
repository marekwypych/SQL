USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyBarlinekD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-07-01
-- Description:	Rapor dzienny opłatomatów ROC
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyBarlinekD]
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

	--wpłaty
	SELECT 
			ag.AgencyNumber [Numer opłatomatu],
			d.Id [ID wpłaty],
			dc.CartDate [Data wpłaty],
			d.Amount [Kwota wpłaty],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytuł]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON dc.CashierStandID = cs.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON cs.AgencyID = ag.Id
		WHERE ag.Agentid = 830
		AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK
			ORDER BY 1
	
	--wypłaty
	SELECT ag.AgencyNumber [Numer opłatomatu],
			adr.City [Miejscowość],
			adr.Street [Adres]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Address] adr ON ag.AddressId = adr.Id
		WHERE ag.Agentid = 830
		AND ag.StatusAgId = 2
		ORDER BY 1

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport wpłat w opłatomatach: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = 'Opłatomat: Opłatomaty GBS Barlinek'

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wpłaty_Barlinek_' + CONVERT(varchar(10), @dataP),
		'Wpłaty',
		'Opłatomaty'
END
GO
