USE [FENIKS]
GO
/****** Object:  StoredProcedure [dbo].[Feniks_Pobierz_PlikiAML]    Script Date: 08.11.2022 20:24:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Marek Wypych
-- Create date: 2021-04-10
-- Description: lista zaączników do ankiety AML
-- =============================================
CREATE PROCEDURE [dbo].[Feniks_Pobierz_PlikiAML]
	@ORD_ID INT
AS
BEGIN

	select 
		d.FILENAME, d.UPLOAD_DATE, d.UPLOADER_LOGIN, b.DOC_BIN 
		from FENIKS.FENIKS.AML_DOCUMENTS d
		join FENIKS..aml_documents_bin b on d.ID = b.DOC_ID
			where d.ORD_ID = @ORD_ID

END
GO
