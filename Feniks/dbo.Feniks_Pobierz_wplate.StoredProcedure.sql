USE [FENIKS]
GO
/****** Object:  StoredProcedure [dbo].[Feniks_Pobierz_wplate]    Script Date: 08.11.2022 20:24:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-04-10
-- Description:	Wysukanie wpłat w archwiwach feniksa
-- =============================================
CREATE PROCEDURE [dbo].[Feniks_Pobierz_wplate]
	@ORD_ID INT, @DBNAME NVARCHAR(50)
AS
BEGIN

	DECLARE @Command NVARCHAR(max) = ''

	SET @Command = 
		'select 
			o.ORD_BEN_NRB, o.ORD_AMOUNT, ORD_INTEREST_AMOUNT, o.ORD_PAYER_NAME, o.ORD_BEN_NAME, o.ORD_DESCR, o.ORD_SUBM_DATE_TIME, o.ORD_STATUS, o.ORD_TYPE, o.ORD_REQUESTED_BOOK_DATE, o.ORD_BOOKED_DATE, ISNULL(o.ORD_AML_STATUS, 4), o.ORD_CASHFLOW_TYPE, o.ORD_SERVICE_TYPE,
			o.ORD_PAY_COMM_VAL, o.ORD_BEN_COMM_VAL, o.ORD_PAY_COMM_VAL + o.ORD_BEN_COMM_VAL COMM_ALL, ''dodać profil prowizyjny'' COMM_PROFILE, ISNULL(od.POS_COMM_ID, 0) POS_COMM_ID, ISNULL(od.POS_COMM_AMOUNT, 0) POS_COMM_AMOUNT,
			o.ORD_AGN_REMUN, o.ORD_PROP_REMUN, 
			ISNULL(aml.SUSPICION_REASONS, ''[]'') SUSPICION_REASONS,
			at.AGNT_NAME, at.AGNT_DISP_NAME, at.AGNT_LOCALITY, at.AGNT_ADDRESS, at.AGNT_POSTAL,
			ag.AGNC_DISP_ID, ag.AGNC_DISP_NAME, ag.AGNC_LOCALITY, ag.AGNC_ADDRESS,
			u.USER_CASHIER_ID, u.USER_FIRST_NAME, u.USER_FAMILY_NAME, ISNULL(o.ORD_NOTES, '''') ORD_NOTES, o.ORD_RECEIVER_ACCNT_TYPE, ISNULL(aml.ORDER_ID, 0) ANKIETA_AML, aml.ALL_FORM_DATA
				from ' + @DBNAME + '.dbo.ORDERS o
				left join AGENCIES ag ON ag.AGNC_DISP_NAME = o.AGNC_DISP_NAME
				left join AGENTS at ON at.AGNT_ID = ag.AGNT_ID
				left join FENIKS.USERS u ON u.USER_ID = o.USER_ID
				left join FENIKS.ORDERS_AML_FORM aml ON aml.ORDER_ID = o.ORD_ID
				left join FENIKS.FENIKS.ORDERS_DETAILS od ON od.ORD_ID = o.ORD_ID
			where o.ORD_ID = ' + CONVERT(VARCHAR, @ORD_ID)
	
	EXECUTE sp_executesql @Command

END
GO
