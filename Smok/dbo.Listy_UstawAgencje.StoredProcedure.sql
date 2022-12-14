USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_UstawAgencje]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-12-02
-- Description:	LIsta agencji, które obsługują wypłaty w urzędach sakrbowych
-- =============================================
CREATE PROCEDURE [dbo].[Listy_UstawAgencje]
	@NumerAgencji INT 
AS
BEGIN

	SET NOCOUNT ON;

	SELECT
		ag.AgencyNumber agencja,
		adr.City,
		adr.Street
	FROM [ROCDB_RAP].[Monetia_PROD].dbo.Agency ag
	JOIN [ROCDB_RAP].[Monetia_PROD].dbo.Address adr ON ag.AddressId = adr.Id 
		WHERE AgencyNumber = @NumerAgencji

END
GO
