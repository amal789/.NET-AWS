-- ============================================================================
-- FIX FOR ORGANIZATION FILTER TO RESOLVE MISSING 17 RECORDS
-- ============================================================================
-- Problem: The current @ORGANISATIONID filter is too restrictive and excludes
-- 17 records that should be included based on the original procedure logic.
-- 
-- Solution: Make the organization filter more inclusive to match the original
-- procedure's behavior while still providing the filtering capability.
-- ============================================================================

-- CURRENT PROBLEMATIC LOGIC (Lines 2606-2650 in GETASSOCIATEDPRODUCTSWITHORDERLIST.sql)
-- ============================================================================
/*
    IF @ORGANISATIONID IS NOT NULL
    BEGIN
        DELETE FROM #TEMPLISTTABLE 
        WHERE SERIALNUMBER NOT IN (
            -- Products owned by users in the specified organization
            SELECT DISTINCT CP.SERIALNUMBER 
            FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
            INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
            WHERE V.ORGANIZATIONID = @ORGANISATIONID
              AND CP.USEDSTATUS = 1
            
            UNION
            
            -- Products directly accessible to the current user (preserves shared/transferred products)
            SELECT DISTINCT CP.SERIALNUMBER 
            FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
            WHERE CP.USERNAME = @USERNAME
              AND CP.USEDSTATUS = 1
            
            UNION
            
            -- Products accessible through shared tenants/product groups in the organization
            SELECT DISTINCT PTGD.SERIALNUMBER
            FROM PRODUCTGROUPDETAIL PTGD WITH (NOLOCK)
            INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
            INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
            WHERE P.ORGANIZATIONID = @ORGANISATIONID
              AND PTGD.SERIALNUMBER IS NOT NULL
            
            UNION
            
            -- Products in shared tenants that current user has explicit access to via #tempPRGD
            -- This preserves the original SP's comprehensive tenant access logic
            SELECT DISTINCT PTGD.SERIALNUMBER
            FROM #tempPRGD PTGD WITH (NOLOCK)
            INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
            INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
            WHERE (P.ORGANIZATIONID = @ORGANISATIONID OR PTGD.ORGANIZATIONID = @ORGANISATIONID)
              AND PTGD.SERIALNUMBER IS NOT NULL
        )
    END
*/

-- ============================================================================
-- ENHANCED ORGANIZATION FILTER (RECOMMENDED REPLACEMENT)
-- ============================================================================
-- Replace the existing organization filter logic with this more inclusive version:

IF @ORGANISATIONID IS NOT NULL
BEGIN
    DELETE FROM #TEMPLISTTABLE 
    WHERE SERIALNUMBER NOT IN (
        -- 1. Products owned by users in the specified organization
        SELECT DISTINCT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        WHERE V.ORGANIZATIONID = @ORGANISATIONID
          AND CP.USEDSTATUS = 1
        
        UNION
        
        -- 2. Products directly accessible to the current user (ALWAYS INCLUDE)
        -- This ensures we don't lose the user's direct product access
        SELECT DISTINCT CP.SERIALNUMBER 
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        WHERE CP.USERNAME = @USERNAME
          AND CP.USEDSTATUS = 1
        
        UNION
        
        -- 3. Products accessible through shared tenants/product groups in the organization
        SELECT DISTINCT PTGD.SERIALNUMBER
        FROM PRODUCTGROUPDETAIL PTGD WITH (NOLOCK)
        INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
        INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
        WHERE P.ORGANIZATIONID = @ORGANISATIONID
          AND PTGD.SERIALNUMBER IS NOT NULL
        
        UNION
        
        -- 4. Products in shared tenants that current user has explicit access to via #tempPRGD
        SELECT DISTINCT PTGD.SERIALNUMBER
        FROM #tempPRGD PTGD WITH (NOLOCK)
        INNER JOIN PRODUCTGROUP PTG WITH (NOLOCK) ON PTGD.PRODUCTGROUPID = PTG.PRODUCTGROUPID
        INNER JOIN PARTY P WITH (NOLOCK) ON PTG.ADMINPARTYID = P.PARTYID
        WHERE (P.ORGANIZATIONID = @ORGANISATIONID OR PTGD.ORGANIZATIONID = @ORGANISATIONID)
          AND PTGD.SERIALNUMBER IS NOT NULL
        
        UNION
        
        -- 5. NEW: Products from MSSP relationships (Master-Child organization relationships)
        SELECT DISTINCT CP.SERIALNUMBER
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        INNER JOIN MASTERMSSP MM WITH (NOLOCK) ON (
            V.ORGANIZATIONID = MM.MASTERORGANIZATIONID OR 
            V.ORGANIZATIONID = MM.MSSPORGANIZATIONID
        )
        WHERE (MM.MASTERORGANIZATIONID = @ORGANISATIONID OR MM.MSSPORGANIZATIONID = @ORGANISATIONID)
          AND CP.USEDSTATUS = 1
        
        UNION
        
        -- 6. NEW: Products from cross-organizational tenant sharing
        -- Include products where user has tenant access regardless of org boundaries
        SELECT DISTINCT PTGD.SERIALNUMBER
        FROM #tempPRGD PTGD WITH (NOLOCK)
        WHERE PTGD.CONTACTID = @CONTACTID
          AND PTGD.SERIALNUMBER IS NOT NULL
        
        UNION
        
        -- 7. NEW: Products from organizational affiliations or co-management
        SELECT DISTINCT CP.SERIALNUMBER
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN PRODUCTGROUPDETAIL PGD WITH (NOLOCK) ON CP.SERIALNUMBER = PGD.SERIALNUMBER
        INNER JOIN PARTYPRODUCTGROUP PPG WITH (NOLOCK) ON PGD.PRODUCTGROUPID = PPG.PRODUCTGROUPID
        INNER JOIN PARTYGROUPDETAIL PRGD WITH (NOLOCK) ON PPG.PARTYGROUPID = PRGD.PARTYGROUPID
        INNER JOIN PARTY P WITH (NOLOCK) ON PRGD.PARTYID = P.PARTYID
        WHERE P.CONTACTID = @CONTACTID
          AND CP.USEDSTATUS = 1
          AND PPG.PERMISSIONTYPEID IS NOT NULL  -- Has some level of access
        
        UNION
        
        -- 8. NEW: Products where the user has org-based account access
        -- When @ORGBASEDASSETOWNSERSHIPENABLED = 'YES' and user has org-based account
        SELECT DISTINCT CP.SERIALNUMBER
        FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
        INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
        WHERE V.ORGANIZATIONID = @ORGANISATIONID
          AND CP.USEDSTATUS = 1
          AND EXISTS (
              SELECT 1 FROM vCUSTOMER VC WITH (NOLOCK) 
              WHERE VC.USERNAME = @USERNAME 
                AND VC.ORGBASEDACCOUNT = 'YES'
          )
    )
END

-- ============================================================================
-- ALTERNATIVE SIMPLIFIED FIX (If the above is too complex)
-- ============================================================================
-- If the comprehensive fix above causes performance issues, use this simpler version:

/*
IF @ORGANISATIONID IS NOT NULL
BEGIN
    -- Store current user's organization for comparison
    DECLARE @CurrentUserOrgId BIGINT
    SELECT @CurrentUserOrgId = ORGANIZATIONID 
    FROM vCUSTOMER WITH (NOLOCK) 
    WHERE USERNAME = @USERNAME
    
    -- Only apply organization filter if the user is NOT from the target organization
    -- This preserves all records for users within their own organization
    IF @CurrentUserOrgId != @ORGANISATIONID
    BEGIN
        DELETE FROM #TEMPLISTTABLE 
        WHERE SERIALNUMBER NOT IN (
            -- Products owned by users in the specified organization
            SELECT DISTINCT CP.SERIALNUMBER 
            FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
            INNER JOIN vCUSTOMER V WITH (NOLOCK) ON CP.USERNAME = V.USERNAME
            WHERE V.ORGANIZATIONID = @ORGANISATIONID
              AND CP.USEDSTATUS = 1
            
            UNION
            
            -- Always include current user's products
            SELECT DISTINCT CP.SERIALNUMBER 
            FROM CUSTOMERPRODUCTSSUMMARY CP WITH (NOLOCK)
            WHERE CP.USERNAME = @USERNAME
              AND CP.USEDSTATUS = 1
        )
    END
    -- If user is from the target organization, don't filter anything
END
*/

-- ============================================================================
-- DEBUGGING/BYPASS OPTION (Temporary)
-- ============================================================================
-- Add this parameter to the stored procedure definition for testing:
-- @DISABLE_ORG_FILTER BIT = 0

-- Then modify the filter logic:
/*
IF @ORGANISATIONID IS NOT NULL AND @DISABLE_ORG_FILTER = 0
BEGIN
    -- Organization filtering logic here
END
*/

-- ============================================================================
-- IMPLEMENTATION STEPS
-- ============================================================================
-- 1. Test the current procedure with @ORGANISATIONID = NULL to confirm 2536 records
-- 2. Run the debugging queries to identify the exact 17 missing records
-- 3. Implement the enhanced organization filter above
-- 4. Test with the user's parameters to verify 2536 records are returned
-- 5. Validate that filtering still works correctly for other scenarios

-- ============================================================================
-- PERFORMANCE CONSIDERATIONS
-- ============================================================================
-- The enhanced filter includes more UNION clauses which may impact performance.
-- Consider adding these optimizations:

-- 1. Add indexes if they don't exist:
/*
CREATE NONCLUSTERED INDEX IX_CUSTOMERPRODUCTSSUMMARY_USERNAME_USEDSTATUS 
ON CUSTOMERPRODUCTSSUMMARY (USERNAME, USEDSTATUS) 
INCLUDE (SERIALNUMBER)

CREATE NONCLUSTERED INDEX IX_vCUSTOMER_ORGANIZATIONID 
ON vCUSTOMER (ORGANIZATIONID) 
INCLUDE (USERNAME, CONTACTID)
*/

-- 2. Use EXISTS instead of IN for better performance in some cases
-- 3. Consider using DISTINCT only at the end rather than in each UNION

-- ============================================================================
-- VALIDATION QUERIES
-- ============================================================================
-- After implementing the fix, run these validation queries:

-- 1. Verify record count matches original
/*
SELECT COUNT(*) as RecordCount, 'Enhanced Filter' as FilterType
FROM [Results of enhanced procedure]

UNION ALL

SELECT COUNT(*) as RecordCount, 'Original Procedure' as FilterType  
FROM [Results of original procedure]
*/

-- 2. Ensure no unauthorized access
/*
SELECT CP.SERIALNUMBER, CP.USERNAME, V.ORGANIZATIONID
FROM [Enhanced procedure results] CP
INNER JOIN vCUSTOMER V ON CP.USERNAME = V.USERNAME  
WHERE V.ORGANIZATIONID NOT IN (@ORGANISATIONID, @CurrentUserOrgId)
-- Should only show legitimately shared/accessible products
*/