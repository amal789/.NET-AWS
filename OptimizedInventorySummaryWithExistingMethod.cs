using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.AspNetCore.Http;

public class OptimizedInventoryController
{
    private readonly ProductManager _productManager;

    public OptimizedInventoryController()
    {
        _productManager = new ProductManager();
    }

    // Optimized InventorySummary that uses your existing GetAssociatedProducts method
    public List<ServiceLineItem> InventorySummary(string organizationID, string tenantID, string type, 
        bool? isLicenseExpired, bool? isUpdateAvailable, HttpContext httpContext, string searchText, 
        string firmwareVersion, string registeredOn, string expiryDate)
    {
        var objLog = new Latte.Library.LoggingAndTrace();
        var combinedResults = new List<ServiceLineItem>();
        var objCust = new Latte.BusinessLayer.Customer();

        try
        {
            var objToken = Helper.ParseToken(httpContext);
            string username = objToken.userName;
            string sessionId = objToken.sessionId;

            // Get user context data (if needed)
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

            // Build input dataset with all filters and pagination - Direct call to your existing method!
            DataSet inputDS = _productManager.BuildGetAssociatedProductsDataset(
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
                pageSize: 5000  // Support up to 5000 records
            );

            // Call your existing GetAssociatedProducts method with enhanced parameters
            DataSet objDS = _productManager.GetAssociatedProducts(inputDS);

            if (objDS != null && objDS.Tables.Count > 0 && objDS.Tables[0].Rows.Count > 0)
            {
                // Single optimized loop to process all data and apply client-side filters
                combinedResults = ProcessDataInSingleLoop(objDS.Tables[0], new FilterCriteria
                {
                    TenantID = tenantID,
                    ProductType = type,
                    IsUpdateAvailable = isUpdateAvailable,
                    SearchText = searchText,
                    FirmwareVersion = firmwareVersion,
                    RegisteredOn = registeredOn,
                    ExpiryDate = expiryDate
                });
            }
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
        }

        return combinedResults;
    }

    // Single loop processing method - eliminates multiple loops
    private List<ServiceLineItem> ProcessDataInSingleLoop(DataTable productData, FilterCriteria filters)
    {
        var results = new List<ServiceLineItem>();

        // Single loop to process all data and apply remaining filters
        foreach (DataRow row in productData.Rows)
        {
            try
            {
                // Apply client-side filters that couldn't be handled at database level
                if (!PassesClientSideFilters(row, filters))
                    continue;

                // Create ServiceLineItem object directly - no additional loops!
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

    private bool PassesClientSideFilters(DataRow row, FilterCriteria filters)
    {
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

        // Apply search text filter (comprehensive search across multiple fields)
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
            // Log error but return null to skip this item
            return null;
        }
    }

    // Helper methods for safe data extraction
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

// Filter criteria class for organizing client-side filters
public class FilterCriteria
{
    public string TenantID { get; set; }
    public string ProductType { get; set; }
    public bool? IsUpdateAvailable { get; set; }
    public string SearchText { get; set; }
    public string FirmwareVersion { get; set; }
    public string RegisteredOn { get; set; }
    public string ExpiryDate { get; set; }
}

// Usage examples
public class UsageExamples
{
    public void Example1_Get5000Records()
    {
        var controller = new OptimizedInventoryController();
        
        // Get up to 5000 records with no filters
        var allRecords = controller.InventorySummary(
            organizationID: null,    // No organization filter
            tenantID: "ALL",         // All tenants
            type: "ALL",             // All product types
            isLicenseExpired: null,  // All license statuses  
            isUpdateAvailable: null, // All update statuses
            httpContext: httpContext,
            searchText: "",          // No search filter
            firmwareVersion: "",     // No firmware filter
            registeredOn: "",        // No date filter
            expiryDate: ""           // No expiry filter
        );
        
        Console.WriteLine($"Retrieved {allRecords.Count} records");
    }

    public void Example2_FilteredQuery()
    {
        var controller = new OptimizedInventoryController();
        
        // Get filtered results using database and client-side filtering
        var filteredRecords = controller.InventorySummary(
            organizationID: "12345",      // Database filter
            tenantID: "TENANT001",        // Client-side filter
            type: "FIREWALL",            // Client-side filter
            isLicenseExpired: true,      // Database filter
            isUpdateAvailable: false,    // Client-side filter
            httpContext: httpContext,
            searchText: "SonicWall",     // Client-side filter
            firmwareVersion: "7.0",      // Client-side filter
            registeredOn: "",
            expiryDate: ""
        );
        
        Console.WriteLine($"Retrieved {filteredRecords.Count} filtered records");
    }

    public void Example3_SearchAndPagination()
    {
        var controller = new OptimizedInventoryController();
        
        // Search across multiple fields with large page size
        var searchResults = controller.InventorySummary(
            organizationID: null,
            tenantID: "ALL",
            type: "ALL",
            isLicenseExpired: null,
            isUpdateAvailable: null,
            httpContext: httpContext,
            searchText: "NSa",           // Search for NSa products
            firmwareVersion: "",
            registeredOn: "",
            expiryDate: ""
        );
        
        Console.WriteLine($"Found {searchResults.Count} products matching 'NSa'");
    }
}