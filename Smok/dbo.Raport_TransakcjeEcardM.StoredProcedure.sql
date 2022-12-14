USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_TransakcjeEcardM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2020-03-17
-- Description:	Raport miesięczny płatnośći kartami eCard wg wytycznych sprzedaży
-- =============================================
CREATE PROCEDURE [dbo].[Raport_TransakcjeEcardM]
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE [Terminale].[dbo].TransakcjeECard SET Agencja = tid.numerAgencji
		FROM [Terminale].[dbo].TransakcjeECard t JOIN [Terminale].[dbo].tbTID tid ON t.POSId = tid.TID
			WHERE t.Agencja IS NULL

	SET LANGUAGE polish
	DECLARE @Data date, @Licznik INT, @OstatniMiesiac INT, @Rok CHAR(4), @Miesiac VARCHAR(50), @DoSql1 VARCHAR(1500), @DoSql2 VARCHAR(1500), @command nvarchar(4000), @SumaK VARCHAR(1500), @SumaL VARCHAR(1500), @Kwoty VARCHAR(1500), @Liczby VARCHAR(1500), @MSumaK VARCHAR(1500), @MSumaL VARCHAR(1500)

	SELECT @Data = GETDATE()
	SELECT @DoSql1 = ''
	SELECT @DoSql2 = ''
	SELECT @SumaK = ''
	SELECT @SumaL = ''
	SELECT @MSumaK = ''
	SELECT @MSumaL = ''
	SELECT @Kwoty = ''
	SELECT @Liczby = ''
	SELECT @Licznik = 1
	SELECT @OstatniMiesiac = DATEPART(mm, DATEADD(dd, -DAY(@Data), @Data))
	SELECT @Rok = DATEPART(yyyy, DATEADD(dd, -DAY(@Data), @Data))

	WHILE @Licznik <= @OstatniMiesiac
	BEGIN

		SELECT @Miesiac = FORMAT(CONVERT(date, @Rok + '-' + FORMAT(@Licznik, '00') + '-01'), 'MMMM')
		SELECT @DoSql1 = @DoSql1 + '[' + @Miesiac + '_kwota],' 
		SELECT @DoSql2 = @DoSql2 + '[' + @Miesiac + '_liczba],'
		SELECT @SumaK = @SumaK + 'ISNULL(' + @Miesiac + '_kwota, 0)+' 
		SELECT @SumaL = @SumaL + 'ISNULL(' + @Miesiac + '_liczba, 0)+'
		SELECT @MSumaK = @MSumaK + 'SUM(' + @Miesiac + '_kwota),' 
		SELECT @MSumaL = @MSumaL + 'SUM(' + @Miesiac + '_liczba),'
		SELECT @Kwoty = @Kwoty + 'ISNULL(' + @Miesiac + '_kwota, 0) ' + @Miesiac + '_kwota,'
		SELECT @Liczby = @Liczby + 'CONVERT(int, ISNULL(' + @Miesiac + '_liczba, 0)) ' + @Miesiac + '_liczba,'
		SELECT @Licznik = @Licznik + 1
	END
	SELECT @DoSql1 = @DoSql1 + LEFT(@DoSql2, LEN(@DoSql2)-1)
	SELECT @SumaK = LEFT(@SumaK, LEN(@SumaK)-1) + ' suma_kwota'
	SELECT @SumaL = 'CONVERT(int, ' + LEFT(@SumaL, LEN(@SumaL)-1) + ') suma_liczba'
	select @Kwoty = LEFT(@Kwoty, LEN(@Kwoty)-1)
	select @Liczby = LEFT(@Liczby, LEN(@Liczby)-1)

	SET @command = 	'SELECT Agencja, PosID, Brand,' + @Kwoty + ',' + @Liczby + ',' + @SumaK + ',' + @SumaL + ' into ##t from (
						SELECT Agencja, PosID, Brand, FORMAT(datetime, ''MMMM'') + ''_kwota'' AS Miesiac, SUM(Amount) AS Wartosc
							FROM [Terminale].[dbo].[TransakcjeECard] WHERE YEAR(DateTime) = ' + @Rok + ' AND MONTH(DateTime) <= ' + CONVERT(nvarchar, @OstatniMiesiac) + '
							GROUP BY Agencja, PosID, Brand, FORMAT(datetime, ''MMMM''), MONTH(datetime)
						UNION ALL
						SELECT Agencja, PosID, Brand, FORMAT(datetime, ''MMMM'') + ''_liczba'' AS Miesiac, COUNT(*) AS Wartosc
							FROM [Terminale].[dbo].[TransakcjeECard]  WHERE YEAR(DateTime) = ' + @Rok + ' AND MONTH(DateTime) <= ' + CONVERT(nvarchar, @OstatniMiesiac) + '
							GROUP BY Agencja, PosID, Brand, FORMAT(datetime, ''MMMM''), MONTH(datetime)
						  ) AS Transakcje
						  PIVOT(SUM(Wartosc) FOR Miesiac IN(' + @DoSql1 + ')) AS ss
						  WHERE Brand <>''0'''

	exec sp_executesql @command 

	--posortowanie przy pomocy indeksu klastrowego :)
	CREATE CLUSTERED INDEX i1 ON ##t (Agencja ASC, PosID ASC, Brand DESC);

	SET @command = 'SELECT ag.City, ag.Street, ag.RegionID, t.Agencja, t.PosID, t.Brand, '+ @DoSql1 +', suma_kwota, suma_liczba 
						FROM ##t t 
						LEFT JOIN (SELECT a.AgencyNumber, adr.City, adr.Street, a.RegionID 
									FROM [ROCDB_RAP].[Monetia_PROD].[dbo].Agency a
									JOIN [ROCDB_RAP].[Monetia_PROD].[dbo].Address adr on a.AddressId = adr.Id) ag ON ag.AgencyNumber = t.Agencja
						UNION ALL	
						SELECT '''', '''', 0, 0, 0, ''Łącznie'',' + @MSumaK + @MSumaL + 'SUM(suma_kwota), SUM(suma_liczba) FROM ##t'

	exec sp_executesql @command 

	DROP TABLE ##t

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport płatności kartami: ' + FORMAT(CONVERT(date, @Rok + '-' + FORMAT(@Licznik-1, '00') + '-01'), 'MMMM') + ' ' + @Rok
	  SELECT @tresc = ''

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Raport_płatności_kartami_' + FORMAT(CONVERT(date, @Rok + '-' + FORMAT(@Licznik-1, '00') + '-01'), 'MMMM') + '_' + @Rok,
		'Transakcje eCard'
		
END
GO
