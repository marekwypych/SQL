USE [FENIKS]
GO
/****** Object:  StoredProcedure [dbo].[Feniks_Szukaj_Wplaty]    Script Date: 08.11.2022 20:24:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-04-10
-- Description:	Wysukanie wpłat w archwiwach feniksa
-- =============================================
CREATE PROCEDURE [dbo].[Feniks_Szukaj_Wplaty]
	@DataOd date, @DataDo date, @Nrb varchar(26), @Status int, @Nadawca varchar(120), @Odbiorca varchar(120), @Agencja int, @KwotaOd money, @KwotaDo money
AS
BEGIN

	DECLARE @Archiwum VARCHAR(15)
	DECLARE @Command NVARCHAR(max) = ''

	DECLARE ARCHIWA CURSOR FOR 
		SELECT Baza FROM ORDERS_ARCH
			WHERE DataOd 
				BETWEEN	ISNULL((SELECT TOP 1 DataOd FROM ORDERS_ARCH WHERE DataOd <= @DataOD ORDER BY DataOd DESC), '2000-01-01')
				AND	(SELECT TOP 1 DataOd FROM ORDERS_ARCH WHERE DataOd <= @DataDo ORDER BY DataOd DESC)
	OPEN ARCHIWA
	FETCH NEXT FROM ARCHIWA INTO @Archiwum
	WHILE @@FETCH_STATUS = 0 
		BEGIN
			DECLARE @NRB_SQL VARCHAR(40)
			IF LEN(@Nrb) = 26
				SET @NRB_SQL = ' = ''' + @Nrb + ''''
			ELSE
				SET @NRB_SQL = ' like ''%' + @Nrb + '%'''
			
			SET @Command = @Command +
				 'SELECT AGNC_DISP_NAME, ORD_SUBM_DATE_TIME, ORD_PAYER_NAME, ORD_BEN_NAME, ORD_BEN_NRB, ORD_AMOUNT, ORD_ID, ''' + @Archiwum + ''' BAZA, [USER_FIRST_NAME] + '' '' + [USER_FAMILY_NAME] +'' ('' + [USER_login] +'')''		 ORD_KASJER
				  FROM [' + @Archiwum + '].[dbo].[ORDERS] o
				  LEFT JOIN [FENIKS].[USERS] u ON o.USER_ID = u.USER_ID
				  where ORD_SUBM_DATE_TIME Between ''' + CONVERT(varchar, @DataOd) + ''' AND ''' + CONVERT(varchar, @DataDo) + '''
					and ORD_BEN_NRB ' + @NRB_SQL + '
					and ORD_STATUS = ' + CONVERT(varchar, @Status) + '
					AND ORD_PAYER_NAME LIKE ''%' + @Nadawca + '%''
					AND ORD_BEN_NAME  LIKE ''%' + @Odbiorca + '%''
					AND AGNC_DISP_NAME BETWEEN ' + CONVERT(varchar, @Agencja) + ' AND ' + IIF(@agencja=0, '999999', CONVERT(varchar, @Agencja)) + '
					AND ORD_AMOUNT BETWEEN ' + CONVERT(varchar, @KwotaOd) + ' AND ' + CONVERT(varchar, @KwotaDo) + '
				UNION ALL '
			FETCH NEXT FROM ARCHIWA INTO @Archiwum
		END
	CLOSE ARCHIWA
	DEALLOCATE ARCHIWA
	SET @Command = LEFT(@command, LEN(@command) - IIF(LEN(@command)>0, 10, 0))
	EXECUTE sp_executesql @Command
	
END
GO
