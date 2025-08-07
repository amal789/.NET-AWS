-- =====================================================
-- QUICK FIX FOR MISSING RECORDS (2536 vs 2519 = 17 missing)
-- =====================================================

-- 🎯 MOST LIKELY CAUSE: The ORGANISATIONID filter is too restrictive

-- =====================================================
-- STEP 1: QUICK DIAGNOSIS (Run this first)
-- =====================================================

-- Test A: Original query (should return 2536)
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

-- Test B: With ORGANISATIONID (probably returns 2519)
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

-- =====================================================
-- STEP 2: FIND THE MISSING 17 RECORDS
-- =====================================================

-- Check user's organization memberships
SELECT DISTINCT 
    V.ORGANIZATIONID,
    V.ORGANIZATIONNAME,
    COUNT(CP.SERIALNUMBER) AS ProductCount
FROM vCUSTOMER V WITH (NOLOCK)
INNER JOIN CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE V.USERNAME = '4_37687189'
GROUP BY V.ORGANIZATIONID, V.ORGANIZATIONNAME
ORDER BY ProductCount DESC;

-- Find products that would be filtered out by organization ID 1873731
SELECT 
    CP.SERIALNUMBER,
    CP.NAME AS ProductFriendlyName,
    CP.PRODUCTNAME,
    V.ORGANIZATIONID,
    V.ORGANIZATIONNAME
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
LEFT JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
WHERE CP.USERNAME = '4_37687189'
AND (V.ORGANIZATIONID != 1873731 OR V.ORGANIZATIONID IS NULL)
ORDER BY CP.SERIALNUMBER;

-- This should show you the 17 missing products and their organizations

-- =====================================================
-- STEP 3: IMMEDIATE FIX OPTIONS
-- =====================================================

-- Option 1: Remove ORGANISATIONID filter (get all user's products)
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=NULL,  -- Remove organization filter
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
    @SEARCHSERIALNUMBER='';

-- This should return all 2536 records

-- =====================================================
-- STEP 4: MODIFIED ORGANIZATION FILTER (Better Fix)
-- =====================================================

-- The current filter logic is too restrictive:
/*
DELETE FROM #TEMPLISTTABLE 
WHERE SERIALNUMBER NOT IN (
    SELECT CP.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
    INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
    WHERE V.ORGANIZATIONID = @ORGANISATIONID
)
*/

-- PROBLEM: This only keeps products where the user's organization matches exactly
-- But users might have products from multiple organizations

-- BETTER APPROACH: Modify the stored procedure to use this logic instead:

/*
-- Option A: Include products from user's primary organization + user's own products
IF @ORGANISATIONID IS NOT NULL
BEGIN
    DELETE FROM #TEMPLISTTABLE 
    WHERE SERIALNUMBER NOT IN (
        -- Keep products from the specified organization
        SELECT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        WHERE V.ORGANIZATIONID = @ORGANISATIONID
        
        UNION
        
        -- Also keep all products owned by this specific user
        SELECT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        WHERE CP.USERNAME = @USERNAME
    )
END
*/

-- =====================================================
-- STEP 5: TEMPORARY STORED PROCEDURE MODIFICATION
-- =====================================================

-- Modify your stored procedure's organization filter section from:
/*
-- CURRENT (RESTRICTIVE):
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

-- TO THIS (INCLUSIVE):
/*
IF @ORGANISATIONID IS NOT NULL
BEGIN
    DELETE FROM #TEMPLISTTABLE 
    WHERE SERIALNUMBER NOT IN (
        -- Products from specified organization
        SELECT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        WHERE V.ORGANIZATIONID = @ORGANISATIONID
        
        UNION
        
        -- User's own products (regardless of organization)
        SELECT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        WHERE CP.USERNAME = @USERNAME
    )
END
*/

-- =====================================================
-- STEP 6: TEST THE MODIFIED LOGIC
-- =====================================================

-- Test the improved organization filter logic:
SELECT COUNT(DISTINCT CP.SERIALNUMBER) AS TotalProductsWithImprovedFilter
FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
WHERE CP.SERIALNUMBER IN (
    -- Products from specified organization
    SELECT CP2.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP2 WITH (NOLOCK)
    INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP2.USERNAME = V.USERNAME
    WHERE V.ORGANIZATIONID = 1873731
    
    UNION
    
    -- User's own products (regardless of organization)
    SELECT CP3.SERIALNUMBER 
    FROM CUSTOMERPRODUCTSSUMMARY CP3 WITH (NOLOCK)
    WHERE CP3.USERNAME = '4_37687189'
);

-- This should give you 2536 products (or close to it)

-- =====================================================
-- STEP 7: BUSINESS LOGIC CLARIFICATION
-- =====================================================

/*
🤔 BUSINESS QUESTION: What should the ORGANISATIONID filter actually do?

Option A: RESTRICTIVE (Current implementation)
- Only show products where user's organization = specified organization
- PROBLEM: Users lose access to their own products from other orgs

Option B: INCLUSIVE (Recommended)
- Show products from specified organization + user's own products
- BENEFIT: Users keep access to all their products

Option C: HYBRID  
- Primary filter by organization
- But include user's "personally owned" products
- Most flexible approach

Option D: CONDITIONAL
- If user belongs to the specified organization: show all user's products
- If user doesn't belong: show only organization products (shared products)
*/

-- =====================================================
-- IMMEDIATE WORKAROUND
-- =====================================================

-- Until you can modify the stored procedure, use this:
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @SOURCE='RESTAPI',
    @ISPRODUCTGROUPTABLENEEDED='NO',
    @ORGANISATIONID=NULL,              -- ← Remove this filter temporarily
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
    @SEARCHSERIALNUMBER='';

-- This should restore your 2536 records

-- Then apply organization filtering in your C# code if needed:
/*
var allProducts = GetProductsFromStoredProcedure();
var orgFilteredProducts = allProducts.Where(p => 
    p.organizationId == organizationID || 
    p.username == currentUsername
).ToList();
*/