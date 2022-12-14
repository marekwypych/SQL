USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_WyplatyISLodz]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-01-22
-- Description:	Raport tygodniowy z wypłat dla agencji i numerów kont
-- =============================================
CREATE PROCEDURE [dbo].[Raport_WyplatyISLodz]
	@Zleceniodawca varchar(100)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Rok int, @Miesiac int
	SELECT @Rok = DATEPART(yyyy, GETDATE()-DATEPART(dd, GETDATE()))	
	SELECT @Miesiac = DATEPART(mm, GETDATE()-DATEPART(dd, GETDATE()))	
	
	SELECT  Zleceniodawca, 
			Data_wypłaty 'Data wypłat', 
			Kwota, 
			Wyplacajacy, 
			Tytułem, 
			[Prowizja Beneficjenta] Prowizja, 
			Identyfikator 'Identyfikator dokumentu'
		FROM [ORDERS].[dbo].[Wypłaty]
		where LB = 1
			and Zleceniodawca = @Zleceniodawca
		ORDER BY 2
	  
	  --obowiązkowa ostatnia tabela z parametrami maila
	  --obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Podsumowanie miesiąca ' + CONVERT(varchar, @Rok) + '-' + FORMAT(@Miesiac, '00') + ' - ' +@Zleceniodawca 
	  SELECT @tresc = 'Raport przedstawia liczbę zrealizwoanych wypłat w ' + @Zleceniodawca

	  SELECT 
		@Temat AS Temat,
		@tresc AS Tresc,
		'Raport_miesięcznyWyplaty_' + CONVERT(varchar, @Rok) + '-' + FORMAT(@Miesiac, '00')+ '-' +@Zleceniodawca,
		'RaportMiesięczny'
END
GO
