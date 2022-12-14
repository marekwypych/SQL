USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_OplatomatyWersjaSoftu]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2022-05-27
-- Description:	Rapor dzienny opłatomatów ROC
-- =============================================
CREATE PROCEDURE [dbo].[Raport_OplatomatyWersjaSoftu]
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ag.AgencyNumber Agencja, ag.CustomaryName NazwaZwyczajowa, ad.City + ', ' + ad.Street Adres, ApiVersion, NotifierVersion 
		FROM [ROCDB_RAP].[Monetia_PROD].dbo.DeviceState ds
		JOIN [ROCDB_RAP].[Monetia_PROD].dbo.CashierStand cs ON ds.PaymentMachineId = cs.PaymentMachineId
		JOIN [ROCDB_RAP].[Monetia_PROD].dbo.Agency ag ON cs.AgencyId = ag.Id
		JOIN [ROCDB_RAP].[Monetia_PROD].dbo.Address ad ON ag.AddressId = ad.Id
		WHERE ag.StatusAgId = 2
		AND cs.Active = 1
		ORDER BY 4 DESC, 5 DESC, 1	

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Opłatomaty - wersja oprogramowania: ' + CONVERT(varchar(10), GETDATE(), 23)
	  SELECT @tresc = 'Raport wersji oprogramowania w opłatomatach.'

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'opłatomaty_soft_' + CONVERT(varchar(10), GETDATE(), 23),
		'Opłatomaty'
END
GO
