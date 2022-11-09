USE [WSPOLNA]
GO

/****** Object:  UserDefinedFunction [dbo].[CharCount]    Script Date: 09.11.2022 15:12:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marek Wypych
-- Create date: 2022-01-12
-- Description:	Funkcja zwraca liczbę znaków w stringu w kolejności występowania
-- =============================================
CREATE   FUNCTION [dbo].[CharCount](@Tekst VARCHAR(max))
RETURNS VARCHAR(max)
WITH EXECUTE AS CALLER
AS
BEGIN

	DECLARE @TekstWyjscie VARCHAR(500) = ''
	DECLARE @Licznik INT = 1
	DECLARE @Znak CHAR(1)
	DECLARE @LiczbaZnakow INT
	WHILE @Licznik <= LEN(@Tekst)
	BEGIN
		SET @Znak = SUBSTRING(@tekst, @Licznik, 1)
		SET @LiczbaZnakow =  LEN(@Tekst) - LEN(REPLACE(@Tekst, @Znak, ''))
		IF(LEN(@TekstWyjscie) - LEN(REPLACE(@TekstWyjscie, CONVERT(VARCHAR, @LiczbaZnakow) + @Znak, '')) = 0)
			BEGIN
				SELECT @TekstWyjscie = @TekstWyjscie + CONVERT(VARCHAR, @LiczbaZnakow) + @Znak
			END
		SET @Licznik = @Licznik + 1
	END
	RETURN @TekstWyjscie

END

GO

