USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_ListaAgencji]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-12-02
-- Description:	LIsta agencji, które obsługują wypłaty w urzędach sakrbowych
-- =============================================
CREATE PROCEDURE [dbo].[Listy_ListaAgencji]
AS
BEGIN

	SET NOCOUNT ON;

	--SELECT agencja, miasto, adres FROM AGENCIES WHERE status=4 and Agencja IN (SELECT agencja FROM AGENCIES_US) ORDER BY 1
	SELECT
		ag.AgencyNumber agencja,
		adr.City,
		adr.Street
	FROM [ROCDB_RAP].[Monetia_PROD].dbo.Agency ag
	JOIN [ROCDB_RAP].[Monetia_PROD].dbo.Address adr ON ag.AddressId = adr.Id 
		WHERE ag.StatusAgId = 2
		AND ag.AgencyTypeId = 1
		ORDER BY AgencyNumber

END
GO
