using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Linq;
using Microsoft.AspNetCore.Http;

public class OptimizedInventoryController
{
    // Optimized InventorySummary that goes directly to inner class
    public List<ServiceLineItem> InventorySummary(string organizationID, string tenantID, string type, 
        bool? isLicenseExpired, bool? isUpdateAvailable, HttpContext httpContext, string searchText, 
        string firmwareVersion, string registeredOn, string expiryDate)
    {
        var objLog = new Latte.Library.LoggingAndTrace();
        var combinedResults = new List<ServiceLineItem>();
        var objCust = new Latte.BusinessLayer.Customer();
        var objPM = new Products();

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

            // Create optimized request with all filters
            var optimizedRequest = new OptimizedProductRequest
            {
                Username = username,
                SessionId = sessionId,
                Locale = "EN",
                AppName = "MSW",
                OrganizationID = organizationID,
                TenantID = tenantID,
                ProductType = type,
                IsLicenseExpired = isLicenseExpired,
                IsUpdateAvailable = isUpdateAvailable,
                SearchText = searchText,
                FirmwareVersion = firmwareVersion,
                RegisteredOn = registeredOn,
                ExpiryDate = expiryDate
            };

            // Call optimized inner method directly
            combinedResults = objPM.GetOptimizedProductListForInventory(optimizedRequest);
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
        }

        return combinedResults;
    }
}

// Request model for optimized method
public class OptimizedProductRequest
{
    public string Username { get; set; }
    public string SessionId { get; set; }
    public string Locale { get; set; } = "EN";
    public string AppName { get; set; } = "MSW";
    public string OrganizationID { get; set; }
    public string TenantID { get; set; }
    public string ProductType { get; set; }
    public bool? IsLicenseExpired { get; set; }
    public bool? IsUpdateAvailable { get; set; }
    public string SearchText { get; set; }
    public string FirmwareVersion { get; set; }
    public string RegisteredOn { get; set; }
    public string ExpiryDate { get; set; }
}

// Optimized inner class method
public class Products
{
    public List<ServiceLineItem> GetOptimizedProductListForInventory(OptimizedProductRequest request)
    {
        var results = new List<ServiceLineItem>();
        var objCust = new Customer();
        
        try
        {
            // Get data from stored procedure with filters applied at database level
            DataSet objDS = GetFilteredProductData(request);
            
            if (objDS == null || objDS.Tables.Count == 0 || objDS.Tables[0].Rows.Count == 0)
            {
                return results;
            }

            // Single optimized loop to process all data
            results = ProcessProductDataInSingleLoop(objDS.Tables[0], request);
        }
        catch (Exception ex)
        {
            // Log error
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
        }

        return results;
    }

    private DataSet GetFilteredProductData(OptimizedProductRequest request)
    {
        // Build dataset with all filters for the stored procedure
        DataSet objDSInput = BuildOptimizedDataset(request);
        
        // Call stored procedure with filters applied at database level
        return GetAssociatedProducts(objDSInput);
    }

    private DataSet BuildOptimizedDataset(OptimizedProductRequest request)
    {
        DataSet dsInput = new DataSet();
        DataTable dtInput = new DataTable("INPUT");
        
        // Add parameters table
        dtInput.Columns.Add("USERNAME", typeof(string));
        dtInput.Columns.Add("SESSIONID", typeof(string)); 
        dtInput.Columns.Add("LOCALE", typeof(string));
        dtInput.Columns.Add("APPNAME", typeof(string));
        dtInput.Columns.Add("ORGANIZATIONID", typeof(string));
        dtInput.Columns.Add("TENANTID", typeof(string));
        dtInput.Columns.Add("PRODUCTTYPE", typeof(string));
        dtInput.Columns.Add("ISLICENSEEXPIRED", typeof(bool));
        dtInput.Columns.Add("ISUPDATEAVAILABLE", typeof(bool));
        dtInput.Columns.Add("SEARCHTEXT", typeof(string));
        dtInput.Columns.Add("FIRMWAREVERSION", typeof(string));
        dtInput.Columns.Add("REGISTEREDON", typeof(string));
        dtInput.Columns.Add("EXPIRYDATE", typeof(string));

        DataRow row = dtInput.NewRow();
        row["USERNAME"] = request.Username;
        row["SESSIONID"] = request.SessionId;
        row["LOCALE"] = request.Locale;
        row["APPNAME"] = request.AppName;
        row["ORGANIZATIONID"] = request.OrganizationID ?? (object)DBNull.Value;
        row["TENANTID"] = request.TenantID ?? (object)DBNull.Value;
        row["PRODUCTTYPE"] = request.ProductType ?? (object)DBNull.Value;
        row["ISLICENSEEXPIRED"] = request.IsLicenseExpired ?? (object)DBNull.Value;
        row["ISUPDATEAVAILABLE"] = request.IsUpdateAvailable ?? (object)DBNull.Value;
        row["SEARCHTEXT"] = request.SearchText ?? (object)DBNull.Value;
        row["FIRMWAREVERSION"] = request.FirmwareVersion ?? (object)DBNull.Value;
        row["REGISTEREDON"] = request.RegisteredOn ?? (object)DBNull.Value;
        row["EXPIRYDATE"] = request.ExpiryDate ?? (object)DBNull.Value;
        
        dtInput.Rows.Add(row);
        dsInput.Tables.Add(dtInput);
        
        return dsInput;
    }

    private List<ServiceLineItem> ProcessProductDataInSingleLoop(DataTable productData, OptimizedProductRequest request)
    {
        var results = new List<ServiceLineItem>();
        
        // Get renewal days once for all products
        var objCust = new Customer();
        string renewaldays = objCust.GetRenewalsDay(request.Username);
        if (string.IsNullOrEmpty(renewaldays))
            renewaldays = "0";

        // Single loop to process all data and apply remaining filters
        foreach (DataRow row in productData.Rows)
        {
            try
            {
                // Apply client-side filters that couldn't be handled at database level
                if (!PassesClientSideFilters(row, request))
                    continue;

                // Create ServiceLineItem object directly
                var serviceItem = CreateServiceLineItemFromDataRow(row, renewaldays);
                
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

    private bool PassesClientSideFilters(DataRow row, OptimizedProductRequest request)
    {
        // Apply search text filter (complex string matching)
        if (!string.IsNullOrEmpty(request.SearchText))
        {
            string searchText = request.SearchText.ToLower();
            bool matchFound = 
                SafeContains(row["PRODUCTNAME"]?.ToString(), searchText) ||
                SafeContains(row["NAME"]?.ToString(), searchText) ||
                SafeContains(row["REGISTRATIONDATE"]?.ToString(), searchText) ||
                SafeContains(row["PRODUCTGROUPNAME"]?.ToString(), searchText) ||
                SafeContains(row["SUPPORTEXPIRYDATE"]?.ToString(), searchText) ||
                SafeContains(row["FIRMWAREVERSION"]?.ToString(), searchText) ||
                SafeContains(row["CCNODECOUNT"]?.ToString(), searchText);

            if (!matchFound)
                return false;
        }

        // Apply firmware version filter
        if (!string.IsNullOrEmpty(request.FirmwareVersion))
        {
            string productFirmware = row["FIRMWAREVERSION"]?.ToString() ?? "";
            if (!productFirmware.Contains(request.FirmwareVersion, StringComparison.OrdinalIgnoreCase))
                return false;
        }

        // Apply registration date filter
        if (!string.IsNullOrEmpty(request.RegisteredOn))
        {
            if (!DateTime.TryParse(row["REGISTRATIONDATE"]?.ToString(), out DateTime regDate) ||
                !DateTime.TryParse(request.RegisteredOn, out DateTime filterDate))
                return false;
                
            if (regDate.Date != filterDate.Date)
                return false;
        }

        // Apply expiry date filter
        if (!string.IsNullOrEmpty(request.ExpiryDate))
        {
            if (!DateTime.TryParse(row["MINLICENSEEXPIRYDATE"]?.ToString(), out DateTime expDate) ||
                !DateTime.TryParse(request.ExpiryDate, out DateTime filterExpDate))
                return false;
                
            if (expDate.Date != filterExpDate.Date)
                return false;
        }

        return true;
    }

    private bool SafeContains(string source, string searchText)
    {
        return !string.IsNullOrEmpty(source) && 
               source.Contains(searchText, StringComparison.OrdinalIgnoreCase);
    }

    private ServiceLineItem CreateServiceLineItemFromDataRow(DataRow row, string renewaldays)
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

// ServiceLineItem class (assuming this exists)
public class ServiceLineItem
{
    public string serialNumber { get; set; }
    public string productName { get; set; }
    public string productFriendlyName { get; set; }
    public string productType { get; set; }
    public string firmwareVersion { get; set; }
    public string supportExpiryDate { get; set; }
    public string registeredOn { get; set; }
    public int zeroTouch { get; set; }
    public string tenantName { get; set; }
    public string tenantSerialNumber { get; set; }
    public long organizationId { get; set; }
    public string organizationName { get; set; }
    public string serviceId { get; set; }
    public string service { get; set; }
    public DateTime? licenseStartDate { get; set; }
    public DateTime? licenseExpiryDate { get; set; }
    public string nodeCount { get; set; }
    public int usedNodeCount { get; set; }
    public string status { get; set; }
    public bool isMonthlySubscription { get; set; }
    public bool isUpdateAvailable { get; set; }
    public int addressId { get; set; }
    public string productCount { get; set; }
    public bool? isHidden { get; set; }
    public bool? isHiddenServices { get; set; }
    public bool isAffiliated { get; set; }
    public bool isLicenseExpiry { get; set; }
    public string managedBy { get; set; }
    public bool isZTEnable { get; set; }
}