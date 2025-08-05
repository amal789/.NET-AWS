-- =============================================
-- Usage Examples for GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified
-- =============================================

-- Example 1: Basic Usage with Pagination
-- Get first page with 20 records, sorted by ProductName
DECLARE @TotalRecords INT, @TotalPages INT

EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = 'john.doe',
    @ORDERNAME = '',
    @ORDERTYPE = '',
    @PageNumber = 1,
    @PageSize = 20,
    @SortColumn = 'ProductName',
    @SortDirection = 'ASC',
    @TotalRecords = @TotalRecords OUTPUT,
    @TotalPages = @TotalPages OUTPUT

SELECT @TotalRecords as TotalRecords, @TotalPages as TotalPages

-- =============================================

-- Example 2: Advanced Search with Multiple Filters
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = 'jane.smith',
    @ORDERNAME = 'ORDER',
    @ORDERTYPE = 'PURCHASE',
    @SearchText = 'laptop',
    @ProductNameFilter = 'Dell',
    @StatusFilter = 'Active',
    @CategoryFilter = 'Electronics',
    @DateFromFilter = '2024-01-01',
    @DateToFilter = '2024-12-31',
    @PriceMinFilter = 500.00,
    @PriceMaxFilter = 2000.00,
    @PageNumber = 1,
    @PageSize = 15,
    @SortColumn = 'Price',
    @SortDirection = 'DESC'

-- =============================================

-- Example 3: Get Second Query (Summary Data) Along with Main Results
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = '',
    @ORDERNAME = '',
    @ORDERTYPE = '',
    @PageNumber = 1,
    @PageSize = 10,
    @EnableSecondQuery = 1,
    @ReturnSummaryData = 1

-- =============================================

-- Example 4: Serial Number Search with Pagination
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = '',
    @SERIALNUMBER = 'SN123456',
    @SEARCHSERIALNUMBER = 'SN12',  -- Partial search
    @PageNumber = 1,
    @PageSize = 25,
    @SortColumn = 'SerialNumber',
    @SortDirection = 'ASC'

-- =============================================

-- Example 5: Category-wise Analysis with Date Range
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = '',
    @CategoryFilter = 'Software',
    @DateFromFilter = '2024-06-01',
    @DateToFilter = '2024-06-30',
    @PageNumber = 1,
    @PageSize = 50,
    @SortColumn = 'OrderDate',
    @SortDirection = 'DESC',
    @EnableSecondQuery = 1

-- =============================================

-- Example 6: Mobile App Usage
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = 'mobile.user',
    @IsMobile = 'YES',
    @SearchText = 'phone',
    @PageNumber = 1,
    @PageSize = 10,  -- Smaller page size for mobile
    @SortColumn = 'ProductName',
    @SortDirection = 'ASC'

-- =============================================

-- Example 7: Large Dataset Navigation (Page 5 of results)
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @USERNAME = 'admin',
    @PageNumber = 5,
    @PageSize = 100,
    @SortColumn = 'OrderDate',
    @SortDirection = 'DESC'

-- =============================================

-- Example 8: Price Range Analysis with Summary
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @PriceMinFilter = 1000.00,
    @PriceMaxFilter = 5000.00,
    @StatusFilter = 'Active',
    @PageNumber = 1,
    @PageSize = 20,
    @SortColumn = 'Price',
    @SortDirection = 'ASC',
    @ReturnSummaryData = 1

-- =============================================

-- Example 9: Order Type Specific Search
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @ORDERTYPE = 'MAINTENANCE',
    @DateFromFilter = '2024-01-01',
    @PageNumber = 1,
    @PageSize = 30,
    @SortColumn = 'OrderDate',
    @SortDirection = 'DESC',
    @EnableSecondQuery = 1

-- =============================================

-- Example 10: Global Search Across All Fields
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]
    @SearchText = 'SNWL',  -- Will search in ProductName, ProductCode, and Description
    @PageNumber = 1,
    @PageSize = 25,
    @SortColumn = 'ProductCode',
    @SortDirection = 'ASC'