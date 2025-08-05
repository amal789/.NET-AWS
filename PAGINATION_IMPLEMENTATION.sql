-- =====================================================
-- PAGINATION IMPLEMENTATION FOR GETASSOCIATEDPRODUCTSWITHORDERLIST
-- This script provides the pagination logic to be integrated into the main stored procedure
-- =====================================================

-- 1. PARAMETER ADDITIONS (Already added to main procedure)
-- @PAGENO INT = 1,                    -- Page number (1-based)
-- @PAGESIZE INT = 50,                 -- Number of records per page
-- @MINCOUNT INT = NULL,               -- Minimum record count filter
-- @MAXCOUNT INT = NULL                -- Maximum record count filter

-- 2. PARAMETER VALIDATION AND INITIALIZATION
DECLARE @ValidatedPageNo INT = ISNULL(@PAGENO, 1);
DECLARE @ValidatedPageSize INT = ISNULL(@PAGESIZE, 50);
DECLARE @Offset INT;
DECLARE @TotalRecords INT = 0;

-- Validate pagination parameters
IF @ValidatedPageNo <= 0 SET @ValidatedPageNo = 1;
IF @ValidatedPageSize <= 0 SET @ValidatedPageSize = 50;
IF @ValidatedPageSize > 1000 SET @ValidatedPageSize = 1000; -- Prevent excessive page sizes

-- Calculate offset
SET @Offset = (@ValidatedPageNo - 1) * @ValidatedPageSize;

-- 3. ENHANCED TEMPORARY TABLE WITH ROW NUMBERING
-- Add a computed column for row numbering to #TEMPLISTTABLE
ALTER TABLE #TEMPLISTTABLE ADD 
    ROWNUMBER BIGINT,
    TOTALCOUNT INT DEFAULT 0;

-- 4. COUNT TOTAL RECORDS BEFORE PAGINATION
SELECT @TotalRecords = COUNT(*) FROM #TEMPLISTTABLE;

-- Update total count in temp table for easy access
UPDATE #TEMPLISTTABLE SET TOTALCOUNT = @TotalRecords;

-- 5. APPLY ROW NUMBERING BASED ON ORDER CRITERIA
-- This replaces the existing ORDER BY logic throughout the procedure
WITH OrderedResults AS (
    SELECT *,
           ROW_NUMBER() OVER (
               ORDER BY 
                   CASE 
                       WHEN @ORDERNAME = 'SERIALNUMBER' AND @ORDERTYPE = '0' THEN SERIALNUMBER
                       WHEN @ORDERNAME = 'SERIALNUMBER' AND @ORDERTYPE = '1' THEN SERIALNUMBER
                   END DESC,
                   CASE 
                       WHEN @ORDERNAME = 'SERIALNUMBER' AND @ORDERTYPE = '1' THEN SERIALNUMBER
                   END ASC,
                   CASE 
                       WHEN @ORDERNAME = 'NAME' AND @ORDERTYPE = '0' THEN PRODUCTOWNER
                       WHEN @ORDERNAME = 'NAME' AND @ORDERTYPE = '1' THEN PRODUCTOWNER
                   END DESC,
                   CASE 
                       WHEN @ORDERNAME = 'NAME' AND @ORDERTYPE = '1' THEN PRODUCTOWNER
                   END ASC,
                   CASE 
                       WHEN @ORDERNAME = 'PRODUCTLINE' AND @ORDERTYPE = '0' THEN PRODUCTLINE
                       WHEN @ORDERNAME = 'PRODUCTLINE' AND @ORDERTYPE = '1' THEN PRODUCTLINE
                   END DESC,
                   CASE 
                       WHEN @ORDERNAME = 'PRODUCTLINE' AND @ORDERTYPE = '1' THEN PRODUCTLINE
                   END ASC,
                   CASE 
                       WHEN @ORDERNAME = 'REGISTEREDDATE' AND @ORDERTYPE = '0' THEN CID
                       WHEN @ORDERNAME = 'REGISTEREDDATE' AND @ORDERTYPE = '1' THEN CID
                   END DESC,
                   CASE 
                       WHEN @ORDERNAME = 'REGISTEREDDATE' AND @ORDERTYPE = '1' THEN CID
                   END ASC,
                   -- Default ordering
                   CID DESC
           ) as RowNum
    FROM #TEMPLISTTABLE
)
UPDATE t 
SET ROWNUMBER = o.RowNum
FROM #TEMPLISTTABLE t
INNER JOIN OrderedResults o ON t.CID = o.CID;

-- 6. APPLY PAGINATION FILTERS
-- Filter records based on pagination parameters
DELETE FROM #TEMPLISTTABLE 
WHERE ROWNUMBER <= @Offset 
   OR ROWNUMBER > (@Offset + @ValidatedPageSize);

-- 7. APPLY OPTIONAL COUNT FILTERS
IF @MINCOUNT IS NOT NULL
BEGIN
    DELETE FROM #TEMPLISTTABLE WHERE @TotalRecords < @MINCOUNT;
END

IF @MAXCOUNT IS NOT NULL
BEGIN
    DELETE FROM #TEMPLISTTABLE WHERE @TotalRecords > @MAXCOUNT;
END

-- 8. PAGINATION METADATA RESULT SET
-- This should be returned as an additional result set before the main results
IF @OutformatXML = 0
BEGIN
    -- Return pagination metadata for non-XML requests
    SELECT 
        @TotalRecords as TotalRecords,
        @ValidatedPageNo as CurrentPage,
        @ValidatedPageSize as PageSize,
        CEILING(CAST(@TotalRecords AS FLOAT) / @ValidatedPageSize) as TotalPages,
        CASE 
            WHEN @ValidatedPageNo > 1 THEN 1 
            ELSE 0 
        END as HasPreviousPage,
        CASE 
            WHEN @ValidatedPageNo < CEILING(CAST(@TotalRecords AS FLOAT) / @ValidatedPageSize) THEN 1 
            ELSE 0 
        END as HasNextPage,
        @Offset + 1 as FirstRecordOnPage,
        CASE 
            WHEN @Offset + @ValidatedPageSize > @TotalRecords THEN @TotalRecords
            ELSE @Offset + @ValidatedPageSize
        END as LastRecordOnPage;
END

-- 9. INTEGRATION POINTS IN MAIN PROCEDURE

-- Replace existing result sets with paginated versions:
-- Instead of: ORDER BY C.CREATEDDATE DESC
-- Use: ORDER BY T.ROWNUMBER ASC (since records are already ordered and filtered)

-- Example for the main SELECT statements:
/*
-- BEFORE:
SELECT DISTINCT TOP 10
    C.PRODUCTID,
    C.SERIALNUMBER,
    -- ... other columns
FROM CUSTOMERPRODUCTSSUMMARY C with (nolock)
INNER JOIN #TEMPLISTTABLE AS PRODUCT ON C.serialnumber=PRODUCT.serialnumber
ORDER BY C.CREATEDDATE DESC

-- AFTER:
SELECT DISTINCT
    C.PRODUCTID,
    C.SERIALNUMBER,
    -- ... other columns
    PRODUCT.ROWNUMBER,
    PRODUCT.TOTALCOUNT
FROM CUSTOMERPRODUCTSSUMMARY C with (nolock)
INNER JOIN #TEMPLISTTABLE AS PRODUCT ON C.serialnumber=PRODUCT.serialnumber
ORDER BY PRODUCT.ROWNUMBER ASC
*/

-- 10. PERFORMANCE OPTIMIZATION NOTES
-- 
-- - Remove all "TOP 10" limitations since pagination handles this
-- - Remove duplicate ORDER BY clauses throughout the procedure  
-- - Consider adding these indexes for better performance:
--   CREATE INDEX IDX_TEMPLISTTABLE_ROWNUMBER ON #TEMPLISTTABLE(ROWNUMBER);
--   CREATE INDEX IDX_TEMPLISTTABLE_SERIALNUMBER_ROWNUMBER ON #TEMPLISTTABLE(SERIALNUMBER, ROWNUMBER);

-- 11. ERROR HANDLING FOR PAGINATION
IF @TotalRecords = 0 AND @ValidatedPageNo > 1
BEGIN
    -- Return empty result set with pagination metadata indicating no results
    SELECT 
        0 as TotalRecords,
        @ValidatedPageNo as CurrentPage,
        @ValidatedPageSize as PageSize,
        0 as TotalPages,
        0 as HasPreviousPage,
        0 as HasNextPage,
        0 as FirstRecordOnPage,
        0 as LastRecordOnPage;
    RETURN;
END

-- 12. LOGGING AND MONITORING
-- Add this near the end of the procedure for performance tracking
DECLARE @EndTime DATETIME2 = GETDATE();
DECLARE @ExecutionTimeMs INT = DATEDIFF(millisecond, @StartTime, @EndTime);

-- Log pagination usage for monitoring
INSERT INTO PROCEDURE_PAGINATION_LOG (
    ProcedureName, 
    Username, 
    PageNumber, 
    PageSize, 
    TotalRecords, 
    ExecutionTimeMs, 
    LogDate
)
VALUES (
    'GETASSOCIATEDPRODUCTSWITHORDERLIST',
    @USERNAME,
    @ValidatedPageNo,
    @ValidatedPageSize,
    @TotalRecords,
    @ExecutionTimeMs,
    GETDATE()
);

-- =====================================================
-- INTEGRATION CHECKLIST:
-- =====================================================
-- [ ] 1. Add pagination parameters to procedure signature (COMPLETED)
-- [ ] 2. Add parameter validation section at beginning of procedure
-- [ ] 3. Modify #TEMPLISTTABLE creation to include ROWNUMBER and TOTALCOUNT columns
-- [ ] 4. Replace all "TOP 10" with pagination logic
-- [ ] 5. Update all ORDER BY clauses to use ROWNUMBER
-- [ ] 6. Add pagination metadata result set
-- [ ] 7. Add performance logging
-- [ ] 8. Test with various page sizes and parameter combinations
-- [ ] 9. Update calling applications to handle pagination metadata
-- [ ] 10. Monitor performance impact and adjust indexes as needed