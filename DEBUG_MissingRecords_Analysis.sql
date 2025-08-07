-- DEBUG: Analysis for Missing 17 Records
-- This script helps identify why GETASSOCIATEDPRODUCTSWITHORDERLIST returns 17 fewer records than GETASSOCIATEDPRODUCTSWITHORDER

-- Step 1: Execute both stored procedures and compare
-- Original SP returns 2536 records
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDER] 
    @USERNAME = N'4_37687189', 
    @ORDERNAME = 'REGISTEREDDATE', 
    @ORDERTYPE = '0', 
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
    @SOURCE = 'RESTAPI', 
    @SEARCHSERIALNUMBER = '', 
    @ISPRODUCTGROUPTABLENEEDED = 'NO'

-- Modified SP returns 2519 records when ORGANISATIONID filter is applied
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=1873731,        -- This is the problematic filter
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

-- Step 2: Test Modified SP WITHOUT ORGANISATIONID filter - should return 2536 records
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=NULL,           -- Remove the filter
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

-- Step 3: Find the 17 missing products
-- Query to identify which products are being filtered out by the ORGANISATIONID filter
SELECT 
    'MISSING_PRODUCTS' as RecordType,
    COUNT(*) as MissingCount,
    'Products owned by users NOT in organization 1873731' as Reason
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
WHERE CP.USERNAME = '4_37687189'
  AND CP.USEDSTATUS = 1
  AND CP.SERIALNUMBER NOT IN (
      SELECT CP2.SERIALNUMBER 
      FROM CUSTOMERPRODUCTSSUMMARY CP2 WITH (NOLOCK)
      INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP2.USERNAME = V.USERNAME
      WHERE V.ORGANIZATIONID = 1873731
        AND CP2.USERNAME = '4_37687189'
        AND CP2.USEDSTATUS = 1
  )

-- Step 4: Detailed analysis - Show which users/organizations own the missing products
SELECT DISTINCT
    'OWNERSHIP_ANALYSIS' as RecordType,
    CP.USERNAME,
    V.ORGANIZATIONID,
    O.ORGANIZATIONNAME,
    COUNT(CP.SERIALNUMBER) as ProductCount
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
LEFT JOIN ORGANIZATION O WITH (NOLOCK) ON V.ORGANIZATIONID = O.ORGANIZATIONID
WHERE CP.SERIALNUMBER IN (
    -- Get all products for user 4_37687189
    SELECT SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY WITH (NOLOCK) 
    WHERE USERNAME = '4_37687189' AND USEDSTATUS = 1
)
AND CP.USEDSTATUS = 1
GROUP BY CP.USERNAME, V.ORGANIZATIONID, O.ORGANIZATIONNAME
ORDER BY ProductCount DESC

-- Step 5: Check if user 4_37687189 belongs to organization 1873731
SELECT 
    'USER_ORG_CHECK' as RecordType,
    USERNAME,
    ORGANIZATIONID,
    'User organization membership' as Description
FROM vCUSTOMER WITH (NOLOCK)
WHERE USERNAME = '4_37687189'

-- Step 6: Find products that belong to shared/different organizations
SELECT 
    'SHARED_PRODUCTS' as RecordType,
    CP.SERIALNUMBER,
    CP.USERNAME as ProductOwner,
    V.ORGANIZATIONID as OwnerOrgID,
    O.ORGANIZATIONNAME as OwnerOrgName,
    CP.PRODUCTFAMILY,
    CP.PRODUCTLINE
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
LEFT JOIN ORGANIZATION O WITH (NOLOCK) ON V.ORGANIZATIONID = O.ORGANIZATIONID
WHERE CP.SERIALNUMBER IN (
    SELECT SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY WITH (NOLOCK) 
    WHERE USERNAME = '4_37687189' AND USEDSTATUS = 1
)
AND CP.USEDSTATUS = 1
AND V.ORGANIZATIONID != 1873731  -- Products from different organizations
ORDER BY V.ORGANIZATIONID, CP.SERIALNUMBER

/*
EXPECTED FINDINGS:
1. The 17 missing records are products that are accessible to user '4_37687189' 
   but are owned by users from organizations other than 1873731
2. These could be:
   - Shared products from partner organizations
   - Products transferred from other organizations
   - Products with special sharing arrangements
   - Multi-organization product access scenarios

SOLUTION:
Remove or modify the ORGANISATIONID filter to be more inclusive, 
or make it optional and default to NULL to maintain original behavior.
*/