IF OBJECT_ID(N'dbo.GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO', N'P') IS NOT NULL
    DROP PROCEDURE dbo.GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO;
GO

CREATE PROCEDURE [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO]
    @USERNAME NVARCHAR(30) ,
    @ORDERNAME VARCHAR(50) ,
    @ORDERTYPE VARCHAR(30) ,
    @ASSOCTYPEID INT = 0 ,
    @ASSOCTYPE VARCHAR(30) = '' ,
    @SERIALNUMBER VARCHAR(30) = '' ,
    @LANGUAGECODE CHAR(2) = 'EN' ,
    @SESSIONID VARCHAR(50) = NULL ,
    @PRODUCTLIST VARCHAR(100) = NULL ,
    @OEMCODE CHAR(4) = 'SNWL' ,
    @APPNAME VARCHAR(50) = 'MSW' ,
    @OutformatXML INT = NULL ,
    @CallFrom VARCHAR(50) = NULL ,
    @IsMobile VARCHAR(50) = 'NO',
    @SOURCE VARCHAR(10) ='',
    @SEARCHSERIALNUMBER VARCHAR(30) ='',
    @ISPRODUCTGROUPTABLENEEDED VARCHAR(10) ='YES'
AS
BEGIN
    SET NOCOUNT ON;

    EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
        @USERNAME = @USERNAME,
        @ORDERNAME = @ORDERNAME,
        @ORDERTYPE = @ORDERTYPE,
        @ASSOCTYPEID = @ASSOCTYPEID,
        @ASSOCTYPE = @ASSOCTYPE,
        @SERIALNUMBER = @SERIALNUMBER,
        @LANGUAGECODE = @LANGUAGECODE,
        @SESSIONID = @SESSIONID,
        @PRODUCTLIST = @PRODUCTLIST,
        @OEMCODE = @OEMCODE,
        @APPNAME = @APPNAME,
        @OutformatXML = @OutformatXML,
        @CallFrom = @CallFrom,
        @IsMobile = @IsMobile,
        @SOURCE = @SOURCE,
        @SEARCHSERIALNUMBER = @SEARCHSERIALNUMBER,
        @ISPRODUCTGROUPTABLENEEDED = @ISPRODUCTGROUPTABLENEEDED;
END
GO

-- DEMO: sample executions
-- Notes:
-- - Set @PRODUCTLIST = 'LIMIT' to get a limited (TOP 10) list; omit or set NULL for full result as per internal logic
-- - Set @OutformatXML = 1 to get XML output where supported by the underlying procedure

-- Example 1: Basic list (JSON/tabular depending on underlying SP branches)
-- EXEC dbo.GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO
--     @USERNAME = N'demo_user',
--     @ORDERNAME = 'AssociatedProducts',
--     @ORDERTYPE = 'DEFAULT',
--     @ASSOCTYPEID = 0,
--     @ASSOCTYPE = '',
--     @SERIALNUMBER = '',
--     @LANGUAGECODE = 'EN',
--     @SESSIONID = NULL,
--     @PRODUCTLIST = NULL,
--     @OEMCODE = 'SNWL',
--     @APPNAME = 'MSW',
--     @OutformatXML = 0,
--     @CallFrom = NULL,
--     @IsMobile = 'NO',
--     @SOURCE = '',
--     @SEARCHSERIALNUMBER = '',
--     @ISPRODUCTGROUPTABLENEEDED = 'YES';

-- Example 2: Limited top 10 list
-- EXEC dbo.GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO
--     @USERNAME = N'demo_user',
--     @ORDERNAME = 'AssociatedProducts',
--     @ORDERTYPE = 'DEFAULT',
--     @PRODUCTLIST = 'LIMIT',
--     @OutformatXML = 0,
--     @OEMCODE = 'SNWL',
--     @APPNAME = 'MSW',
--     @IsMobile = 'NO';

-- Example 3: XML output
-- EXEC dbo.GETASSOCIATEDPRODUCTSWITHORDERLISTDEMO
--     @USERNAME = N'demo_user',
--     @ORDERNAME = 'AssociatedProducts',
--     @ORDERTYPE = 'DEFAULT',
--     @PRODUCTLIST = 'LIMIT',
--     @OutformatXML = 1;