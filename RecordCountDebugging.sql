-- =====================================================
-- DEBUGGING MISSING RECORDS (2536 vs 2519 = 17 missing)
-- =====================================================

-- 🔍 STEP-BY-STEP DEBUGGING TO FIND THE 17 MISSING RECORDS

-- Your EXEC statement:
/*
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=1873731,
    @ISLICENSEEXPIRY=NULL,
    @PAGENO=1,
    @PAGESIZE=5000,
    @MINCOUNT=10,
    @MAXCOUNT=20000,
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER=''
*/

-- =====================================================
-- STEP 1: RUN OLD QUERY TO CONFIRM BASELINE
-- =====================================================

-- First, run the OLD version without our new parameters to confirm 2536 records
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='';

-- Expected: 2536 records
-- This confirms the baseline

-- =====================================================
-- STEP 2: TEST WITH MINIMAL NEW PARAMETERS
-- =====================================================

-- Test 2A: Add only SOURCE and ISPRODUCTGROUPTABLENEEDED
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='';

-- Expected: Should still be 2536 records
-- If not, the issue is with SOURCE or ISPRODUCTGROUPTABLENEEDED logic

-- =====================================================
-- STEP 3: TEST ORGANIZATION FILTER ALONE
-- =====================================================

-- Test 3A: Add only ORGANISATIONID filter
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=1873731,
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='';

-- Check record count here
-- If this shows 2519, then ORGANISATIONID filter is removing 17 records

-- =====================================================
-- STEP 4: ANALYZE THE ORGANIZATION FILTER LOGIC
-- =====================================================

-- Let's check what the ORGANISATIONID filter is doing:
/*
The filter logic is:
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
*/

-- Test 4A: Check how many serial numbers exist for this organization
SELECT COUNT(DISTINCT CP.SERIALNUMBER) AS SerialNumbersInOrg
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE V.ORGANIZATIONID = 1873731;

-- Test 4B: Find the 17 missing serial numbers
-- First, get all serial numbers from the original query (without org filter)
SELECT SERIALNUMBER INTO #OriginalSerials
FROM (
    -- Run your original logic here to get the 2536 records
    -- This is a placeholder - you'll need to extract the logic
    SELECT 'PLACEHOLDER' AS SERIALNUMBER
) AS OriginalData;

-- Then find what's missing when org filter is applied
SELECT DISTINCT SERIALNUMBER 
FROM #OriginalSerials
WHERE SERIALNUMBER NOT IN (
    SELECT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
    WHERE V.ORGANIZATIONID = 1873731
);

-- This will show you the 17 missing serial numbers

-- =====================================================
-- STEP 5: DETAILED ORGANIZATION ANALYSIS
-- =====================================================

-- Test 5A: Check the user's organization details
SELECT 
    V.USERNAME,
    V.ORGANIZATIONID,
    V.ORGANIZATIONNAME,
    COUNT(CP.SERIALNUMBER) AS ProductCount
FROM vCUSTOMER V WITH (NOLOCK)
LEFT JOIN CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE V.USERNAME = '4_37687189'
GROUP BY V.USERNAME, V.ORGANIZATIONID, V.ORGANIZATIONNAME;

-- Test 5B: Check if user belongs to multiple organizations
SELECT DISTINCT 
    V.ORGANIZATIONID,
    V.ORGANIZATIONNAME,
    COUNT(CP.SERIALNUMBER) AS ProductCount
FROM vCUSTOMER V WITH (NOLOCK)
LEFT JOIN CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE V.USERNAME = '4_37687189'
GROUP BY V.ORGANIZATIONID, V.ORGANIZATIONNAME;

-- Test 5C: Check if there are products not associated with the specified organization
SELECT 
    CP.SERIALNUMBER,
    CP.USERNAME,
    V.ORGANIZATIONID,
    V.ORGANIZATIONNAME
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
LEFT JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE CP.USERNAME = '4_37687189'
AND (V.ORGANIZATIONID != 1873731 OR V.ORGANIZATIONID IS NULL)
ORDER BY CP.SERIALNUMBER;

-- This shows products that would be filtered out by the organization filter

-- =====================================================
-- STEP 6: TEST OTHER POTENTIAL ISSUES
-- =====================================================

-- Test 6A: Check if ISPRODUCTGROUPTABLENEEDED='NO' is causing issues
-- Compare these two:

-- With product group table
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='YES',
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='';

-- Without product group table  
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='0',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='';

-- Compare record counts

-- =====================================================
-- STEP 7: INCREMENTAL PARAMETER TESTING
-- =====================================================

-- Test each parameter addition one by one:

-- Test 7A: Baseline
exec GETASSOCIATEDPRODUCTSWITHORDERLIST @USERNAME=N'4_37687189',@ORDERNAME='REGISTEREDDATE',@ORDERTYPE='0',@ASSOCTYPEID=NULL,@ASSOCTYPE='',@SERIALNUMBER='',@LANGUAGECODE='EN',@SESSIONID=NULL,@PRODUCTLIST='',@OEMCODE='SNWL',@APPNAME='MSW',@OutformatXML=0,@CallFrom='',@IsMobile='',@SEARCHSERIALNUMBER='';

-- Test 7B: Add SOURCE
exec GETASSOCIATEDPRODUCTSWITHORDERLIST @SOURCE='RESTAPI',@USERNAME=N'4_37687189',@ORDERNAME='REGISTEREDDATE',@ORDERTYPE='0',@ASSOCTYPEID=NULL,@ASSOCTYPE='',@SERIALNUMBER='',@LANGUAGECODE='EN',@SESSIONID=NULL,@PRODUCTLIST='',@OEMCODE='SNWL',@APPNAME='MSW',@OutformatXML=0,@CallFrom='',@IsMobile='',@SEARCHSERIALNUMBER='';

-- Test 7C: Add ISPRODUCTGROUPTABLENEEDED
exec GETASSOCIATEDPRODUCTSWITHORDERLIST @SOURCE='RESTAPI',@ISPRODUCTGROUPTABLENEEDED='NO',@USERNAME=N'4_37687189',@ORDERNAME='REGISTEREDDATE',@ORDERTYPE='0',@ASSOCTYPEID=NULL,@ASSOCTYPE='',@SERIALNUMBER='',@LANGUAGECODE='EN',@SESSIONID=NULL,@PRODUCTLIST='',@OEMCODE='SNWL',@APPNAME='MSW',@OutformatXML=0,@CallFrom='',@IsMobile='',@SEARCHSERIALNUMBER='';

-- Test 7D: Add ORGANISATIONID (this likely causes the drop from 2536 to 2519)
exec GETASSOCIATEDPRODUCTSWITHORDERLIST @SOURCE='RESTAPI',@ISPRODUCTGROUPTABLENEEDED='NO',@ORGANISATIONID=1873731,@USERNAME=N'4_37687189',@ORDERNAME='REGISTEREDDATE',@ORDERTYPE='0',@ASSOCTYPEID=NULL,@ASSOCTYPE='',@SERIALNUMBER='',@LANGUAGECODE='EN',@SESSIONID=NULL,@PRODUCTLIST='',@OEMCODE='SNWL',@APPNAME='MSW',@OutformatXML=0,@CallFrom='',@IsMobile='',@SEARCHSERIALNUMBER='';

-- Test 7E: Add remaining parameters
exec GETASSOCIATEDPRODUCTSWITHORDERLIST @SOURCE='RESTAPI',@ISPRODUCTGROUPTABLENEEDED='NO',@ORGANISATIONID=1873731,@ISLICENSEEXPIRY=NULL,@PAGENO=1,@PAGESIZE=5000,@MINCOUNT=10,@MAXCOUNT=20000,@USERNAME=N'4_37687189',@ORDERNAME='REGISTEREDDATE',@ORDERTYPE='0',@ASSOCTYPEID=NULL,@ASSOCTYPE='',@SERIALNUMBER='',@LANGUAGECODE='EN',@SESSIONID=NULL,@PRODUCTLIST='',@OEMCODE='SNWL',@APPNAME='MSW',@OutformatXML=0,@CallFrom='',@IsMobile='',@SEARCHSERIALNUMBER='';

-- Record the count after each step to identify where the drop occurs

-- =====================================================
-- DEBUGGING VERSION WITH COUNT TRACKING
-- =====================================================

-- Add this debugging code to your stored procedure temporarily:
/*
-- Add these PRINT statements in your stored procedure at key points:

-- After initial data population (before any new filters):
SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
PRINT 'Records after initial population: ' + CAST(@DebugCount AS VARCHAR(10))

-- After ORGANISATIONID filter:
IF @ORGANISATIONID IS NOT NULL
BEGIN
    SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records before ORGANISATIONID filter: ' + CAST(@DebugCount AS VARCHAR(10))
    
    DELETE FROM #TEMPLISTTABLE 
    WHERE SERIALNUMBER NOT IN (
        SELECT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        WHERE V.ORGANIZATIONID = @ORGANISATIONID
    )
    
    SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records after ORGANISATIONID filter: ' + CAST(@DebugCount AS VARCHAR(10))
END

-- After ISLICENSEEXPIRY filter:
IF @ISLICENSEEXPIRY IS NOT NULL
BEGIN
    SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records before ISLICENSEEXPIRY filter: ' + CAST(@DebugCount AS VARCHAR(10))
    
    -- ... filter logic ...
    
    SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
    PRINT 'Records after ISLICENSEEXPIRY filter: ' + CAST(@DebugCount AS VARCHAR(10))
END

-- Before pagination:
SELECT @DebugCount = COUNT(*) FROM #TEMPLISTTABLE
PRINT 'Records before pagination: ' + CAST(@DebugCount AS VARCHAR(10))
*/

-- =====================================================
-- MOST LIKELY CAUSE ANALYSIS
-- =====================================================

/*
🎯 MOST LIKELY CAUSES OF THE 17 MISSING RECORDS:

1. **ORGANISATIONID FILTER** (Most Likely)
   - The organization filter is removing products that belong to the user
   - But are associated with different organizations in the vCUSTOMER table
   - Some products might be shared across organizations

2. **ISPRODUCTGROUPTABLENEEDED='NO'**
   - This might change the data population logic
   - Compare with 'YES' to see if it affects record count

3. **SOURCE='RESTAPI'**
   - This parameter might trigger different logic paths
   - Compare with empty/NULL value

4. **DATA INCONSISTENCY**
   - User has products in CUSTOMERPRODUCTSSUMMARY
   - But not all are linked properly in vCUSTOMER view
   - Or some products belong to multiple organizations

🔧 IMMEDIATE ACTIONS:

1. Run the incremental tests above to identify which parameter causes the drop
2. Check the organization membership of the missing 17 products
3. Verify if the user belongs to multiple organizations
4. Consider if the organization filter should be modified or made optional
*/