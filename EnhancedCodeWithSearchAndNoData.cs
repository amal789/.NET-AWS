using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.AspNetCore.Http;

// =====================================================
// ENHANCED CODE WITH SEARCH FILTER AND "NO DATA" HANDLING
// =====================================================

public class EnhancedInventoryController
{
    private readonly ProductManager _productManager;

    public EnhancedInventoryController()
    {
        _productManager = new ProductManager();
    }

    // Enhanced InventorySummary with universal search filter and "No data" handling
    public List<ServiceLineItem> InventorySummary(string organizationID, string tenantID, string type, 
        bool? isLicenseExpired, bool? isUpdateAvailable, HttpContext httpContext, string searchText, 
        string firmwareVersion, string registeredOn, string expiryDate, 
        string queryStr = null)  // NEW: Universal search parameter
    {
        var objLog = new Latte.Library.LoggingAndTrace();
        var combinedResults = new List<ServiceLineItem>();
        var objCust = new Latte.BusinessLayer.Customer();

        try
        {
            var objToken = Helper.ParseToken(httpContext);
            string username = objToken.userName;
            string sessionId = objToken.sessionId;

            // Get user context data
            string contactId = string.Empty;
            string OrgId = string.Empty;
            DataSet dsuserinfo = objCust.GetCustomer(username);
            if (dsuserinfo != null && dsuserinfo.Tables.Count > 0)
            {
                contactId = dsuserinfo.Tables[0].Rows[0]["CONTACTID"].ToString();
                if (dsuserinfo.Tables[1].Rows.Count > 0 &&
                    dsuserinfo.Tables["ORGANIZATION"].Rows[0]["ISDEFAULTORGANIZATION"].ToString() == "YES")
                {
                    OrgId = dsuserinfo.Tables["ORGANIZATION"].Rows[0]["ORGANIZATIONID"].ToString();
                }
            }

            // Build input dataset with all filters including new queryStr
            DataSet inputDS = _productManager.BuildGetAssociatedProductsDatasetEnhanced(
                userName: username,
                locale: "EN",
                sessionId: sessionId,
                orderName: "REGISTEREDDATE",
                appName: "MSW",
                oemCode: "SNWL",
                searchSerial: searchText ?? "",
                organizationID: organizationID,
                isLicenseExpiry: isLicenseExpired,
                pageNo: 1,
                pageSize: 5000,
                queryStr: queryStr  // NEW: Pass the universal search filter
            );

            // Call the enhanced GetAssociatedProducts method
            DataSet objDS = _productManager.GetAssociatedProductsEnhanced(inputDS);

            if (objDS != null && objDS.Tables.Count > 0 && objDS.Tables[0].Rows.Count > 0)
            {
                // Process data with single loop and apply remaining client-side filters
                combinedResults = ProcessDataInSingleLoopEnhanced(objDS.Tables[0], new FilterCriteriaEnhanced
                {
                    TenantID = tenantID,
                    ProductType = type,
                    IsUpdateAvailable = isUpdateAvailable,
                    SearchText = searchText,
                    FirmwareVersion = firmwareVersion,
                    RegisteredOn = registeredOn,
                    ExpiryDate = expiryDate,
                    QueryStr = queryStr  // NEW: Universal search filter
                });
            }

            // NEW: Handle empty results - Add "No data" row
            if (combinedResults.Count == 0)
            {
                combinedResults.Add(CreateNoDataServiceLineItem());
            }
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            
            // Return "No data" item on error as well
            combinedResults.Add(CreateNoDataServiceLineItem());
        }

        return combinedResults;
    }

    // NEW: Create a "No data" ServiceLineItem
    private ServiceLineItem CreateNoDataServiceLineItem()
    {
        return new ServiceLineItem
        {
            serialNumber = "NO_DATA",
            productName = "No data",
            productFriendlyName = "No data",
            productType = "NO_DATA",
            firmwareVersion = "",
            supportExpiryDate = "",
            registeredOn = "",
            zeroTouch = 0,
            tenantName = "No data",
            tenantSerialNumber = "",
            organizationId = 0,
            organizationName = "",
            serviceId = "",
            service = "",
            licenseStartDate = null,
            licenseExpiryDate = null,
            nodeCount = "0",
            usedNodeCount = 0,
            status = "NO_DATA",
            isMonthlySubscription = false,
            isUpdateAvailable = false,
            addressId = 0,
            productCount = "0",
            isHidden = null,
            isHiddenServices = null,
            isAffiliated = false,
            isLicenseExpiry = false,
            managedBy = "",
            isZTEnable = false
        };
    }

    // Enhanced single loop processing with universal search
    private List<ServiceLineItem> ProcessDataInSingleLoopEnhanced(DataTable productData, FilterCriteriaEnhanced filters)
    {
        var results = new List<ServiceLineItem>();

        // Single loop to process all data and apply filters
        foreach (DataRow row in productData.Rows)
        {
            try
            {
                // Apply client-side filters including the new universal search
                if (!PassesClientSideFiltersEnhanced(row, filters))
                    continue;

                // Create ServiceLineItem object directly
                var serviceItem = CreateServiceLineItemFromDataRow(row);
                
                if (serviceItem != null)
                    results.Add(serviceItem);
            }
            catch (Exception ex)
            {
                // Log individual row processing errors but continue
                // EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            }
        }

        return results;
    }

    // Enhanced filtering with universal search
    private bool PassesClientSideFiltersEnhanced(DataRow row, FilterCriteriaEnhanced filters)
    {
        // Apply universal search filter first (NEW)
        if (!string.IsNullOrEmpty(filters.QueryStr))
        {
            string queryStr = filters.QueryStr.ToLower();
            bool universalMatchFound = 
                SafeContains(SafeGetString(row, "PRODUCTGROUPNAME"), queryStr) ||      // TenantName
                SafeContains(SafeGetString(row, "NAME"), queryStr) ||                  // FriendlyName
                SafeContains(SafeGetString(row, "SERIALNUMBER"), queryStr) ||          // SerialNumber
                SafeContains(SafeGetString(row, "PRODUCTNAME"), queryStr);             // ProductName

            if (!universalMatchFound)
                return false;
        }

        // Apply existing filters
        // Apply tenant filter
        if (!string.IsNullOrEmpty(filters.TenantID) && filters.TenantID.ToUpper() != "ALL")
        {
            string productGroupId = SafeGetString(row, "PRODUCTGROUPID");
            if (string.IsNullOrEmpty(productGroupId) || 
                productGroupId.Trim().ToUpper() != filters.TenantID.Trim().ToUpper())
            {
                return false;
            }
        }

        // Apply product type filter  
        if (!string.IsNullOrEmpty(filters.ProductType) && filters.ProductType.ToUpper() != "ALL")
        {
            string productType = SafeGetString(row, "PRODUCTTYPE");
            if (string.IsNullOrEmpty(productType) || 
                !productType.Equals(filters.ProductType, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }
        }

        // Apply update available filter
        if (filters.IsUpdateAvailable.HasValue)
        {
            bool isDownloadAvailable = SafeGetBool(row, "ISDOWNLOADAVAILABLE");
            if (isDownloadAvailable != filters.IsUpdateAvailable.Value)
            {
                return false;
            }
        }

        // Apply search text filter (separate from universal search)
        if (!string.IsNullOrEmpty(filters.SearchText))
        {
            bool matchFound = 
                SafeContains(SafeGetString(row, "PRODUCTNAME"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "NAME"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "REGISTRATIONDATE"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "PRODUCTGROUPNAME"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "SUPPORTEXPIRYDATE"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "FIRMWAREVERSION"), filters.SearchText) ||
                SafeContains(SafeGetString(row, "CCNODECOUNT"), filters.SearchText);

            if (!matchFound)
                return false;
        }

        // Apply firmware version filter
        if (!string.IsNullOrEmpty(filters.FirmwareVersion))
        {
            string productFirmware = SafeGetString(row, "FIRMWAREVERSION");
            if (!SafeContains(productFirmware, filters.FirmwareVersion))
                return false;
        }

        // Apply registration date filter
        if (!string.IsNullOrEmpty(filters.RegisteredOn))
        {
            if (!DateTime.TryParse(SafeGetString(row, "REGISTRATIONDATE"), out DateTime regDate) ||
                !DateTime.TryParse(filters.RegisteredOn, out DateTime filterDate))
                return false;
                
            if (regDate.Date != filterDate.Date)
                return false;
        }

        // Apply expiry date filter
        if (!string.IsNullOrEmpty(filters.ExpiryDate))
        {
            if (!DateTime.TryParse(SafeGetString(row, "MINLICENSEEXPIRYDATE"), out DateTime expDate) ||
                !DateTime.TryParse(filters.ExpiryDate, out DateTime filterExpDate))
                return false;
                
            if (expDate.Date != filterExpDate.Date)
                return false;
        }

        return true;
    }

    private ServiceLineItem CreateServiceLineItemFromDataRow(DataRow row)
    {
        try
        {
            var serviceItem = new ServiceLineItem
            {
                serialNumber = SafeGetString(row, "SERIALNUMBER"),
                productName = SafeGetString(row, "PRODUCTNAME"),
                productFriendlyName = SafeGetString(row, "NAME"),
                productType = SafeGetString(row, "PRODUCTTYPE"),
                firmwareVersion = SafeGetString(row, "FIRMWAREVERSION"),
                supportExpiryDate = FormatDate(SafeGetString(row, "SUPPORTEXPIRYDATE")),
                registeredOn = FormatDate(SafeGetString(row, "REGISTRATIONDATE")),
                zeroTouch = SafeGetInt(row, "ISZTSUPPORTED"),
                tenantName = SafeGetString(row, "PRODUCTGROUPNAME"),
                tenantSerialNumber = SafeGetString(row, "PRODUCTGROUPID"),
                organizationId = SafeGetLong(row, "ORGANIZATIONID"),
                organizationName = SafeGetString(row, "ORGNAME"),
                serviceId = "",
                service = "",
                licenseStartDate = null,
                licenseExpiryDate = ParseNullableDate(SafeGetString(row, "MINLICENSEEXPIRYDATE")),
                nodeCount = SafeGetString(row, "CCNODECOUNT"),
                usedNodeCount = 0,
                status = SafeGetString(row, "DEVICESTATUS"),
                isMonthlySubscription = false,
                isUpdateAvailable = SafeGetBool(row, "ISDOWNLOADAVAILABLE"),
                addressId = 0,
                productCount = SafeGetString(row, "HESNODECOUNT"),
                isHidden = null,
                isHiddenServices = null,
                isAffiliated = false,
                isLicenseExpiry = SafeGetBool(row, "ISLICENSEEXPIRED"),
                managedBy = SafeGetString(row, "MANAGEMENTOPTION"),
                isZTEnable = SafeGetBool(row, "ISZTSUPPORTED")
            };

            return serviceItem;
        }
        catch (Exception ex)
        {
            return null;
        }
    }

    // Helper methods
    private string SafeGetString(DataRow row, string columnName)
    {
        try
        {
            return row[columnName]?.ToString() ?? "";
        }
        catch
        {
            return "";
        }
    }

    private int SafeGetInt(DataRow row, string columnName)
    {
        try
        {
            if (int.TryParse(row[columnName]?.ToString(), out int result))
                return result;
            return 0;
        }
        catch
        {
            return 0;
        }
    }

    private long SafeGetLong(DataRow row, string columnName)
    {
        try
        {
            if (long.TryParse(row[columnName]?.ToString(), out long result))
                return result;
            return 0;
        }
        catch
        {
            return 0;
        }
    }

    private bool SafeGetBool(DataRow row, string columnName)
    {
        try
        {
            string value = row[columnName]?.ToString();
            return value == "1" || value?.ToLower() == "true";
        }
        catch
        {
            return false;
        }
    }

    private bool SafeContains(string source, string searchText)
    {
        return !string.IsNullOrEmpty(source) && 
               source.Contains(searchText, StringComparison.OrdinalIgnoreCase);
    }

    private string FormatDate(string dateString)
    {
        try
        {
            if (DateTime.TryParse(dateString, out DateTime date))
                return date.ToString("MMM dd yyyy");
            return dateString;
        }
        catch
        {
            return dateString;
        }
    }

    private DateTime? ParseNullableDate(string dateString)
    {
        try
        {
            if (DateTime.TryParse(dateString, out DateTime date))
                return date;
            return null;
        }
        catch
        {
            return null;
        }
    }
}

// Enhanced filter criteria with universal search
public class FilterCriteriaEnhanced
{
    public string TenantID { get; set; }
    public string ProductType { get; set; }
    public bool? IsUpdateAvailable { get; set; }
    public string SearchText { get; set; }
    public string FirmwareVersion { get; set; }
    public string RegisteredOn { get; set; }
    public string ExpiryDate { get; set; }
    public string QueryStr { get; set; }  // NEW: Universal search parameter
}

// =====================================================
// ENHANCED PRODUCT MANAGER WITH UNIVERSAL SEARCH
// =====================================================

public partial class ProductManager
{
    // Enhanced method with universal search support
    public DataSet GetAssociatedProductsEnhanced(DataSet objInputDS)
    {
        DataSet objResult = new DataSet();
        DataAccessHandler DAL = new DataAccessHandler();
        
        // ... existing variable declarations ...
        String strSerialNumber = "";
        String strOrderName = "";
        String strUserName = "";
        // ... (all your existing variables)
        
        // ADD new variable for universal search
        string strQueryStr = "";
        
        try
        {
            // ... your existing parameter extraction code ...
            strUserName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "USERNAME", "");
            // ... (all your existing extractions)
            
            // ADD new parameter extraction for universal search
            strQueryStr = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "QUERYSTR", "");
            
            // ... your existing parameter setup code ...
            List<SqlParameter> lst = new List<SqlParameter>();
            
            // ... add all your existing parameters ...
            
            // ADD new parameter for universal search
            SqlParameter sqlParamQueryStr = new SqlParameter("@QUERYSTR", SqlDbType.VarChar);
            sqlParamQueryStr.Size = 100;
            sqlParamQueryStr.Value = string.IsNullOrEmpty(strQueryStr) ? "" : strQueryStr;
            lst.Add(sqlParamQueryStr);
            
            // Execute the stored procedure
            objResult = DAL.ExecuteSQLDataSet("GETASSOCIATEDPRODUCTSWITHORDERLIST", lst);
            
            // Check if no data returned and add default status
            if (objResult.Tables.Count == 0 || objResult.Tables[0].Rows.Count == 0)
            {
                // Create empty table with proper structure for "No data" handling
                DataTable emptyTable = CreateEmptyProductTable();
                objResult.Tables.Clear();
                objResult.Tables.Add(emptyTable);
            }
            
            objResult.Tables.Add(Helper.BuildDefaultSuccessStatus());

        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            objResult.Tables.Clear();
            objResult.Tables.Add(Helper.BuildDefaultFailureStatus());
        }
        finally
        {
            if (DAL != null)
                DAL = null;
        }
        
        return objResult;
    }

    // Helper method to create empty table structure
    private DataTable CreateEmptyProductTable()
    {
        DataTable dt = new DataTable();
        dt.Columns.Add("SERIALNUMBER", typeof(string));
        dt.Columns.Add("PRODUCTNAME", typeof(string));
        dt.Columns.Add("NAME", typeof(string));
        dt.Columns.Add("PRODUCTTYPE", typeof(string));
        dt.Columns.Add("FIRMWAREVERSION", typeof(string));
        dt.Columns.Add("SUPPORTEXPIRYDATE", typeof(string));
        dt.Columns.Add("REGISTRATIONDATE", typeof(string));
        dt.Columns.Add("ISZTSUPPORTED", typeof(int));
        dt.Columns.Add("PRODUCTGROUPNAME", typeof(string));
        dt.Columns.Add("PRODUCTGROUPID", typeof(string));
        dt.Columns.Add("ORGANIZATIONID", typeof(long));
        dt.Columns.Add("ORGNAME", typeof(string));
        dt.Columns.Add("MINLICENSEEXPIRYDATE", typeof(string));
        dt.Columns.Add("CCNODECOUNT", typeof(string));
        dt.Columns.Add("DEVICESTATUS", typeof(string));
        dt.Columns.Add("ISDOWNLOADAVAILABLE", typeof(bool));
        dt.Columns.Add("HESNODECOUNT", typeof(string));
        dt.Columns.Add("ISLICENSEEXPIRED", typeof(bool));
        dt.Columns.Add("MANAGEMENTOPTION", typeof(string));
        return dt;
    }

    // Enhanced dataset builder with universal search
    public DataSet BuildGetAssociatedProductsDatasetEnhanced(string userName, string locale, string sessionId, 
        string orderName, string appName, string oemCode, string searchSerial, 
        string organizationID = null, bool? isLicenseExpiry = null, int? pageNo = null, 
        int? pageSize = null, int? minCount = null, int? maxCount = null, string queryStr = null)
    {
        DataSet dsInput = new DataSet();
        DataTable dtInput = new DataTable("INPUT");
        
        // Add all existing columns
        dtInput.Columns.Add("USERNAME", typeof(string));
        dtInput.Columns.Add("ORDERNAME", typeof(string));
        dtInput.Columns.Add("ORDERTYPE", typeof(string));
        dtInput.Columns.Add("ASSOCTYPEID", typeof(string));
        dtInput.Columns.Add("ASSOCTYPE", typeof(string));
        dtInput.Columns.Add("SERIALNUMBER", typeof(string));
        dtInput.Columns.Add("LANGUAGECODE", typeof(string));
        dtInput.Columns.Add("SESSIONID", typeof(string));
        dtInput.Columns.Add("PRODUCTLIST", typeof(string));
        dtInput.Columns.Add("OEMCODE", typeof(string));
        dtInput.Columns.Add("APPNAME", typeof(string));
        dtInput.Columns.Add("CALLFROM", typeof(string));
        dtInput.Columns.Add("ISMOBILE", typeof(string));
        dtInput.Columns.Add("SEARCHSERIALNUMBER", typeof(string));
        dtInput.Columns.Add("SOURCE", typeof(string));
        dtInput.Columns.Add("ISPRODUCTGROUPTABLENEEDED", typeof(string));
        dtInput.Columns.Add("ORGANIZATIONID", typeof(string));
        dtInput.Columns.Add("ISLICENSEEXPIRY", typeof(string));
        dtInput.Columns.Add("PAGENO", typeof(string));
        dtInput.Columns.Add("PAGESIZE", typeof(string));
        dtInput.Columns.Add("MINCOUNT", typeof(string));
        dtInput.Columns.Add("MAXCOUNT", typeof(string));
        
        // ADD new column for universal search
        dtInput.Columns.Add("QUERYSTR", typeof(string));

        DataRow row = dtInput.NewRow();
        row["USERNAME"] = userName;
        row["ORDERNAME"] = orderName;
        row["ORDERTYPE"] = "";
        row["ASSOCTYPEID"] = "";
        row["ASSOCTYPE"] = "";
        row["SERIALNUMBER"] = "";
        row["LANGUAGECODE"] = locale;
        row["SESSIONID"] = sessionId;
        row["PRODUCTLIST"] = "";
        row["OEMCODE"] = oemCode;
        row["APPNAME"] = appName;
        row["CALLFROM"] = "";
        row["ISMOBILE"] = "";
        row["SEARCHSERIALNUMBER"] = searchSerial ?? "";
        row["SOURCE"] = "";
        row["ISPRODUCTGROUPTABLENEEDED"] = "YES";
        row["ORGANIZATIONID"] = organizationID ?? "";
        row["ISLICENSEEXPIRY"] = isLicenseExpiry?.ToString() ?? "";
        row["PAGENO"] = pageNo?.ToString() ?? "1";
        row["PAGESIZE"] = pageSize?.ToString() ?? "50";
        row["MINCOUNT"] = minCount?.ToString() ?? "";
        row["MAXCOUNT"] = maxCount?.ToString() ?? "";
        
        // ADD new row value for universal search
        row["QUERYSTR"] = queryStr ?? "";
        
        dtInput.Rows.Add(row);
        dsInput.Tables.Add(dtInput);
        
        return dsInput;
    }
}

// =====================================================
// USAGE EXAMPLES WITH NEW FEATURES
// =====================================================

public class UsageExamplesEnhanced
{
    public void Example1_UniversalSearch()
    {
        var controller = new EnhancedInventoryController();
        
        // Search across TenantName, FriendlyName, SerialNumber, ProductName
        var searchResults = controller.InventorySummary(
            organizationID: null,
            tenantID: "ALL",
            type: "ALL",
            isLicenseExpired: null,
            isUpdateAvailable: null,
            httpContext: httpContext,
            searchText: "",
            firmwareVersion: "",
            registeredOn: "",
            expiryDate: "",
            queryStr: "SonicWall"  // NEW: Universal search - will search across all 4 fields
        );
        
        // Will return "No data" item if nothing found
        Console.WriteLine($"Universal search results: {searchResults.Count}");
    }

    public void Example2_NoDataHandling()
    {
        var controller = new EnhancedInventoryController();
        
        // This will return "No data" item if no results found
        var results = controller.InventorySummary(
            organizationID: "999999",  // Non-existent org
            tenantID: "ALL",
            type: "ALL",
            isLicenseExpired: null,
            isUpdateAvailable: null,
            httpContext: httpContext,
            searchText: "",
            firmwareVersion: "",
            registeredOn: "",
            expiryDate: "",
            queryStr: null
        );
        
        if (results.Count == 1 && results[0].serialNumber == "NO_DATA")
        {
            Console.WriteLine("No data found - showing 'No data' row");
        }
    }

    public void Example3_CombinedFiltersWithSearch()
    {
        var controller = new EnhancedInventoryController();
        
        // Combine universal search with other filters
        var results = controller.InventorySummary(
            organizationID: "12345",
            tenantID: "ALL",
            type: "FIREWALL",
            isLicenseExpired: false,
            isUpdateAvailable: null,
            httpContext: httpContext,
            searchText: "",
            firmwareVersion: "",
            registeredOn: "",
            expiryDate: "",
            queryStr: "NSa"  // Search for NSa in any of the 4 fields
        );
        
        Console.WriteLine($"Filtered search results: {results.Count}");
    }
}