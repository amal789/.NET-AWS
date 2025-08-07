-- Debug script to identify the 17 missing records between old and new stored procedures
-- This script helps you understand which records are being filtered out by the @ORGANISATIONID parameter

-- Step 1: Test the old stored procedure (should return 2536 records)
PRINT '=== Testing Original Stored Procedure ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDER]
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
    @SOURCE='RESTAPI',
    @SEARCHSERIALNUMBER='',
    @ISPRODUCTGROUPTABLENEEDED='NO'

-- Step 2: Test the new stored procedure WITHOUT organization filter (should return 2536 records)
PRINT '=== Testing New Stored Procedure WITHOUT @ORGANISATIONID Filter ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=NULL,        -- NULL = no organization filtering
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

-- Step 3: Test the new stored procedure WITH organization filter (should return 2519 records)
PRINT '=== Testing New Stored Procedure WITH @ORGANISATIONID=1873731 Filter ==='
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=1873731,     -- This filter is causing the 17 missing records
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

-- Step 4: Analyze which products are being filtered out by the organization filter
PRINT '=== Finding the 17 Missing Records ==='

-- Create temporary table to store results from procedure without org filter
CREATE TABLE #WithoutOrgFilter (
    SERIALNUMBER VARCHAR(30),
    PRODUCTNAME NVARCHAR(255),
    PRODUCTGROUPNAME NVARCHAR(510),
    -- Add other key fields you want to analyze
    PRODUCTID INT
)

-- Create temporary table to store results from procedure with org filter  
CREATE TABLE #WithOrgFilter (
    SERIALNUMBER VARCHAR(30),
    PRODUCTNAME NVARCHAR(255),
    PRODUCTGROUPNAME NVARCHAR(510),
    PRODUCTID INT
)

-- You would need to manually populate these tables by running the procedures
-- and inserting the results, then run this query:

/*
-- Find records that exist without org filter but not with org filter
SELECT 
    W.SERIALNUMBER,
    W.PRODUCTNAME,
    W.PRODUCTGROUPNAME,
    W.PRODUCTID,
    'FILTERED OUT BY ORGANIZATION' as Reason
FROM #WithoutOrgFilter W
LEFT JOIN #WithOrgFilter O ON W.SERIALNUMBER = O.SERIALNUMBER
WHERE O.SERIALNUMBER IS NULL

-- Check organization associations for the missing products
SELECT DISTINCT
    CP.SERIALNUMBER,
    CP.PRODUCTNAME,
    V.ORGANIZATIONID,
    V.USERNAME,
    O.ORGANIZATIONNAME,
    'User Organization' as Association_Type
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME  
INNER JOIN ORGANIZATION O WITH (NOLOCK) ON V.ORGANIZATIONID = O.ORGANIZATIONID
WHERE CP.SERIALNUMBER IN (
    SELECT W.SERIALNUMBER 
    FROM #WithoutOrgFilter W
    LEFT JOIN #WithOrgFilter O ON W.SERIALNUMBER = O.SERIALNUMBER
    WHERE O.SERIALNUMBER IS NULL
)
AND CP.USEDSTATUS = 1

UNION

SELECT DISTINCT
    PTGD.SERIALNUMBER,
    CP.PRODUCTNAME,
    P.ORGANIZATIONID,
    PTG.PRODUCTGROUPNAME as USERNAME,
    O.ORGANIZATIONNAME,
    'Tenant Organization' as Association_Type  
FROM PRODUCTGROUPDETAIL PTGD WITH (NOLOCK)
INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
INNER JOIN ORGANIZATION O WITH (NOLOCK) ON P.ORGANIZATIONID = O.ORGANIZATIONID
INNER JOIN CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK) ON PTGD.SERIALNUMBER = CP.SERIALNUMBER
WHERE PTGD.SERIALNUMBER IN (
    SELECT W.SERIALNUMBER 
    FROM #WithoutOrgFilter W
    LEFT JOIN #WithOrgFilter O ON W.SERIALNUMBER = O.SERIALNUMBER
    WHERE O.SERIALNUMBER IS NULL
)
ORDER BY SERIALNUMBER, Association_Type
*/

DROP TABLE #WithoutOrgFilter
DROP TABLE #WithOrgFilter

-- Recommendation:
PRINT '=== RECOMMENDATION ==='
PRINT 'To get the same 2536 records as the original stored procedure:'
PRINT '1. Set @ORGANISATIONID=NULL in your execution command'
PRINT '2. OR remove the @ORGANISATIONID parameter entirely'
PRINT '3. The @ORGANISATIONID filter is NEW and does not exist in the original SP'