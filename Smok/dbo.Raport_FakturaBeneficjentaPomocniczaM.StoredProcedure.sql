USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_FakturaBeneficjentaPomocniczaM]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych 
-- Create date: 2020-03-26
-- Description:	Raport miesięczny wypłat dla klienta - pomocnicza dla innego raportu
-- =============================================
CREATE PROCEDURE [dbo].[Raport_FakturaBeneficjentaPomocniczaM]
  @Klient varchar(500)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Command nvarchar(1500)
	DECLARE @DataRaportu Date = GETDATE()-DATEPART(dd, GETDATE())
	DECLARE @ORDERS VARCHAR(50) = 'ORDERS.dbo.ORDERS_' + CONVERT(varchar, DATEPART(yyyy, @DataRaportu)) + FORMAT(DATEPART(mm, @DataRaportu), '00')

	--wpłaty
	SET @Command = 'SELECT 
						CONVERT(varchar, Agencja) Agencja,
						CONVERT(varchar, Data_wpłaty, 23) Data,
						Rachunek,
						Kwota,
						Nadawca,
						Tytułem,
						Prow_Ben Prowizja
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=1 AND Prow_ben>0
					UNION ALL
					SELECT '''', '''', ''Łącznie'', SUM(Kwota), ''Liczba'', CONVERT(varchar, COUNT(*)), ROUND(SUM(Prow_Ben), 2) 
					FROM  ' + @ORDERS + '
						WHERE Klient = ''' + @Klient + ''' AND LB=1 AND Prow_ben>0'
					
	EXECUTE sp_executesql @Command

END
GO
