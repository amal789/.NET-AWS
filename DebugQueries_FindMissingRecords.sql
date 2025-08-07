-- ============================================================================
-- DEBUG QUERIES TO FIND THE 17 MISSING RECORDS
-- Between GETASSOCIATEDPRODUCTSWITHORDER (2536) and GETASSOCIATEDPRODUCTSWITHORDERLIST (2519)
-- ============================================================================

-- STEP 1: Test the modified procedure without the new filters
-- This should return 2536 records if the organization filter is the culprit
-- ============================================================================
PRINT 'STEP 1: Testing modified procedure without new filters...'

EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
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
    @ISPRODUCTGROUPTABLENEEDED = 'NO',
    @ORGANISATIONID = NULL,        -- REMOVE ORG FILTER
    @ISLICENSEEXPIRY = NULL,       -- REMOVE LICENSE FILTER
    @QUERYSTR = NULL,              -- REMOVE SEARCH FILTER
    @PAGENO = 1,
    @PAGESIZE = 5000,
    @MINCOUNT = NULL,              -- REMOVE MIN COUNT
    @MAXCOUNT = NULL               -- REMOVE MAX COUNT

-- Expected: Should return 2536 records if org filter is the issue

-- ============================================================================
-- STEP 2: Test with only organization filter applied
-- ============================================================================
PRINT 'STEP 2: Testing with only organization filter...'

EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST] 
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
    @ISPRODUCTGROUPTABLENEEDED = 'NO',
    @ORGANISATIONID = 1873731,    -- KEEP ORG FILTER
    @ISLICENSEEXPIRY = NULL,      -- REMOVE LICENSE FILTER
    @QUERYSTR = NULL,             -- REMOVE SEARCH FILTER
    @PAGENO = 1,
    @PAGESIZE = 5000,
    @MINCOUNT = NULL,             -- REMOVE MIN COUNT
    @MAXCOUNT = NULL              -- REMOVE MAX COUNT

-- Expected: Should return 2519 records if org filter is the only issue

-- ============================================================================
-- STEP 3: Direct query to find products for the user
-- ============================================================================
PRINT 'STEP 3: Finding all products directly accessible to user...'

SELECT 
    COUNT(*) as TotalUserProducts,
    COUNT(CASE WHEN V.ORGANIZATIONID = 1873731 THEN 1 END) as ProductsInTargetOrg,
    COUNT(CASE WHEN V.ORGANIZATIONID != 1873731 OR V.ORGANIZATIONID IS NULL THEN 1 END) as ProductsOutsideTargetOrg
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
LEFT JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE CP.USERNAME = '4_37687189'
  AND CP.USEDSTATUS = 1
  AND CP.PRODUCTFAMILY NOT IN ('CLIENTLICENSE','FLEXSPEND')
  AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE')

-- ============================================================================
-- STEP 4: Find the organization relationships for the user
-- ============================================================================
PRINT 'STEP 4: Checking user organization relationships...'

SELECT 
    VC.USERNAME,
    VC.ORGANIZATIONID as UserOrgId,
    VC.CONTACTID,
    O.ORGANIZATIONNAME as UserOrgName,
    VC.ISORGADMIN,
    VC.ORGBASEDACCOUNT
FROM vCUSTOMER VC WITH (NOLOCK)
INNER JOIN ORGANIZATION O WITH (NOLOCK) ON VC.ORGANIZATIONID = O.ORGANIZATIONID
WHERE VC.USERNAME = '4_37687189'

-- ============================================================================
-- STEP 5: Check for MSSP relationships
-- ============================================================================
PRINT 'STEP 5: Checking MSSP relationships...'

SELECT 
    MM.MASTERMSSPID,
    MM.MSSPNAME,
    MM.MASTERORGANIZATIONID,
    MM.MSSPORGANIZATIONID,
    MO.ORGANIZATIONNAME as MasterOrgName,
    SO.ORGANIZATIONNAME as MSSPOrgName
FROM MASTERMSSP MM WITH (NOLOCK)
LEFT JOIN ORGANIZATION MO WITH (NOLOCK) ON MM.MASTERORGANIZATIONID = MO.ORGANIZATIONID
LEFT JOIN ORGANIZATION SO WITH (NOLOCK) ON MM.MSSPORGANIZATIONID = SO.ORGANIZATIONID
WHERE MM.MASTERORGANIZATIONID = 1873731 
   OR MM.MSSPORGANIZATIONID = 1873731

-- ============================================================================
-- STEP 6: Comprehensive query to identify the missing 17 products
-- ============================================================================
PRINT 'STEP 6: Finding products that should be included but are filtered out...'

-- Products accessible via the old procedure logic
WITH OldProcedureProducts AS (
    SELECT DISTINCT CP.SERIALNUMBER
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    WHERE CP.USERNAME = '4_37687189'
      AND CP.USEDSTATUS = 1
      AND CP.PRODUCTFAMILY NOT IN ('CLIENTLICENSE','FLEXSPEND')
      AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE')
    
    UNION
    
    -- Products from shared tenants (simplified from #tempPRGD logic)
    SELECT DISTINCT PTGD.SERIALNUMBER
    FROM PARTYGROUP PG WITH (NOLOCK)
    INNER JOIN PARTYGROUPDETAIL PGD WITH (NOLOCK) ON PG.PARTYGROUPID = PGD.PARTYGROUPID
    INNER JOIN PARTYPRODUCTGROUP PPG WITH (NOLOCK) ON PPG.PARTYGROUPID = PG.PARTYGROUPID
    INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PPG.PRODUCTGROUPID = PTG.PRODUCTGROUPID
    INNER JOIN PRODUCTGROUPDETAIL PTGD WITH (NOLOCK) ON PTG.PRODUCTGROUPID = PTGD.PRODUCTGROUPID
    INNER JOIN PARTY P WITH (NOLOCK) ON P.PARTYID = PGD.PARTYID
    INNER JOIN vCUSTOMER VC WITH (NOLOCK) ON VC.CONTACTID = P.CONTACTID
    WHERE VC.USERNAME = '4_37687189'
      AND PTGD.SERIALNUMBER IS NOT NULL
),

-- Products that pass the new organization filter
NewProcedureProducts AS (
    SELECT DISTINCT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
    WHERE V.ORGANIZATIONID = 1873731
      AND CP.USEDSTATUS = 1
    
    UNION
    
    SELECT DISTINCT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    WHERE CP.USERNAME = '4_37687189'
      AND CP.USEDSTATUS = 1
    
    UNION
    
    SELECT DISTINCT PTGD.SERIALNUMBER
    FROM PRODUCTGROUPDETAIL PTGD WITH (NOLOCK)
    INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
    INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
    WHERE P.ORGANIZATIONID = 1873731
      AND PTGD.SERIALNUMBER IS NOT NULL
)

-- Find the difference
SELECT 
    OP.SERIALNUMBER as MissingSerialNumber,
    CP.USERNAME,
    CP.PRODUCTNAME,
    CP.PRODUCTGROUPNAME,
    V.ORGANIZATIONID as ProductOwnerOrgId,
    O.ORGANIZATIONNAME as ProductOwnerOrgName,
    CP.CREATEDDATE as RegistrationDate
FROM OldProcedureProducts OP
LEFT JOIN NewProcedureProducts NP ON OP.SERIALNUMBER = NP.SERIALNUMBER
INNER JOIN CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK) ON OP.SERIALNUMBER = CP.SERIALNUMBER
LEFT JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
LEFT JOIN ORGANIZATION O WITH (NOLOCK) ON V.ORGANIZATIONID = O.ORGANIZATIONID
WHERE NP.SERIALNUMBER IS NULL
  AND CP.USEDSTATUS = 1
ORDER BY CP.CREATEDDATE DESC

-- This should show the 17 missing records with their details

-- ============================================================================
-- STEP 7: Summary query for verification
-- ============================================================================
PRINT 'STEP 7: Summary verification...'

SELECT 
    'Old Procedure Logic' as ProcedureType,
    COUNT(DISTINCT CP.SERIALNUMBER) as RecordCount
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
WHERE CP.USERNAME = '4_37687189'
  AND CP.USEDSTATUS = 1
  AND CP.PRODUCTFAMILY NOT IN ('CLIENTLICENSE','FLEXSPEND')
  AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE')

UNION ALL

SELECT 
    'New Procedure Org Filter' as ProcedureType,
    COUNT(DISTINCT FilteredProducts.SERIALNUMBER) as RecordCount
FROM (
    SELECT DISTINCT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
    WHERE V.ORGANIZATIONID = 1873731
      AND CP.USEDSTATUS = 1
      AND CP.PRODUCTFAMILY NOT IN ('CLIENTLICENSE','FLEXSPEND')
      AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE')
    
    UNION
    
    SELECT DISTINCT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    WHERE CP.USERNAME = '4_37687189'
      AND CP.USEDSTATUS = 1
      AND CP.PRODUCTFAMILY NOT IN ('CLIENTLICENSE','FLEXSPEND')
      AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE')
) FilteredProducts

-- ============================================================================
-- Expected Results:
-- Step 1: Should return 2536 records (same as old procedure)
-- Step 2: Should return 2519 records (confirms org filter issue)
-- Step 6: Should show exactly 17 missing records with their details
-- Step 7: Should show the count difference (2536 vs 2519 = 17)
-- ============================================================================