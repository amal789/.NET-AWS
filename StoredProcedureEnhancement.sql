-- =====================================================
-- STORED PROCEDURE ENHANCEMENT FOR UNIVERSAL SEARCH
-- Add this to your existing GETASSOCIATEDPRODUCTSWITHORDERLIST
-- =====================================================

-- Step 1: Add the new @QUERYSTR parameter to your stored procedure header
-- Add this after the existing @MAXCOUNT parameter:

ALTER PROCEDURE [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]        
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
    @SOURCE VARCHAR(10) =''  ,      
    @SEARCHSERIALNUMBER VARCHAR(30) ='',      
    @ISPRODUCTGROUPTABLENEEDED VARCHAR(10) ='YES',    
    @ORGANISATIONID BIGINT = NULL,              
    @ISLICENSEEXPIRY BIT = NULL,                
    @PAGENO INT = 1,                            
    @PAGESIZE INT = 50,                         
    @MINCOUNT INT = NULL,                       
    @MAXCOUNT INT = NULL,                        
    @QUERYSTR VARCHAR(100) = NULL               -- NEW: Universal search parameter
AS             
BEGIN          
    SET NOCOUNT ON                  
    
    -- ... existing code ...
    
    -- Step 2: Add universal search filtering logic
    -- Add this AFTER the existing filters but BEFORE pagination
    
    -- Apply universal search filter if specified
    IF @QUERYSTR IS NOT NULL AND LEN(TRIM(@QUERYSTR)) > 0
    BEGIN
        DELETE FROM #TEMPLISTTABLE 
        WHERE NOT (
            -- Search in TenantName (PRODUCTGROUPNAME)
            (PRODUCTGROUPNAME IS NOT NULL AND PRODUCTGROUPNAME LIKE '%' + @QUERYSTR + '%')
            OR
            -- Search in FriendlyName (NAME)  
            (NAME IS NOT NULL AND NAME LIKE '%' + @QUERYSTR + '%')
            OR
            -- Search in SerialNumber
            (SERIALNUMBER IS NOT NULL AND SERIALNUMBER LIKE '%' + @QUERYSTR + '%')
            OR
            -- Search in ProductName
            (PRODUCTNAME IS NOT NULL AND PRODUCTNAME LIKE '%' + @QUERYSTR + '%')
        )
    END

    -- Apply ORGANISATIONID filter if specified
    IF @ORGANISATIONID IS NOT NULL
    BEGIN
        DELETE FROM #TEMPLISTTABLE 
        WHERE SERIALNUMBER NOT IN (
            SELECT CP.SERIALNUMBER 
            FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
            INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
            WHERE V.ORGANIZATIONID = @ORGANISATIONID
        )
    END

    -- Apply ISLICENSEEXPIRY filter if specified
    IF @ISLICENSEEXPIRY IS NOT NULL
    BEGIN
        IF @ISLICENSEEXPIRY = 1
        BEGIN
            DELETE FROM #TEMPLISTTABLE WHERE ISLICENSEEXPIRED <> 1 OR ISLICENSEEXPIRED IS NULL
        END
        ELSE IF @ISLICENSEEXPIRY = 0
        BEGIN
            DELETE FROM #TEMPLISTTABLE WHERE ISLICENSEEXPIRED = 1
        END
    END

    -- ... rest of pagination logic ...
    
END

-- =====================================================
-- ALTERNATIVE: Case-Insensitive Universal Search
-- Use this version if you want case-insensitive search
-- =====================================================

-- Replace the universal search section with this for case-insensitive search:
/*
    IF @QUERYSTR IS NOT NULL AND LEN(TRIM(@QUERYSTR)) > 0
    BEGIN
        DECLARE @SearchQuery VARCHAR(102) = '%' + UPPER(@QUERYSTR) + '%'
        
        DELETE FROM #TEMPLISTTABLE 
        WHERE NOT (
            -- Search in TenantName (case-insensitive)
            (PRODUCTGROUPNAME IS NOT NULL AND UPPER(PRODUCTGROUPNAME) LIKE @SearchQuery)
            OR
            -- Search in FriendlyName (case-insensitive)  
            (NAME IS NOT NULL AND UPPER(NAME) LIKE @SearchQuery)
            OR
            -- Search in SerialNumber (case-insensitive)
            (SERIALNUMBER IS NOT NULL AND UPPER(SERIALNUMBER) LIKE @SearchQuery)
            OR
            -- Search in ProductName (case-insensitive)
            (PRODUCTNAME IS NOT NULL AND UPPER(PRODUCTNAME) LIKE @SearchQuery)
        )
    END
*/

-- =====================================================
-- TESTING THE UNIVERSAL SEARCH
-- =====================================================

-- Test 1: Search for "SonicWall" across all fields
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = N'4_37687189',
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @ASSOCTYPEID = NULL,
    @ASSOCTYPE = '',
    @SERIALNUMBER = '',
    @LANGUAGECODE = 'EN',
    @SESSIONID = NULL,
    @PRODUCTLIST = '',
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0,
    @CallFrom = '',
    @IsMobile = '',
    @SOURCE = '',
    @SEARCHSERIALNUMBER = '',
    @ISPRODUCTGROUPTABLENEEDED = 'YES',
    @ORGANISATIONID = NULL,
    @ISLICENSEEXPIRY = NULL,
    @PAGENO = 1,
    @PAGESIZE = 50,
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL,
    @QUERYSTR = 'SonicWall';  -- NEW: Universal search

-- Test 2: Search for specific serial number
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = N'4_37687189',
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @ASSOCTYPEID = NULL,
    @ASSOCTYPE = '',
    @SERIALNUMBER = '',
    @LANGUAGECODE = 'EN',
    @SESSIONID = NULL,
    @PRODUCTLIST = '',
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0,
    @CallFrom = '',
    @IsMobile = '',
    @SOURCE = '',
    @SEARCHSERIALNUMBER = '',
    @ISPRODUCTGROUPTABLENEEDED = 'YES',
    @ORGANISATIONID = NULL,
    @ISLICENSEEXPIRY = NULL,
    @PAGENO = 1,
    @PAGESIZE = 5000,  -- Get more records
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL,
    @QUERYSTR = 'NSa';  -- Search for NSa products

-- Test 3: No search filter (should return all records)
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = N'4_37687189',
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @ASSOCTYPEID = NULL,
    @ASSOCTYPE = '',
    @SERIALNUMBER = '',
    @LANGUAGECODE = 'EN',
    @SESSIONID = NULL,
    @PRODUCTLIST = '',
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0,
    @CallFrom = '',
    @IsMobile = '',
    @SOURCE = '',
    @SEARCHSERIALNUMBER = '',
    @ISPRODUCTGROUPTABLENEEDED = 'YES',
    @ORGANISATIONID = NULL,
    @ISLICENSEEXPIRY = NULL,
    @PAGENO = 1,
    @PAGESIZE = 5000,
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL,
    @QUERYSTR = NULL;  -- No universal search

-- =====================================================
-- PERFORMANCE OPTIMIZATION FOR UNIVERSAL SEARCH
-- =====================================================

-- If you have large datasets, consider adding these indexes:
/*
CREATE NONCLUSTERED INDEX IX_CUSTOMERPRODUCTSSUMMARY_SEARCH 
ON CUSTOMERPRODUCTSSUMMARY (PRODUCTNAME, NAME, SERIALNUMBER) 
INCLUDE (PRODUCTGROUPNAME);

CREATE NONCLUSTERED INDEX IX_TEMPLISTTABLE_SEARCH
ON #TEMPLISTTABLE (PRODUCTNAME, NAME, SERIALNUMBER, PRODUCTGROUPNAME);
*/

-- =====================================================
-- DEBUGGING UNIVERSAL SEARCH
-- =====================================================

-- Add this temporary debug code to see how many records each filter step removes:
/*
-- Debug: Count before universal search
SELECT 'Before Universal Search' as Step, COUNT(*) as RecordCount FROM #TEMPLISTTABLE;

-- Apply universal search with debug
IF @QUERYSTR IS NOT NULL AND LEN(TRIM(@QUERYSTR)) > 0
BEGIN
    DELETE FROM #TEMPLISTTABLE 
    WHERE NOT (
        (PRODUCTGROUPNAME IS NOT NULL AND PRODUCTGROUPNAME LIKE '%' + @QUERYSTR + '%')
        OR (NAME IS NOT NULL AND NAME LIKE '%' + @QUERYSTR + '%')
        OR (SERIALNUMBER IS NOT NULL AND SERIALNUMBER LIKE '%' + @QUERYSTR + '%')
        OR (PRODUCTNAME IS NOT NULL AND PRODUCTNAME LIKE '%' + @QUERYSTR + '%')
    );
    
    -- Debug: Count after universal search
    SELECT 'After Universal Search' as Step, COUNT(*) as RecordCount FROM #TEMPLISTTABLE;
END
*/