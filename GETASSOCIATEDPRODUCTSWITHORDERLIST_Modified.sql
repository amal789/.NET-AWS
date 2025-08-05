ALTER PROCEDURE [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST_Modified]        
    @USERNAME NVARCHAR(30),            
    @ORDERNAME VARCHAR(50),            
    @ORDERTYPE VARCHAR(30),            
    @ASSOCTYPEID INT = 0,            
    @ASSOCTYPE VARCHAR(30) = '',            
    @SERIALNUMBER VARCHAR(30) = '',            
    @LANGUAGECODE CHAR(2) = 'EN',            
    @SESSIONID VARCHAR(50) = NULL,            
    @PRODUCTLIST VARCHAR(100) = NULL,            
    @OEMCODE CHAR(4) = 'SNWL',            
    @APPNAME VARCHAR(50) = 'MSW',            
    @OutformatXML INT = NULL,            
    @CallFrom VARCHAR(50) = NULL,            
    @IsMobile VARCHAR(50) = 'NO',          
    @SOURCE VARCHAR(10) = '',      
    @SEARCHSERIALNUMBER VARCHAR(30) = '',      
    @ISPRODUCTGROUPTABLENEEDED VARCHAR(10) = 'YES',
    
    -- New Pagination Parameters
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SortColumn VARCHAR(50) = 'ProductName',
    @SortDirection VARCHAR(4) = 'ASC',
    
    -- New Search Filter Parameters
    @SearchText VARCHAR(100) = '',
    @ProductNameFilter VARCHAR(100) = '',
    @ProductCodeFilter VARCHAR(50) = '',
    @StatusFilter VARCHAR(20) = '',
    @CategoryFilter VARCHAR(50) = '',
    @DateFromFilter DATETIME = NULL,
    @DateToFilter DATETIME = NULL,
    @PriceMinFilter DECIMAL(10,2) = NULL,
    @PriceMaxFilter DECIMAL(10,2) = NULL,
    
    -- Output Parameters for Pagination
    @TotalRecords INT = 0 OUTPUT,
    @TotalPages INT = 0 OUTPUT,
    
    -- Control Parameters
    @EnableSecondQuery BIT = 0,
    @ReturnSummaryData BIT = 0
AS             
BEGIN          
    SET NOCOUNT ON
    
    -- Parameter Validation and Default Values
    IF ISNULL(@LANGUAGECODE, '') = ''             
        SELECT @LANGUAGECODE = 'EN'                 
                    
    IF ISNULL(@OEMCODE, '') = ''             
        SELECT @OEMCODE = 'SNWL'              
                                      
    IF ISNULL(@APPNAME, '') = ''             
        SELECT @APPNAME = 'MSW'              
                    
    IF ISNULL(@IsMobile, '') = ''             
        SELECT @IsMobile = 'NO'
        
    -- Pagination Validation
    IF @PageNumber < 1 SET @PageNumber = 1
    IF @PageSize < 1 SET @PageSize = 20
    IF @PageSize > 100 SET @PageSize = 100  -- Maximum page size limit
    
    -- Sort Validation
    IF @SortColumn NOT IN ('ProductName', 'ProductCode', 'SerialNumber', 'OrderDate', 'Status', 'Category', 'Price')
        SET @SortColumn = 'ProductName'
        
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'ASC'
              
    -- Variable Declarations
    DECLARE @CONTACTID BIGINT               
    DECLARE @ORGID BIGINT          
    DECLARE @ROLLUP BIT      
    DECLARE @ISSELECTEDPARTNER BIT = 0      
    DECLARE @INDEX INT              
    DECLARE @TotalCNT INT              
    DECLARE @TEMPSERIALNUMBER VARCHAR(30)            
    DECLARE @DISPLAYKEYSET VARCHAR(3)            
    DECLARE @ASSOWITHTXT NVARCHAR(100)              
    DECLARE @BISCLOSEDNETWORK INT            
    DECLARE @ISLARGEUSER VARCHAR(3) = 'NO'         
    DECLARE @RECENTCOUNT INT = 50       
    DECLARE @APPLICATIONFUNCTIONALITY VARCHAR(50) = 'ACCESSTYPEPRODMGMT'        
    DECLARE @ISMSSPUSER VARCHAR(10)      
    DECLARE @EMAILADDRESS VARCHAR(30)      
    DECLARE @DESCRIPTION VARCHAR(255)      
    DECLARE @APPLICATIONNAME VARCHAR(50)      
    DECLARE @MOBILESERVERPRODUCTLISTORGANIZATIONID VARCHAR(100)      
    DECLARE @ENABLEORGBASEDASSET VARCHAR(20) = 'NO'      
    DECLARE @ISORGBASEDACCOUNT VARCHAR(3) = 'NO'      
    DECLARE @PARTYID INT      
    DECLARE @ORGBASEDASSETOWNSERSHIPENABLED VARCHAR(3) = 'NO'
    DECLARE @ROLEIDORGBASED INT      
    DECLARE @IT INT = 0        
    DECLARE @CNT INT        
    DECLARE @ISER VARCHAR(40)        
    DECLARE @ICONNECTORNAME VARCHAR(100)   
    DECLARE @CONNECTORNAME NVARCHAR(255)
    
    -- Pagination Variables
    DECLARE @Offset INT
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @CountSQL NVARCHAR(MAX)
    DECLARE @WhereClause NVARCHAR(MAX) = ''
    DECLARE @OrderByClause NVARCHAR(200)
    
    SELECT @BISCLOSEDNETWORK = 0
    
    -- Calculate Offset for Pagination
    SET @Offset = (@PageNumber - 1) * @PageSize
    
    -- Build Dynamic WHERE Clause for Search Filters
    SET @WhereClause = 'WHERE 1=1 '
    
    IF ISNULL(@USERNAME, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.Username = @Username '
        
    IF ISNULL(@ORDERNAME, '') != ''
        SET @WhereClause = @WhereClause + 'AND o.OrderName LIKE ''%'' + @OrderName + ''%'' '
        
    IF ISNULL(@ORDERTYPE, '') != ''
        SET @WhereClause = @WhereClause + 'AND o.OrderType = @OrderType '
        
    IF ISNULL(@SERIALNUMBER, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.SerialNumber = @SerialNumber '
        
    IF ISNULL(@SEARCHSERIALNUMBER, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.SerialNumber LIKE ''%'' + @SearchSerialNumber + ''%'' '
        
    IF ISNULL(@SearchText, '') != ''
        SET @WhereClause = @WhereClause + 'AND (p.ProductName LIKE ''%'' + @SearchText + ''%'' OR p.ProductCode LIKE ''%'' + @SearchText + ''%'' OR p.Description LIKE ''%'' + @SearchText + ''%'') '
        
    IF ISNULL(@ProductNameFilter, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.ProductName LIKE ''%'' + @ProductNameFilter + ''%'' '
        
    IF ISNULL(@ProductCodeFilter, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.ProductCode LIKE ''%'' + @ProductCodeFilter + ''%'' '
        
    IF ISNULL(@StatusFilter, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.Status = @StatusFilter '
        
    IF ISNULL(@CategoryFilter, '') != ''
        SET @WhereClause = @WhereClause + 'AND p.Category = @CategoryFilter '
        
    IF @DateFromFilter IS NOT NULL
        SET @WhereClause = @WhereClause + 'AND o.OrderDate >= @DateFromFilter '
        
    IF @DateToFilter IS NOT NULL
        SET @WhereClause = @WhereClause + 'AND o.OrderDate <= @DateToFilter '
        
    IF @PriceMinFilter IS NOT NULL
        SET @WhereClause = @WhereClause + 'AND p.Price >= @PriceMinFilter '
        
    IF @PriceMaxFilter IS NOT NULL
        SET @WhereClause = @WhereClause + 'AND p.Price <= @PriceMaxFilter '
    
    -- Build ORDER BY Clause
    SET @OrderByClause = 'ORDER BY ' + @SortColumn + ' ' + @SortDirection
    
    -- First Query: Get Total Count for Pagination
    SET @CountSQL = N'
    SELECT @TotalRecords = COUNT(*)
    FROM Products p
    INNER JOIN Orders o ON p.OrderId = o.OrderId
    INNER JOIN AssociatedProducts ap ON p.ProductId = ap.ProductId
    LEFT JOIN ProductCategories pc ON p.CategoryId = pc.CategoryId
    LEFT JOIN Users u ON o.UserId = u.UserId
    ' + @WhereClause
    
    EXEC sp_executesql @CountSQL, 
        N'@Username NVARCHAR(30), @OrderName VARCHAR(50), @OrderType VARCHAR(30), @SerialNumber VARCHAR(30), 
          @SearchSerialNumber VARCHAR(30), @SearchText VARCHAR(100), @ProductNameFilter VARCHAR(100), 
          @ProductCodeFilter VARCHAR(50), @StatusFilter VARCHAR(20), @CategoryFilter VARCHAR(50), 
          @DateFromFilter DATETIME, @DateToFilter DATETIME, @PriceMinFilter DECIMAL(10,2), 
          @PriceMaxFilter DECIMAL(10,2), @TotalRecords INT OUTPUT',
        @USERNAME, @ORDERNAME, @ORDERTYPE, @SERIALNUMBER, @SEARCHSERIALNUMBER, @SearchText, 
        @ProductNameFilter, @ProductCodeFilter, @StatusFilter, @CategoryFilter, 
        @DateFromFilter, @DateToFilter, @PriceMinFilter, @PriceMaxFilter, @TotalRecords OUTPUT
    
    -- Calculate Total Pages
    SET @TotalPages = CEILING(CAST(@TotalRecords AS FLOAT) / @PageSize)
    
    -- Main Query: Get Paginated Results
    SET @SQL = N'
    SELECT 
        p.ProductId,
        p.ProductName,
        p.ProductCode,
        p.SerialNumber,
        p.Description,
        p.Price,
        p.Status,
        p.Category,
        o.OrderId,
        o.OrderName,
        o.OrderType,
        o.OrderDate,
        u.Username,
        ap.AssociationType,
        ap.AssociationDate,
        pc.CategoryName,
        -- Pagination Info
        @TotalRecords as TotalRecords,
        @TotalPages as TotalPages,
        @PageNumber as CurrentPage,
        @PageSize as PageSize
    FROM Products p
    INNER JOIN Orders o ON p.OrderId = o.OrderId
    INNER JOIN AssociatedProducts ap ON p.ProductId = ap.ProductId
    LEFT JOIN ProductCategories pc ON p.CategoryId = pc.CategoryId
    LEFT JOIN Users u ON o.UserId = u.UserId
    ' + @WhereClause + '
    ' + @OrderByClause + '
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY'
    
    EXEC sp_executesql @SQL, 
        N'@Username NVARCHAR(30), @OrderName VARCHAR(50), @OrderType VARCHAR(30), @SerialNumber VARCHAR(30), 
          @SearchSerialNumber VARCHAR(30), @SearchText VARCHAR(100), @ProductNameFilter VARCHAR(100), 
          @ProductCodeFilter VARCHAR(50), @StatusFilter VARCHAR(20), @CategoryFilter VARCHAR(50), 
          @DateFromFilter DATETIME, @DateToFilter DATETIME, @PriceMinFilter DECIMAL(10,2), 
          @PriceMaxFilter DECIMAL(10,2), @TotalRecords INT, @TotalPages INT, @PageNumber INT, 
          @PageSize INT, @Offset INT',
        @USERNAME, @ORDERNAME, @ORDERTYPE, @SERIALNUMBER, @SEARCHSERIALNUMBER, @SearchText, 
        @ProductNameFilter, @ProductCodeFilter, @StatusFilter, @CategoryFilter, 
        @DateFromFilter, @DateToFilter, @PriceMinFilter, @PriceMaxFilter, @TotalRecords, 
        @TotalPages, @PageNumber, @PageSize, @Offset
    
    -- Second Query: Summary/Aggregated Data (Optional)
    IF @EnableSecondQuery = 1 OR @ReturnSummaryData = 1
    BEGIN
        SELECT 
            'Summary Data' as QueryType,
            COUNT(*) as TotalProducts,
            COUNT(DISTINCT o.OrderId) as TotalOrders,
            COUNT(DISTINCT u.UserId) as TotalUsers,
            AVG(p.Price) as AveragePrice,
            MIN(p.Price) as MinPrice,
            MAX(p.Price) as MaxPrice,
            SUM(p.Price) as TotalValue,
            COUNT(CASE WHEN p.Status = 'Active' THEN 1 END) as ActiveProducts,
            COUNT(CASE WHEN p.Status = 'Inactive' THEN 1 END) as InactiveProducts,
            -- Category Breakdown
            STRING_AGG(DISTINCT pc.CategoryName, ', ') as Categories,
            -- Date Range
            MIN(o.OrderDate) as EarliestOrderDate,
            MAX(o.OrderDate) as LatestOrderDate
        FROM Products p
        INNER JOIN Orders o ON p.OrderId = o.OrderId
        INNER JOIN AssociatedProducts ap ON p.ProductId = ap.ProductId
        LEFT JOIN ProductCategories pc ON p.CategoryId = pc.CategoryId
        LEFT JOIN Users u ON o.UserId = u.UserId
        
        -- Category-wise Summary (Second part of second query)
        SELECT 
            'Category Summary' as QueryType,
            ISNULL(pc.CategoryName, 'Uncategorized') as Category,
            COUNT(*) as ProductCount,
            AVG(p.Price) as AvgPrice,
            SUM(p.Price) as TotalValue,
            COUNT(CASE WHEN p.Status = 'Active' THEN 1 END) as ActiveCount,
            COUNT(CASE WHEN p.Status = 'Inactive' THEN 1 END) as InactiveCount
        FROM Products p
        INNER JOIN Orders o ON p.OrderId = o.OrderId
        INNER JOIN AssociatedProducts ap ON p.ProductId = ap.ProductId
        LEFT JOIN ProductCategories pc ON p.CategoryId = pc.CategoryId
        LEFT JOIN Users u ON o.UserId = u.UserId
        GROUP BY pc.CategoryName
        ORDER BY ProductCount DESC
    END
    
    -- Return Pagination Metadata
    SELECT 
        @TotalRecords as TotalRecords,
        @TotalPages as TotalPages,
        @PageNumber as CurrentPage,
        @PageSize as PageSize,
        CASE WHEN @PageNumber > 1 THEN 1 ELSE 0 END as HasPreviousPage,
        CASE WHEN @PageNumber < @TotalPages THEN 1 ELSE 0 END as HasNextPage,
        CASE WHEN @PageNumber > 1 THEN @PageNumber - 1 ELSE NULL END as PreviousPage,
        CASE WHEN @PageNumber < @TotalPages THEN @PageNumber + 1 ELSE NULL END as NextPage
        
END