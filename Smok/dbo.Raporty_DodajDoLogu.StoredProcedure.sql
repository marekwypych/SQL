USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raporty_DodajDoLogu]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2019-10-17
-- Description:	Dodaje do logu wykonanie i wysłanie maila z raportem
-- =============================================
CREATE PROCEDURE [dbo].[Raporty_DodajDoLogu]
	@ID int
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO RAPORTY_LOG (IDRaportu, Data)
		VALUES(@ID, GETDATE())
END
GO
