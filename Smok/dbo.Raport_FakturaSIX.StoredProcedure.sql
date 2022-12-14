USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[Raport_FakturaSIX]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2022-04-31
-- Description:	Raport miesięczny do faktury SIXa
-- =============================================
CREATE PROCEDURE [dbo].[Raport_FakturaSIX]
AS
BEGIN
	SET NOCOUNT ON;

	declare @DataOd date 
	declare @DataDo date
	declare @data date

	SET @data = GETDATE()
	set @DataOd = DATEADD(MM, -1, DATEADD(dd, -DAY(@data)+1, @data))
	set @DataDo = DATEADD(dd, -DAY(@data), @data)

		UPDATE [TERMINALE].dbo.TransakcjeECard SET Agencja = tid.numerAgencji
			FROM [TERMINALE].dbo.TransakcjeECard t JOIN [TERMINALE].dbo.tbTID tid ON t.POSId = tid.TID
				WHERE t.Agencja IS NULL

		SELECT 
			tr.TransactionType TypTransakcji,
			tr.Amount KwotaObciazeniaKarty,
			tr.NetAmount KwotaPoPotraceniuProwizji,
			tr.Amount - tr.NetAmount ProwizjaDokladna, 
			CONVERT(varchar, tr.DateTime, 20) DataTransakcji,
			CONVERT(varchar, pr.DataProcesowania, 20) DataProcesowania,
			tr.Brand TypKarty,
			tr.POSId TIDTerminala,
			tr.MerchantName,
			tr.Agencja,
			tr.CashBack,
			ISNULL(p1.CommValue, 0) Interchange, 
			ISNULL(p1.ComPercent, 0) InterchangePercent, 
			ISNULL(p2.CommValue, 0) Marza, 
			ISNULL(p2.ComPercent, 0) MarzaPercent, 
			ISNULL(p3.CommValue, 0) ProwizjaWaluta, 
			ISNULL(p3.ComPercent, 0) ProwizjaWalutaPercent
		  FROM [TERMINALE].dbo.TransakcjeECard tr
			join [TERMINALE].[dbo].[PrzelewyECard] pr ON tr.IDRaportu = pr.IDRaportu
			left join [TERMINALE].[dbo].[TransakcjeProwizje] p1 on tr.TRXID = p1.trxID and p1.CondCode=15
			left join [TERMINALE].[dbo].[TransakcjeProwizje] p2 on tr.TRXID = p2.trxID and p2.CondCode=1
			left join [TERMINALE].[dbo].[TransakcjeProwizje] p3 on tr.TRXID = p3.trxID and p3.CondCode=10
			WHERE 
				pr.DataProcesowania between @DataOd and @DataDo
				and MerchantNumber = 930266
			ORDER BY DateTime

		SELECT 
			COUNT(*) LiczbaTransakcji,
			CONVERT(money, SUM(tr.Amount)) KwotaObciazeniaKarty,
			CONVERT(money, SUM(tr.NetAmount)) KwotaPoPotraceniuProwizji,
			ROUND(CONVERT(money, SUM(tr.Amount - tr.NetAmount)), 2) ProwizjaDokladna
			FROM [TERMINALE].[dbo].TransakcjeECard tr
			join [TERMINALE].[dbo].[PrzelewyECard] pr ON tr.IDRaportu = pr.IDRaportu
			WHERE 
				pr.DataProcesowania between @DataOd and @DataDo
				and MerchantNumber = 930266

	--obowiązkowa ostatnia tabela z parametrami maila
	  DECLARE @Temat VARCHAR(100), @tresc VARCHAR(1000)
	  SELECT @temat = 'Raport do faktury SIX: ' + CONVERT(varchar, @DataOd) + ' - ' + CONVERT(varchar, @DataDo) 
	  SELECT @tresc = 'Raport do faktury SIXa'

	  SELECT 
		@Temat AS Temat, 
		@tresc AS Tresc,
		'Raport_faktura_SIX_' + CONVERT(varchar, @DataOd) + ' - ' + CONVERT(varchar, @DataDo),
		'Transakcje',
		'Podsumowanie'
		
END
GO
