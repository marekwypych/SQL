USE [WSPOLNA]
GO
/****** Object:  StoredProcedure [dbo].[____Repl_po_imporcie_ROC]    Script Date: 08.11.2022 20:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[____Repl_po_imporcie_ROC]
AS
BEGIN
  
  SET NOCOUNT ON;
  
  UPDATE [WSPOLNA].[dbo]._TEMP_WITHDRAWAL SET NrRachWystawcy = '0169900297500'
	WHERE NrRachWystawcy = '169900297500'

  UPDATE [WSPOLNA].[dbo]._TEMP_WITHDRAWAL SET NrRachWystawcy = '4' + NrRachWystawcy
	WHERE LEN(NrRachWystawcy) = 12

  UPDATE [WSPOLNA].[dbo]._TEMP_WITHDRAWAL SET Status = '1'
	WHERE Status = 'Zrealizowana'

  UPDATE [WSPOLNA].[dbo]._TEMP_WITHDRAWAL SET Status = '2'
	WHERE Status = 'Wycofana'

	INSERT INTO WITHDRAWAL SELECT * FROM _TEMP_WITHDRAWAL

	DELETE FROM _TEMP_WITHDRAWAL

END
GO
