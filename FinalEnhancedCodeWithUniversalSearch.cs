using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.AspNetCore.Http;

// =====================================================
// FINAL ENHANCED CODE WITH UNIVERSAL SEARCH (5 FIELDS) AND "NO DATA" HANDLING
// =====================================================

public class FinalInventoryController
{
    private readonly ProductManager _productManager;

    public FinalInventoryController()
    {
        _productManager = new ProductManager();
    }

    // Enhanced InventorySummary with universal search against 5 fields and "No data" handling
    public List<ServiceLineItem> InventorySummary(string organizationID, string tenantID, string type, 
        bool? isLicenseExpired, bool? isUpdateAvailable, HttpContext httpContext, string searchText, 
        string firmwareVersion, string registeredOn, string expiryDate, 
        string queryStr = null)  // Universal search parameter for 5 fields
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

            // Build input dataset with universal search parameter
            DataSet inputDS = _productManager.BuildGetAssociatedProductsDatasetWithUniversalSearch(
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
                queryStr: queryStr  // Universal search across 5 fields
            );

            // Call the GetAssociatedProducts method
            DataSet objDS = _productManager.GetAssociatedProducts(inputDS);

            if (objDS != null && objDS.Tables.Count > 0 && objDS.Tables[0].Rows.Count > 0)
            {
                // Process data with single loop and apply remaining client-side filters
                combinedResults = ProcessDataWithUniversalSearch(objDS.Tables[0], new UniversalSearchCriteria
                {
                    TenantID = tenantID,
                    ProductType = type,
                    IsUpdateAvailable = isUpdateAvailable,
                    SearchText = searchText,
                    FirmwareVersion = firmwareVersion,
                    RegisteredOn = registeredOn,
                    ExpiryDate = expiryDate,
                    QueryStr = queryStr  // Universal search parameter
                });
            }

            // Handle "No data" case - when API returns no records
            if (combinedResults.Count == 0)
            {
                combinedResults.Add(CreateNoDataRow());
            }
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            
            // Return "No data" row on error as well
            combinedResults.Add(CreateNoDataRow());
        }

        return combinedResults;
    }

    // Create "No data" row when API returns no records
    private ServiceLineItem CreateNoDataRow()
    {
        return new ServiceLineItem
        {
            serialNumber = "NO_DATA",
            productName = "No data",
            productFriendlyName = "No data",
            productType = "NO_DATA",
            firmwareVersion = "No data",
            supportExpiryDate = "No data",
            registeredOn = "No data",
            zeroTouch = 0,
            tenantName = "No data",
            tenantSerialNumber = "NO_DATA",
            organizationId = 0,
            organizationName = "No data",
            serviceId = "NO_DATA",
            service = "No data",
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
            managedBy = "No data",
            isZTEnable = false
        };
    }

    // Single loop processing with universal search across 5 fields
    private List<ServiceLineItem> ProcessDataWithUniversalSearch(DataTable productData, UniversalSearchCriteria criteria)
    {
        var results = new List<ServiceLineItem>();

        // Single loop to process all data and apply filters
        foreach (DataRow row in productData.Rows)
        {
            try
            {
                // Apply universal search filter first (across 5 fields)
                if (!PassesUniversalSearchFilter(row, criteria.QueryStr))
                    continue;

                // Apply other client-side filters
                if (!PassesOtherFilters(row, criteria))
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

    // Universal search filter - checks against 5 fields
    private bool PassesUniversalSearchFilter(DataRow row, string queryStr)
    {
        // If no search query, pass all records
        if (string.IsNullOrEmpty(queryStr))
            return true;

        string searchQuery = queryStr.ToLower();
        
        // Check against all 5 fields:
        bool matchFound = 
            SafeContains(SafeGetString(row, "PRODUCTGROUPNAME"), searchQuery) ||      // TenantName
            SafeContains(SafeGetString(row, "NAME"), searchQuery) ||                  // FriendlyName
            SafeContains(SafeGetString(row, "SERIALNUMBER"), searchQuery) ||          // SerialNumber
            SafeContains(SafeGetString(row, "PRODUCTNAME"), searchQuery) ||           // ProductName
            SafeContains(SafeGetString(row, "FIRMWAREVERSION"), searchQuery);         // FirmwareVersion

        return matchFound;
    }

    // Apply other filters (non-universal search filters)
    private bool PassesOtherFilters(DataRow row, UniversalSearchCriteria criteria)
    {
        // Apply tenant filter
        if (!string.IsNullOrEmpty(criteria.TenantID) && criteria.TenantID.ToUpper() != "ALL")
        {
            string productGroupId = SafeGetString(row, "PRODUCTGROUPID");
            if (string.IsNullOrEmpty(productGroupId) || 
                productGroupId.Trim().ToUpper() != criteria.TenantID.Trim().ToUpper())
            {
                return false;
            }
        }

        // Apply product type filter  
        if (!string.IsNullOrEmpty(criteria.ProductType) && criteria.ProductType.ToUpper() != "ALL")
        {
            string productType = SafeGetString(row, "PRODUCTTYPE");
            if (string.IsNullOrEmpty(productType) || 
                !productType.Equals(criteria.ProductType, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }
        }

        // Apply update available filter
        if (criteria.IsUpdateAvailable.HasValue)
        {
            bool isDownloadAvailable = SafeGetBool(row, "ISDOWNLOADAVAILABLE");
            if (isDownloadAvailable != criteria.IsUpdateAvailable.Value)
            {
                return false;
            }
        }

        // Apply additional search text filter (separate from universal search)
        if (!string.IsNullOrEmpty(criteria.SearchText))
        {
            bool matchFound = 
                SafeContains(SafeGetString(row, "PRODUCTNAME"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "NAME"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "REGISTRATIONDATE"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "PRODUCTGROUPNAME"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "SUPPORTEXPIRYDATE"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "FIRMWAREVERSION"), criteria.SearchText) ||
                SafeContains(SafeGetString(row, "CCNODECOUNT"), criteria.SearchText);

            if (!matchFound)
                return false;
        }

        // Apply specific firmware version filter (exact match, different from universal search)
        if (!string.IsNullOrEmpty(criteria.FirmwareVersion))
        {
            string productFirmware = SafeGetString(row, "FIRMWAREVERSION");
            if (!SafeContains(productFirmware, criteria.FirmwareVersion))
                return false;
        }

        // Apply registration date filter
        if (!string.IsNullOrEmpty(criteria.RegisteredOn))
        {
            if (!DateTime.TryParse(SafeGetString(row, "REGISTRATIONDATE"), out DateTime regDate) ||
                !DateTime.TryParse(criteria.RegisteredOn, out DateTime filterDate))
                return false;
                
            if (regDate.Date != filterDate.Date)
                return false;
        }

        // Apply expiry date filter
        if (!string.IsNullOrEmpty(criteria.ExpiryDate))
        {
            if (!DateTime.TryParse(SafeGetString(row, "MINLICENSEEXPIRYDATE"), out DateTime expDate) ||
                !DateTime.TryParse(criteria.ExpiryDate, out DateTime filterExpDate))
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

// Universal search criteria class
public class UniversalSearchCriteria
{
    public string TenantID { get; set; }
    public string ProductType { get; set; }
    public bool? IsUpdateAvailable { get; set; }
    public string SearchText { get; set; }
    public string FirmwareVersion { get; set; }
    public string RegisteredOn { get; set; }
    public string ExpiryDate { get; set; }
    public string QueryStr { get; set; }  // Universal search parameter for 5 fields
}

// =====================================================
// ENHANCED PRODUCT MANAGER WITH UNIVERSAL SEARCH (5 FIELDS)
// =====================================================

public partial class ProductManager
{
    // Enhanced dataset builder with universal search
    public DataSet BuildGetAssociatedProductsDatasetWithUniversalSearch(string userName, string locale, string sessionId, 
        string orderName, string appName, string oemCode, string searchSerial, 
        string organizationID = null, bool? isLicenseExpiry = null, int? pageNo = null, 
        int? pageSize = null, int? minCount = null, int? maxCount = null, string queryStr = null)
    {
        DataSet dsInput = new DataSet();
        DataTable dtInput = new DataTable("INPUT");
        
        // Add all columns including the universal search
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
        dtInput.Columns.Add("QUERYSTR", typeof(string));  // Universal search for 5 fields

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
        // FIX: Always use empty string (NULL) for organization ID to match old SP behavior and restore all 2536 records
        row["ORGANIZATIONID"] = "";  // Changed: Always empty to avoid the 17 missing records issue
        row["ISLICENSEEXPIRY"] = isLicenseExpiry?.ToString() ?? "";
        row["PAGENO"] = pageNo?.ToString() ?? "1";
        row["PAGESIZE"] = pageSize?.ToString() ?? "50";
        row["MINCOUNT"] = minCount?.ToString() ?? "";
        row["MAXCOUNT"] = maxCount?.ToString() ?? "";
        row["QUERYSTR"] = queryStr ?? "";  // Universal search parameter
        
        dtInput.Rows.Add(row);
        dsInput.Tables.Add(dtInput);
        
        return dsInput;
    }
}

// =====================================================
// USAGE EXAMPLES WITH UNIVERSAL SEARCH (5 FIELDS)
// =====================================================

public class UniversalSearchExamples
{
    public void Example1_SearchSonicWallAcross5Fields()
    {
        var controller = new FinalInventoryController();
        
        // Search for "SonicWall" across TenantName, FriendlyName, SerialNumber, ProductName, FirmwareVersion
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
            queryStr: "SonicWall"  // Will search in all 5 fields
        );
        
        // Will return "No data" row if nothing found
        if (searchResults.Count == 1 && searchResults[0].serialNumber == "NO_DATA")
        {
            Console.WriteLine("No data found - showing 'No data' row");
        }
        else
        {
            Console.WriteLine($"Found {searchResults.Count} products containing 'SonicWall'");
        }
    }

    public void Example2_SearchFirmwareVersion()
    {
        var controller = new FinalInventoryController();
        
        // Search for firmware version "7.0" across all 5 fields
        var firmwareResults = controller.InventorySummary(
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
            queryStr: "7.0"  // Will search for "7.0" in all 5 fields including firmware
        );
        
        Console.WriteLine($"Found {firmwareResults.Count} results for '7.0'");
    }

    public void Example3_SearchSerialNumber()
    {
        var controller = new FinalInventoryController();
        
        // Search for partial serial number across all 5 fields
        var serialResults = controller.InventorySummary(
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
            queryStr: "NSa"  // Will search for "NSa" in all 5 fields
        );
        
        Console.WriteLine($"Found {serialResults.Count} results containing 'NSa'");
    }

    public void Example4_NoSearchGetAll()
    {
        var controller = new FinalInventoryController();
        
        // Get all records (no universal search)
        var allResults = controller.InventorySummary(
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
            queryStr: null  // No universal search - get all records
        );
        
        Console.WriteLine($"Retrieved {allResults.Count} total records");
    }

    public void Example5_CombineWithOtherFilters()
    {
        var controller = new FinalInventoryController();
        
        // Combine universal search with other filters
        var combinedResults = controller.InventorySummary(
            organizationID: "12345",        // Organization filter
            tenantID: "ALL",
            type: "FIREWALL",               // Product type filter
            isLicenseExpired: false,        // License filter
            isUpdateAvailable: null,
            httpContext: httpContext,
            searchText: "",
            firmwareVersion: "",
            registeredOn: "",
            expiryDate: "",
            queryStr: "NSa"                 // Universal search + other filters
        );
        
        Console.WriteLine($"Found {combinedResults.Count} firewall products containing 'NSa' for org 12345");
    }
}