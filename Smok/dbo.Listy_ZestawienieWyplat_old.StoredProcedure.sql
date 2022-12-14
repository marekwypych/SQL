USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Listy_ZestawienieWyplat_old]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Listy_ZestawienieWyplat_old]
	@NumerListy VARCHAR(10),
	@Konto VARCHAR(15)
AS
BEGIN

	SET NOCOUNT ON;
	select 
		CONVERT(varchar, DataRejestracji, 120) Data,
		Odbiorca, 
		Tytul, 
		FORMAT(Kwota, 'C', 'pl-PL') Kwota, 
		NumerListy
	from [dbo].[WITHDRAWAL]
	where NrRachWystawcy = @Konto and 
		NumerListy = @NumerListy and
		Status = 1
		Order by 1 DESC
END
GO
