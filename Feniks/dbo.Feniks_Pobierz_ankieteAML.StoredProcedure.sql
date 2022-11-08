USE [FENIKS]
GO
/****** Object:  StoredProcedure [dbo].[Feniks_Pobierz_ankieteAML]    Script Date: 08.11.2022 20:24:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-04-10
-- Description:	Pobranie ankiety AML dla wskazanej wpłaty
-- =============================================
CREATE PROCEDURE [dbo].[Feniks_Pobierz_ankieteAML]
	@ORD_ID INT
AS
BEGIN

	SELECT * FROM [FENIKS].[ORDERS_AML_FORM]
		WHERE ORDER_ID = @ORD_ID

END
GO
