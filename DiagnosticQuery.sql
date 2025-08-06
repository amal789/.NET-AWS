-- ===============================================
-- DIAGNOSTIC QUERY FOR STORED PROCEDURE ISSUE
-- Run this to identify why no data is returned
-- ===============================================

-- Step 1: Check if stored procedure has new parameters
SELECT 
    'Parameter Check' as CheckType,
    p.parameter_name,
    p.data_type,
    p.max_length,
    p.is_output
FROM sys.parameters p
INNER JOIN sys.objects o ON p.object_id = o.object_id
WHERE o.name = 'GETASSOCIATEDPRODUCTSWITHORDERLIST'
  AND p.parameter_name IN ('@ORGANISATIONID', '@ISLICENSEEXPIRY', '@PAGENO', '@PAGESIZE', '@MINCOUNT', '@MAXCOUNT')
ORDER BY p.parameter_id;

-- If the above returns 0 rows, your stored procedure wasn't updated properly

-- Step 2: Test stored procedure with minimal parameters
PRINT 'Testing stored procedure with minimal parameters...';

EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'test_user',           -- Replace with actual username
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @ASSOCTYPEID = 0,
    @ASSOCTYPE = '',
    @SERIALNUMBER = '',
    @LANGUAGECODE = 'EN',
    @SESSIONID = 'test_session',       -- Replace with actual session
    @PRODUCTLIST = NULL,
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0,                 -- CRITICAL: Must be 0 to return data
    @CallFrom = NULL,
    @IsMobile = 'NO',
    @SOURCE = '',
    @SEARCHSERIALNUMBER = '',
    @ISPRODUCTGROUPTABLENEEDED = 'YES',
    -- New parameters (set to NULL for testing)
    @ORGANISATIONID = NULL,
    @ISLICENSEEXPIRY = NULL,
    @PAGENO = 1,
    @PAGESIZE = 50,
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL;

-- Step 3: Check if data exists for the user
PRINT 'Checking if data exists for user...';

SELECT 
    'Data Check' as CheckType,
    COUNT(*) as RecordCount,
    'CUSTOMERPRODUCTSSUMMARY' as TableName
FROM CUSTOMERPRODUCTSSUMMARY 
WHERE USERNAME = 'test_user';  -- Replace with actual username

-- Step 4: Check user organization access
PRINT 'Checking user organization access...';

SELECT 
    'User Check' as CheckType,
    USERNAME,
    ORGANIZATIONID,
    CONTACTID
FROM vCUSTOMER 
WHERE USERNAME = 'test_user';  -- Replace with actual username

-- Step 5: Test original stored procedure call (without new parameters)
PRINT 'Testing original stored procedure call...';

-- Comment out this section if your SP now requires all new parameters
/*
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'test_user',
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @LANGUAGECODE = 'EN',
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0;
*/

-- Step 6: Check stored procedure definition
PRINT 'Checking stored procedure definition...';

SELECT 
    'SP Definition Check' as CheckType,
    o.name as ProcedureName,
    o.create_date,
    o.modify_date,
    CASE 
        WHEN o.modify_date > DATEADD(day, -1, GETDATE()) THEN 'Recently Modified'
        WHEN o.modify_date > DATEADD(day, -7, GETDATE()) THEN 'Modified This Week'
        ELSE 'Old Modification'
    END as ModificationStatus
FROM sys.objects o
WHERE o.name = 'GETASSOCIATEDPRODUCTSWITHORDERLIST'
  AND o.type = 'P';

-- Step 7: Check for any blocking or lock issues
PRINT 'Checking for blocking issues...';

SELECT 
    'Blocking Check' as CheckType,
    session_id,
    blocking_session_id,
    wait_type,
    wait_time,
    command
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0
   OR session_id IN (
       SELECT DISTINCT blocking_session_id 
       FROM sys.dm_exec_requests 
       WHERE blocking_session_id > 0
   );

-- ===============================================
-- INSTRUCTIONS FOR TROUBLESHOOTING:
-- ===============================================

PRINT '
=== TROUBLESHOOTING INSTRUCTIONS ===

1. If Parameter Check returns 0 rows:
   - Your stored procedure was not updated with new parameters
   - Re-run the ALTER PROCEDURE script

2. If Data Check returns 0 rows:
   - No data exists for this user
   - Check with a different username that has data

3. If User Check returns 0 rows:
   - User does not exist in vCUSTOMER table
   - Check username spelling or use a valid user

4. If SP test returns "Commands executed successfully" but no data:
   - Check @OutformatXML parameter (must be 0)
   - Check if pagination is eliminating all records
   - Check if new filtering is too restrictive

5. If you get errors:
   - Check the exact error message
   - Verify all required parameters are provided
   - Check parameter data types match

Run this diagnostic and let me know the results!
';

-- ===============================================
-- SAMPLE WORKING CALL (Replace with your values)
-- ===============================================

/*
-- Example of a working call:
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'actual_username_here',
    @ORDERNAME = 'REGISTEREDDATE',
    @ORDERTYPE = 'DESC',
    @ASSOCTYPEID = 0,
    @ASSOCTYPE = '',
    @SERIALNUMBER = '',
    @LANGUAGECODE = 'EN',
    @SESSIONID = 'actual_session_here',
    @PRODUCTLIST = NULL,
    @OEMCODE = 'SNWL',
    @APPNAME = 'MSW',
    @OutformatXML = 0,
    @CallFrom = NULL,
    @IsMobile = 'NO',
    @SOURCE = '',
    @SEARCHSERIALNUMBER = '',
    @ISPRODUCTGROUPTABLENEEDED = 'YES',
    @ORGANISATIONID = NULL,
    @ISLICENSEEXPIRY = NULL,
    @PAGENO = 1,
    @PAGESIZE = 50,
    @MINCOUNT = NULL,
    @MAXCOUNT = NULL;
*/