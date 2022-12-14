USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyWplatyAllD]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-07-01
-- Description:	Zestawienie wpłat w opłatomatach Czeladzi
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyWplatyAllD]
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

	SELECT  ag.AgencyNumber [Agencja],
			ag.CustomaryName [Lokalizacja],
			ad.City + ', ' + ad.Street [Adres],
			d.Id [ID wpłaty],
			d.CardPayment [Płatność kartą],
			dc.CartDate [Data wpłaty],
			d.Amount [Kwota wpłaty],
			d.AccountNumber [Rachunek],
			d.Sender [Nadawca],
			d.Recipient [Odbiorca],
			d.Title [Tytuł],
			CASE
				WHEN pt.PaymentName IS NOT NULL THEN pt.PaymentName 
				ELSE 'Płatność kodem lub wpłata dowolna                                        '
			END [Wybrana pozycja],
			d.[Paid] Wpłacone,
			d.[Rest] [Reszta wyliczona],
			d.[DispensedRest] [Reszta wydana]
		FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[Deposit] d
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[DepositCart] dc ON d.DepositCartId = dc.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[CashierStand] cs ON dc.CashierStandId = cs.id
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Agency] ag ON ag.Id = cs.AgencyId
		JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[Address] ad ON ag.AddressID = ad.id
		LEFT JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].[PaymentTemplateAccount] pt ON d.PaymentTemplateId = pt.Id
			WHERE d.TellerId IN (select UserID FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[UserRoles] where RoleID = 10)
  			AND d.AccountNumber NOT IN (SELECT [AccountNumber] FROM [ROCDB_RAP].[Monetia_PROD].[dbo].[PayeeAccount] WHERE PayeeId = 3961)
			AND CONVERT(date, dc.CartDate) BETWEEN @dataP AND @dataK
				ORDER BY 1, 5

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport wpłat w opłatomatach ROC: ' + CONVERT(varchar(10), @dataP)
	  SELECT @tresc = ''

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Wpłaty_opłatomaty_' + CONVERT(varchar(10), @dataP),
		'Wpłaty'
END
GO
