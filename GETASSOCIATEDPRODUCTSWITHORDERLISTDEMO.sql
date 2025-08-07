-- =============================================
-- GETASSOCIATEDPRODUCTSWITHORDERLIST DEMO
-- =============================================
-- This demo script shows how to use the GETASSOCIATEDPRODUCTSWITHORDERLIST stored procedure
-- with various parameter combinations and scenarios.

-- =============================================
-- SCENARIO 1: Basic Usage with Required Parameters
-- =============================================
PRINT '=== SCENARIO 1: Basic Usage ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'demo_user',
    @ORDERNAME = 'DEMO_ORDER_001',
    @ORDERTYPE = 'STANDARD'

-- =============================================
-- SCENARIO 2: With Association Type Filter
-- =============================================
PRINT '=== SCENARIO 2: With Association Type Filter ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'demo_user',
    @ORDERNAME = 'DEMO_ORDER_002',
    @ORDERTYPE = 'PREMIUM',
    @ASSOCTYPEID = 1,
    @ASSOCTYPE = 'PRIMARY'

-- =============================================
-- SCENARIO 3: With Serial Number Filter
-- =============================================
PRINT '=== SCENARIO 3: With Serial Number Filter ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'demo_user',
    @ORDERNAME = 'DEMO_ORDER_003',
    @ORDERTYPE = 'STANDARD',
    @SERIALNUMBER = 'SN123456789'

-- =============================================
-- SCENARIO 4: Mobile Application Usage
-- =============================================
PRINT '=== SCENARIO 4: Mobile Application Usage ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'mobile_user',
    @ORDERNAME = 'MOBILE_ORDER_001',
    @ORDERTYPE = 'MOBILE',
    @IsMobile = 'YES',
    @APPNAME = 'MSW'

-- =============================================
-- SCENARIO 5: With Product List Filter
-- =============================================
PRINT '=== SCENARIO 5: With Product List Filter ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'demo_user',
    @ORDERNAME = 'PRODUCT_FILTER_ORDER',
    @ORDERTYPE = 'STANDARD',
    @PRODUCTLIST = 'PROD001,PROD002,PROD003'

-- =============================================
-- SCENARIO 6: XML Output Format
-- =============================================
PRINT '=== SCENARIO 6: XML Output Format ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'xml_user',
    @ORDERNAME = 'XML_ORDER_001',
    @ORDERTYPE = 'STANDARD',
    @OutformatXML = 1

-- =============================================
-- SCENARIO 7: With Language and OEM Code
-- =============================================
PRINT '=== SCENARIO 7: With Language and OEM Code ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'international_user',
    @ORDERNAME = 'INTL_ORDER_001',
    @ORDERTYPE = 'INTERNATIONAL',
    @LANGUAGECODE = 'FR',
    @OEMCODE = 'SNWL'

-- =============================================
-- SCENARIO 8: With Session ID and Source
-- =============================================
PRINT '=== SCENARIO 8: With Session ID and Source ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'session_user',
    @ORDERNAME = 'SESSION_ORDER_001',
    @ORDERTYPE = 'STANDARD',
    @SESSIONID = 'SESS_12345_67890',
    @SOURCE = 'WEB'

-- =============================================
-- SCENARIO 9: Search by Serial Number
-- =============================================
PRINT '=== SCENARIO 9: Search by Serial Number ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'search_user',
    @ORDERNAME = 'SEARCH_ORDER_001',
    @ORDERTYPE = 'STANDARD',
    @SEARCHSERIALNUMBER = 'SEARCH_SN_123'

-- =============================================
-- SCENARIO 10: Without Product Group Table
-- =============================================
PRINT '=== SCENARIO 10: Without Product Group Table ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'simple_user',
    @ORDERNAME = 'SIMPLE_ORDER_001',
    @ORDERTYPE = 'STANDARD',
    @ISPRODUCTGROUPTABLENEEDED = 'NO'

-- =============================================
-- PARAMETER REFERENCE
-- =============================================
/*
Parameter Descriptions:
- @USERNAME: User identifier (required)
- @ORDERNAME: Name of the order (required)
- @ORDERTYPE: Type of order (required)
- @ASSOCTYPEID: Association type ID (optional, default 0)
- @ASSOCTYPE: Association type name (optional, default '')
- @SERIALNUMBER: Specific serial number filter (optional, default '')
- @LANGUAGECODE: Language code for localization (optional, default 'EN')
- @SESSIONID: Session identifier (optional, default NULL)
- @PRODUCTLIST: Comma-separated list of product IDs (optional, default NULL)
- @OEMCODE: OEM code (optional, default 'SNWL')
- @APPNAME: Application name (optional, default 'MSW')
- @OutformatXML: Output format flag (optional, default NULL)
- @CallFrom: Calling application identifier (optional, default NULL)
- @IsMobile: Mobile application flag (optional, default 'NO')
- @SOURCE: Source system identifier (optional, default '')
- @SEARCHSERIALNUMBER: Serial number for search (optional, default '')
- @ISPRODUCTGROUPTABLENEEDED: Flag for product group table (optional, default 'YES')
*/

-- =============================================
-- ERROR HANDLING EXAMPLE
-- =============================================
PRINT '=== ERROR HANDLING EXAMPLE ==='
BEGIN TRY
    EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
        @USERNAME = NULL,  -- This will cause an error
        @ORDERNAME = 'ERROR_ORDER',
        @ORDERTYPE = 'STANDARD'
END TRY
BEGIN CATCH
    PRINT 'Error occurred: ' + ERROR_MESSAGE()
END CATCH

-- =============================================
-- PERFORMANCE TIPS
-- =============================================
/*
Performance Optimization Tips:
1. Always provide @USERNAME, @ORDERNAME, and @ORDERTYPE for best performance
2. Use specific @SERIALNUMBER when possible to reduce result set
3. Set @ISPRODUCTGROUPTABLENEEDED = 'NO' if product group data is not needed
4. Use appropriate @LANGUAGECODE to avoid unnecessary localization processing
5. Consider using @PRODUCTLIST to filter specific products
6. Set @IsMobile = 'YES' for mobile applications to optimize for mobile usage
*/