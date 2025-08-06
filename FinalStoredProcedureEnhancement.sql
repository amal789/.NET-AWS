-- =====================================================
-- FINAL STORED PROCEDURE ENHANCEMENT FOR UNIVERSAL SEARCH (5 FIELDS)
-- Universal Search: TenantName, FriendlyName, SerialNumber, ProductName, FirmwareVersion
-- =====================================================

-- Step 1: Add the @QUERYSTR parameter to your stored procedure header
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
    @QUERYSTR VARCHAR(100) = NULL               -- Universal search across 5 fields
AS             
BEGIN          
    SET NOCOUNT ON                  
    
    -- ... existing code for data population ...
    
    -- Step 2: Add universal search filtering logic (AFTER data population, BEFORE other filters)
    -- This searches across 5 fields: TenantName, FriendlyName, SerialNumber, ProductName, FirmwareVersion
    
    IF @QUERYSTR IS NOT NULL AND LEN(TRIM(@QUERYSTR)) > 0
    BEGIN
        DECLARE @SearchTerm VARCHAR(102) = '%' + UPPER(@QUERYSTR) + '%'
        
        DELETE FROM #TEMPLISTTABLE 
        WHERE NOT (
            -- Search in TenantName (PRODUCTGROUPNAME)
            (PRODUCTGROUPNAME IS NOT NULL AND UPPER(PRODUCTGROUPNAME) LIKE @SearchTerm)
            OR
            -- Search in FriendlyName (NAME)  
            (NAME IS NOT NULL AND UPPER(NAME) LIKE @SearchTerm)
            OR
            -- Search in SerialNumber
            (SERIALNUMBER IS NOT NULL AND UPPER(SERIALNUMBER) LIKE @SearchTerm)
            OR
            -- Search in ProductName
            (PRODUCTNAME IS NOT NULL AND UPPER(PRODUCTNAME) LIKE @SearchTerm)
            OR
            -- Search in FirmwareVersion
            (FIRMWAREVERSION IS NOT NULL AND UPPER(FIRMWAREVERSION) LIKE @SearchTerm)
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

    -- Declare pagination variables
    DECLARE @TotalRecords INT
    DECLARE @ValidatedPageNo INT = ISNULL(@PAGENO, 1)
    DECLARE @ValidatedPageSize INT = ISNULL(@PAGESIZE, 50)
    DECLARE @OffsetRows INT

    -- Get total record count before pagination
    SELECT @TotalRecords = COUNT(*) FROM #TEMPLISTTABLE

    -- Apply MINCOUNT filter if specified
    IF @MINCOUNT IS NOT NULL AND @TotalRecords < @MINCOUNT
    BEGIN
        DELETE FROM #TEMPLISTTABLE
    END

    -- Apply MAXCOUNT filter if specified  
    IF @MAXCOUNT IS NOT NULL AND @TotalRecords > @MAXCOUNT
    BEGIN
        DELETE FROM #TEMPLISTTABLE
    END

    -- Apply pagination if records still exist
    IF EXISTS(SELECT 1 FROM #TEMPLISTTABLE)
    BEGIN
        -- Validate page number (must be at least 1)
        IF @ValidatedPageNo < 1 SET @ValidatedPageNo = 1
        
        -- Validate page size (must be at least 1, max 5000 for performance)
        IF @ValidatedPageSize < 1 SET @ValidatedPageSize = 50
        IF @ValidatedPageSize > 5000 SET @ValidatedPageSize = 5000
        
        -- Calculate offset
        SET @OffsetRows = (@ValidatedPageNo - 1) * @ValidatedPageSize
        
        -- Create a temporary table with row numbers for pagination
        CREATE TABLE #PAGINATEDTABLE (
            RowNum INT,
            CID INT
        )
        
        -- Insert row numbers with pagination logic
        INSERT INTO #PAGINATEDTABLE (RowNum, CID)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY CID) as RowNum,
            CID
        FROM #TEMPLISTTABLE
        
        -- Delete records outside the requested page
        DELETE FROM #TEMPLISTTABLE 
        WHERE CID NOT IN (
            SELECT CID 
            FROM #PAGINATEDTABLE 
            WHERE RowNum > @OffsetRows 
            AND RowNum <= (@OffsetRows + @ValidatedPageSize)
        )
        
        DROP TABLE #PAGINATEDTABLE
    END
    
    -- Final SELECT to return data
    IF ( @OutformatXML = 0 )             
    BEGIN
        SELECT 
            PRODUCT.SERIALNUMBER,
            PRODUCT.PRODUCTNAME,
            PRODUCT.NAME,
            PRODUCT.PRODUCTTYPE,
            PRODUCT.FIRMWAREVERSION,
            PRODUCT.SUPPORTEXPIRYDATE,
            PRODUCT.REGISTRATIONDATE,
            PRODUCT.ISZTSUPPORTED,
            PRODUCT.PRODUCTGROUPNAME,
            PRODUCT.PRODUCTGROUPID,
            PRODUCT.ORGANIZATIONID,
            PRODUCT.ORGNAME,
            PRODUCT.MINLICENSEEXPIRYDATE,
            PRODUCT.CCNODECOUNT,
            PRODUCT.DEVICESTATUS,
            PRODUCT.ISDOWNLOADAVAILABLE,
            PRODUCT.HESNODECOUNT,
            PRODUCT.ISLICENSEEXPIRED,
            PRODUCT.MANAGEMENTOPTION
            -- Add other fields as needed
        FROM #TEMPLISTTABLE AS PRODUCT
        ORDER BY PRODUCT.CID
    END
         
END

-- =====================================================
-- TESTING THE UNIVERSAL SEARCH (5 FIELDS)
-- =====================================================

-- Test 1: Search for "SonicWall" across all 5 fields
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
    @QUERYSTR = 'SonicWall';  -- Universal search across 5 fields

-- Test 2: Search for firmware version "7.0" across all 5 fields
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
    @QUERYSTR = '7.0';  -- Will find "7.0" in any of the 5 fields

-- Test 3: Search for "NSa" across all 5 fields
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
    @QUERYSTR = 'NSa';  -- Will find "NSa" in serial numbers, product names, etc.

-- Test 4: No universal search (get all records)
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
    @QUERYSTR = NULL;  -- No universal search filter

-- Test 5: Universal search combined with organization filter
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
    @ORGANISATIONID = 12345,        -- Organization filter
    @ISLICENSEEXPIRY = 0,           -- Non-expired licenses
    @PAGENO = 1,
    @PAGESIZE = 5000,
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL,
    @QUERYSTR = 'SonicWall';        -- Universal search + other filters

-- =====================================================
-- DEBUGGING UNIVERSAL SEARCH (5 FIELDS)
-- =====================================================

-- Add this debug code to see how many records each filter step removes:
/*
-- Debug version with record counts
IF @QUERYSTR IS NOT NULL AND LEN(TRIM(@QUERYSTR)) > 0
BEGIN
    DECLARE @BeforeCount INT, @AfterCount INT
    SELECT @BeforeCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records before universal search: ' + CAST(@BeforeCount AS VARCHAR(10))
    
    DECLARE @SearchTerm VARCHAR(102) = '%' + UPPER(@QUERYSTR) + '%'
    
    DELETE FROM #TEMPLISTTABLE 
    WHERE NOT (
        (PRODUCTGROUPNAME IS NOT NULL AND UPPER(PRODUCTGROUPNAME) LIKE @SearchTerm)
        OR (NAME IS NOT NULL AND UPPER(NAME) LIKE @SearchTerm)
        OR (SERIALNUMBER IS NOT NULL AND UPPER(SERIALNUMBER) LIKE @SearchTerm)
        OR (PRODUCTNAME IS NOT NULL AND UPPER(PRODUCTNAME) LIKE @SearchTerm)
        OR (FIRMWAREVERSION IS NOT NULL AND UPPER(FIRMWAREVERSION) LIKE @SearchTerm)
    )
    
    SELECT @AfterCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records after universal search: ' + CAST(@AfterCount AS VARCHAR(10))
    PRINT 'Search term: ' + @QUERYSTR
END
*/

-- =====================================================
-- PERFORMANCE OPTIMIZATION FOR 5-FIELD SEARCH
-- =====================================================

-- Optional: Add indexes for better search performance
/*
-- Index for faster text searches on the 5 search fields
CREATE NONCLUSTERED INDEX IX_CUSTOMERPRODUCTSSUMMARY_UNIVERSAL_SEARCH 
ON CUSTOMERPRODUCTSSUMMARY (PRODUCTNAME, NAME, SERIALNUMBER, FIRMWAREVERSION) 
INCLUDE (PRODUCTGROUPNAME);

-- If you have control over the temporary table structure, add this index:
CREATE NONCLUSTERED INDEX IX_TEMPLISTTABLE_UNIVERSAL_SEARCH
ON #TEMPLISTTABLE (PRODUCTNAME, NAME, SERIALNUMBER, FIRMWAREVERSION, PRODUCTGROUPNAME);
*/

-- =====================================================
-- FIELD MAPPING REFERENCE
-- =====================================================

/*
Universal Search Fields Mapping:
1. TenantName     -> PRODUCTGROUPNAME
2. FriendlyName   -> NAME  
3. SerialNumber   -> SERIALNUMBER
4. ProductName    -> PRODUCTNAME
5. FirmwareVersion -> FIRMWAREVERSION

The @QUERYSTR parameter will search for the provided text in ANY of these 5 fields.
It's case-insensitive and uses LIKE with wildcards (%term%).

Example searches:
- "SonicWall" will find records where any of the 5 fields contains "SonicWall"
- "7.0" will find records where any of the 5 fields contains "7.0" 
- "NSa" will find records where any of the 5 fields contains "NSa"
- "TZ" will find records where any of the 5 fields contains "TZ"
*/