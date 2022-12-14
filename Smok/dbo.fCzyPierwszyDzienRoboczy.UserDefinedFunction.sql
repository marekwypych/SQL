USE [WSPOLNA]
GO
/****** Object:  UserDefinedFunction [dbo].[fCzyPierwszyDzienRoboczy]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 16.10.2019
-- Description:	Funkcja zwraca czy podana data jest pierwszym pracującym dniem miesiąca.
-- =============================================
CREATE FUNCTION [dbo].[fCzyPierwszyDzienRoboczy]
(	
	@data date
)
RETURNS bit
AS
BEGIN
	--zmienne techniczne
	DECLARE @i INT
	DECLARE @Test BIT
	DECLARE @DzienMiesiaca INT
	DECLARE @TestData date

		SET @i = 1
		SET @DzienMiesiaca = DATEPART(day, @data)
		SET @Test = IIF(DATEPART(WEEKDAY, @data) IN(1,7), 0, IIF(EXISTS(SELECT 1 FROM SWIETA WHERE Data=@data), 0, 1))

		WHILE @i < @DzienMiesiaca
			BEGIN
				SET @TestData = DATEADD(day, -@i, @data)
				IF (DATEPART(WEEKDAY, @TestData) NOT IN(1,7) AND NOT EXISTS(SELECT 1 FROM SWIETA WHERE Data=@TestData))
					BEGIN
						SET @Test = 0
						BREAK
					END
				SET @i = @i + 1
			END
 
		RETURN @Test
	END
GO
