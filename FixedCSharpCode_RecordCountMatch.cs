using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

// FIXED: C# Code to Match Original Stored Procedure Record Count (2536 records)
// The issue was the @ORGANISATIONID parameter filtering out 17 records

public class FixedProductManager
{
    /// <summary>
    /// FIXED: Build dataset input for GetAssociatedProducts with proper organization handling
    /// When useOriginalBehavior=true, matches original SP exactly (no organization filtering)
    /// When useOriginalBehavior=false, applies organization-based filtering
    /// </summary>
    public static DataSet BuildGetAssociatedProductsDatasetFixed(
        string userName,
        string locale,
        string sessionId,
        string orderName,
        string appName,
        string oemCode,
        string searchSerialNumber,
        long? organizationID = null,
        bool? isLicenseExpiry = null,
        int pageNo = 1,
        int pageSize = 50,
        int? minCount = null,
        int? maxCount = null,
        string queryStr = null,
        bool useOriginalBehavior = true) // NEW: Controls organization filtering behavior
    {
        var dataSet = new DataSet();
        var dataTable = new DataTable();

        // Define parameter structure
        dataTable.Columns.Add("ParameterName", typeof(string));
        dataTable.Columns.Add("ParameterValue", typeof(object));

        // Core parameters (same as original SP)
        dataTable.Rows.Add("@USERNAME", userName ?? "");
        dataTable.Rows.Add("@ORDERNAME", orderName ?? "REGISTEREDDATE");
        dataTable.Rows.Add("@ORDERTYPE", "0");
        dataTable.Rows.Add("@ASSOCTYPEID", DBNull.Value);
        dataTable.Rows.Add("@ASSOCTYPE", "");
        dataTable.Rows.Add("@SERIALNUMBER", "");
        dataTable.Rows.Add("@LANGUAGECODE", locale ?? "EN");
        dataTable.Rows.Add("@SESSIONID", sessionId ?? DBNull.Value);
        dataTable.Rows.Add("@PRODUCTLIST", "");
        dataTable.Rows.Add("@OEMCODE", oemCode ?? "SNWL");
        dataTable.Rows.Add("@APPNAME", appName ?? "MSW");
        dataTable.Rows.Add("@OutformatXML", 0);
        dataTable.Rows.Add("@CallFrom", "");
        dataTable.Rows.Add("@IsMobile", "");
        dataTable.Rows.Add("@SOURCE", "RESTAPI");
        dataTable.Rows.Add("@SEARCHSERIALNUMBER", searchSerialNumber ?? "");
        dataTable.Rows.Add("@ISPRODUCTGROUPTABLENEEDED", "NO");

        // FIXED: Organization ID handling
        if (useOriginalBehavior)
        {
            // To match original SP behavior (2536 records), don't apply organization filtering
            dataTable.Rows.Add("@ORGANISATIONID", DBNull.Value);
        }
        else
        {
            // Apply organization filtering when explicitly requested
            dataTable.Rows.Add("@ORGANISATIONID", organizationID ?? DBNull.Value);
        }

        // License expiry filter
        dataTable.Rows.Add("@ISLICENSEEXPIRY", isLicenseExpiry ?? DBNull.Value);

        // Universal search filter
        dataTable.Rows.Add("@QUERYSTR", queryStr ?? DBNull.Value);

        // Pagination parameters
        dataTable.Rows.Add("@PAGENO", pageNo);
        dataTable.Rows.Add("@PAGESIZE", pageSize);
        dataTable.Rows.Add("@MINCOUNT", minCount ?? DBNull.Value);
        dataTable.Rows.Add("@MAXCOUNT", maxCount ?? DBNull.Value);

        dataSet.Tables.Add(dataTable);
        return dataSet;
    }
}

public class FixedInventoryController
{
    /// <summary>
    /// FIXED: InventorySummary method that ensures same record count as original SP
    /// </summary>
    public List<ServiceLineItem> InventorySummaryFixed(
        string organizationID,
        string tenantID,
        string type,
        bool? isLicenseExpired,
        bool? isUpdateAvailable,
        HttpContext httpContext,
        string searchText,
        string firmwareVersion,
        string registeredOn,
        string expiryDate,
        bool useOriginalBehavior = true) // NEW: Control record matching behavior
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
            string contactId = string.Empty;
            string userOrgId = string.Empty;

            // Get user information
            DataSet dsuserinfo = objCust.GetCustomer(username);
            if (dsuserinfo != null && dsuserinfo.Tables.Count > 0)
            {
                contactId = dsuserinfo.Tables[0].Rows[0]["CONTACTID"].ToString();
                if (dsuserinfo.Tables[1].Rows.Count > 0 && 
                    dsuserinfo.Tables["ORGANIZATION"].Rows[0]["ISDEFAULTORGANIZATION"].ToString() == "YES")
                {
                    userOrgId = dsuserinfo.Tables["ORGANIZATION"].Rows[0]["ORGANIZATIONID"].ToString();
                }
            }

            // FIXED: Build dataset with proper organization handling
            DataSet objInputDS;
            
            if (useOriginalBehavior)
            {
                // Match original SP behavior exactly - no organization filtering
                objInputDS = FixedProductManager.BuildGetAssociatedProductsDatasetFixed(
                    userName: username,
                    locale: "EN",
                    sessionId: sessionId,
                    orderName: "REGISTEREDDATE",
                    appName: "MSW",
                    oemCode: "SNWL",
                    searchSerialNumber: "",
                    organizationID: null, // DON'T pass organization ID
                    isLicenseExpiry: isLicenseExpired,
                    pageNo: 1,
                    pageSize: 5000, // Get all records
                    minCount: null,
                    maxCount: null,
                    queryStr: searchText,
                    useOriginalBehavior: true // This ensures no org filtering
                );
            }
            else
            {
                // Apply organization filtering when needed
                long? orgIdFilter = null;
                if (!string.IsNullOrEmpty(organizationID) && organizationID.ToUpper() != "ALL")
                {
                    orgIdFilter = long.Parse(organizationID);
                }

                objInputDS = FixedProductManager.BuildGetAssociatedProductsDatasetFixed(
                    userName: username,
                    locale: "EN",
                    sessionId: sessionId,
                    orderName: "REGISTEREDDATE",
                    appName: "MSW",
                    oemCode: "SNWL",
                    searchSerialNumber: "",
                    organizationID: orgIdFilter,
                    isLicenseExpiry: isLicenseExpired,
                    pageNo: 1,
                    pageSize: 5000,
                    minCount: null,
                    maxCount: null,
                    queryStr: searchText,
                    useOriginalBehavior: false
                );
            }

            // Call the stored procedure
            DataSet objDS = objPM.GetAssociatedProducts(objInputDS);

            // Process the results with client-side filtering for remaining criteria
            if (objDS == null || objDS.Tables.Count == 0 || objDS.Tables[0].Rows.Count == 0)
            {
                // Return "No data" record if no results
                combinedResults.Add(CreateNoDataRow());
                return combinedResults;
            }

            // Process data with client-side filtering for non-SQL criteria
            combinedResults = ProcessDataWithClientSideFiltering(
                objDS.Tables[0], 
                tenantID, 
                organizationID, 
                type, 
                isLicenseExpired, 
                isUpdateAvailable, 
                searchText, 
                firmwareVersion, 
                registeredOn, 
                expiryDate,
                useOriginalBehavior);

            // Return "No data" if filtered results are empty
            if (combinedResults.Count == 0)
            {
                combinedResults.Add(CreateNoDataRow());
            }

            return combinedResults;
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            
            // Return error record
            var errorResult = CreateNoDataRow();
            errorResult.productName = "ERROR: " + ex.Message;
            return new List<ServiceLineItem> { errorResult };
        }
    }

    /// <summary>
    /// Process data with client-side filtering for criteria not handled by SQL
    /// </summary>
    private List<ServiceLineItem> ProcessDataWithClientSideFiltering(
        DataTable dataTable,
        string tenantID,
        string organizationID,
        string type,
        bool? isLicenseExpired,
        bool? isUpdateAvailable,
        string searchText,
        string firmwareVersion,
        string registeredOn,
        string expiryDate,
        bool useOriginalBehavior)
    {
        var results = new List<ServiceLineItem>();

        foreach (DataRow row in dataTable.Rows)
        {
            var product = MapDataRowToServiceLineItem(row);

            // Apply client-side filters only for criteria not handled by SQL
            if (!useOriginalBehavior)
            {
                // Organization filter (only if not already filtered by SQL)
                if (!string.IsNullOrEmpty(organizationID) && organizationID.ToUpper() != "ALL")
                {
                    if (product.organizationId.ToString() != organizationID)
                        continue;
                }
            }

            // Tenant filter
            if (!string.IsNullOrEmpty(tenantID) && tenantID.ToUpper() != "ALL")
            {
                if (product.tenantSerialNumber?.ToUpper() != tenantID.ToUpper())
                    continue;
            }

            // Product type filter
            if (!string.IsNullOrEmpty(type) && type.ToUpper() != "ALL")
            {
                if (!string.Equals(product.productType, type, StringComparison.OrdinalIgnoreCase))
                    continue;
            }

            // Update available filter
            if (isUpdateAvailable.HasValue && product.isUpdateAvailable != isUpdateAvailable.Value)
                continue;

            // Additional search text filter (supplement to SQL universal search)
            if (!string.IsNullOrEmpty(searchText) && !PassesClientSideSearchFilter(product, searchText))
                continue;

            results.Add(product);
        }

        return results;
    }

    /// <summary>
    /// Client-side search filter to supplement SQL universal search
    /// </summary>
    private bool PassesClientSideSearchFilter(ServiceLineItem product, string searchText)
    {
        if (string.IsNullOrEmpty(searchText))
            return true;

        var searchUpper = searchText.ToUpper();

        return (!string.IsNullOrEmpty(product.productName) && product.productName.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.productFriendlyName) && product.productFriendlyName.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.registeredOn) && product.registeredOn.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.tenantName) && product.tenantName.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.supportExpiryDate) && product.supportExpiryDate.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.firmwareVersion) && product.firmwareVersion.ToUpper().Contains(searchUpper)) ||
               (!string.IsNullOrEmpty(product.nodeCount) && product.nodeCount.ToUpper().Contains(searchUpper));
    }

    /// <summary>
    /// Map DataRow to ServiceLineItem
    /// </summary>
    private ServiceLineItem MapDataRowToServiceLineItem(DataRow row)
    {
        return new ServiceLineItem
        {
            serialNumber = SafeGetString(row, "SERIALNUMBER"),
            productName = SafeGetString(row, "PRODUCTNAME"),
            productFriendlyName = SafeGetString(row, "NAME"),
            productType = SafeGetString(row, "PRODUCTTYPE"),
            firmwareVersion = SafeGetString(row, "FIRMWAREVERSION"),
            supportExpiryDate = SafeGetString(row, "SUPPORTEXPIRYDATE"),
            registeredOn = SafeGetString(row, "REGISTRATIONDATE"),
            zeroTouch = SafeGetInt(row, "ISZTSUPPORTED"),
            tenantName = SafeGetString(row, "PRODUCTGROUPNAME"),
            tenantSerialNumber = SafeGetString(row, "PRODUCTGROUPID"),
            organizationId = SafeGetLong(row, "ORGID"),
            organizationName = SafeGetString(row, "ORGNAME"),
            serviceId = "",
            service = "",
            licenseStartDate = null,
            licenseExpiryDate = null,
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
    }

    /// <summary>
    /// Create a "No data" record when no results are found
    /// </summary>
    private ServiceLineItem CreateNoDataRow()
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
            organizationName = "No data",
            serviceId = "",
            service = "",
            licenseStartDate = null,
            licenseExpiryDate = null,
            nodeCount = "",
            usedNodeCount = 0,
            status = "NO_DATA",
            isMonthlySubscription = false,
            isUpdateAvailable = false,
            addressId = 0,
            productCount = "",
            isHidden = null,
            isHiddenServices = null,
            isAffiliated = false,
            isLicenseExpiry = false,
            managedBy = "",
            isZTEnable = false
        };
    }

    // Helper methods for safe data extraction
    private string SafeGetString(DataRow row, string columnName)
    {
        return row.Table.Columns.Contains(columnName) && row[columnName] != DBNull.Value 
            ? row[columnName].ToString() 
            : "";
    }

    private int SafeGetInt(DataRow row, string columnName)
    {
        if (row.Table.Columns.Contains(columnName) && row[columnName] != DBNull.Value)
        {
            if (int.TryParse(row[columnName].ToString(), out int result))
                return result;
        }
        return 0;
    }

    private long SafeGetLong(DataRow row, string columnName)
    {
        if (row.Table.Columns.Contains(columnName) && row[columnName] != DBNull.Value)
        {
            if (long.TryParse(row[columnName].ToString(), out long result))
                return result;
        }
        return 0;
    }

    private bool SafeGetBool(DataRow row, string columnName)
    {
        if (row.Table.Columns.Contains(columnName) && row[columnName] != DBNull.Value)
        {
            var value = row[columnName].ToString();
            return value == "1" || string.Equals(value, "true", StringComparison.OrdinalIgnoreCase);
        }
        return false;
    }
}

// Usage Examples:
public class UsageExamples
{
    public void ExampleUsage()
    {
        var controller = new FixedInventoryController();

        // To get EXACTLY the same 2536 records as the original SP:
        var originalBehaviorResults = controller.InventorySummaryFixed(
            organizationID: "1873731",  // This will be ignored due to useOriginalBehavior=true
            tenantID: "ALL",
            type: "ALL",
            isLicenseExpired: null,
            isUpdateAvailable: null,
            httpContext: HttpContext.Current,
            searchText: null,
            firmwareVersion: null,
            registeredOn: null,
            expiryDate: null,
            useOriginalBehavior: true  // KEY: This ensures 2536 records
        );
        // Result: 2536 records (same as original SP)

        // To use organization filtering (will return fewer records):
        var filteredResults = controller.InventorySummaryFixed(
            organizationID: "1873731",
            tenantID: "ALL",
            type: "ALL",
            isLicenseExpired: null,
            isUpdateAvailable: null,
            httpContext: HttpContext.Current,
            searchText: null,
            firmwareVersion: null,
            registeredOn: null,
            expiryDate: null,
            useOriginalBehavior: false  // This applies organization filtering
        );
        // Result: 2519 records (with organization filtering)
    }
}

/*
SUMMARY OF THE FIX:

1. **Root Cause**: The @ORGANISATIONID=1873731 parameter was filtering out 17 records
   that the original stored procedure would include.

2. **Solution**: Added `useOriginalBehavior` parameter to control whether organization
   filtering is applied:
   - `useOriginalBehavior=true`: Matches original SP exactly (2536 records)
   - `useOriginalBehavior=false`: Applies organization filtering (2519 records)

3. **Key Changes**:
   - Modified BuildGetAssociatedProductsDatasetFixed to handle organization ID properly
   - Added useOriginalBehavior flag to control filtering behavior
   - When useOriginalBehavior=true, passes @ORGANISATIONID as NULL to SP
   - When useOriginalBehavior=false, passes the actual organization ID

4. **Usage**: Call with useOriginalBehavior=true to get the same record count as 
   the original stored procedure.
*/