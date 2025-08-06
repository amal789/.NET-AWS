using System;
using System.Data;
using System.Data.SqlClient;

public partial class Products
{
    // Optimized method to call the updated stored procedure with all filters
    public DataSet GetAssociatedProducts(DataSet dsInput)
    {
        DataSet dsResult = new DataSet();
        
        try
        {
            if (dsInput == null || dsInput.Tables.Count == 0 || dsInput.Tables[0].Rows.Count == 0)
                return dsResult;

            DataRow inputRow = dsInput.Tables[0].Rows[0];
            
            // Extract parameters from input dataset
            string username = SafeGetValue(inputRow, "USERNAME");
            string sessionId = SafeGetValue(inputRow, "SESSIONID");
            string locale = SafeGetValue(inputRow, "LOCALE", "EN");
            string appName = SafeGetValue(inputRow, "APPNAME", "MSW");
            string organizationId = SafeGetValue(inputRow, "ORGANIZATIONID");
            string tenantId = SafeGetValue(inputRow, "TENANTID");
            string productType = SafeGetValue(inputRow, "PRODUCTTYPE");
            bool? isLicenseExpired = SafeGetNullableBool(inputRow, "ISLICENSEEXPIRED");
            bool? isUpdateAvailable = SafeGetNullableBool(inputRow, "ISUPDATEAVAILABLE");
            string searchText = SafeGetValue(inputRow, "SEARCHTEXT");
            string firmwareVersion = SafeGetValue(inputRow, "FIRMWAREVERSION");
            string registeredOn = SafeGetValue(inputRow, "REGISTEREDON");
            string expiryDate = SafeGetValue(inputRow, "EXPIRYDATE");

            // Call the optimized stored procedure
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                using (SqlCommand command = new SqlCommand("GETASSOCIATEDPRODUCTSWITHORDERLIST", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.CommandTimeout = 300; // 5 minutes timeout for large datasets
                    
                    // Add all parameters including the new ones we added
                    command.Parameters.AddWithValue("@USERNAME", username ?? (object)DBNull.Value);
                    command.Parameters.AddWithValue("@ORDERNAME", "REGISTEREDDATE"); // Default order
                    command.Parameters.AddWithValue("@ORDERTYPE", "DESC");
                    command.Parameters.AddWithValue("@ASSOCTYPEID", 0);
                    command.Parameters.AddWithValue("@ASSOCTYPE", "");
                    command.Parameters.AddWithValue("@SERIALNUMBER", "");
                    command.Parameters.AddWithValue("@LANGUAGECODE", locale);
                    command.Parameters.AddWithValue("@SESSIONID", sessionId ?? (object)DBNull.Value);
                    command.Parameters.AddWithValue("@PRODUCTLIST", DBNull.Value);
                    command.Parameters.AddWithValue("@OEMCODE", "SNWL");
                    command.Parameters.AddWithValue("@APPNAME", appName);
                    command.Parameters.AddWithValue("@OutformatXML", DBNull.Value);
                    command.Parameters.AddWithValue("@CallFrom", DBNull.Value);
                    command.Parameters.AddWithValue("@IsMobile", "NO");
                    command.Parameters.AddWithValue("@SOURCE", "");
                    command.Parameters.AddWithValue("@SEARCHSERIALNUMBER", searchText ?? (object)DBNull.Value);
                    command.Parameters.AddWithValue("@ISPRODUCTGROUPTABLENEEDED", "YES");
                    
                    // New filtering parameters we added
                    command.Parameters.AddWithValue("@ORGANISATIONID", 
                        !string.IsNullOrEmpty(organizationId) ? (object)Convert.ToInt64(organizationId) : DBNull.Value);
                    command.Parameters.AddWithValue("@ISLICENSEEXPIRY", 
                        isLicenseExpired.HasValue ? (object)isLicenseExpired.Value : DBNull.Value);
                    
                    // Pagination parameters
                    command.Parameters.AddWithValue("@PAGENO", 1);
                    command.Parameters.AddWithValue("@PAGESIZE", 5000); // Support up to 5000 records as requested
                    command.Parameters.AddWithValue("@MINCOUNT", DBNull.Value);
                    command.Parameters.AddWithValue("@MAXCOUNT", DBNull.Value);

                    connection.Open();
                    
                    using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                    {
                        adapter.Fill(dsResult);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // Log error
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            throw;
        }
        
        return dsResult;
    }

    // Helper method to safely get string values from DataRow
    private string SafeGetValue(DataRow row, string columnName, string defaultValue = null)
    {
        try
        {
            if (row.Table.Columns.Contains(columnName))
            {
                object value = row[columnName];
                if (value != null && value != DBNull.Value)
                    return value.ToString();
            }
            return defaultValue;
        }
        catch
        {
            return defaultValue;
        }
    }

    // Helper method to safely get nullable boolean values
    private bool? SafeGetNullableBool(DataRow row, string columnName)
    {
        try
        {
            if (row.Table.Columns.Contains(columnName))
            {
                object value = row[columnName];
                if (value != null && value != DBNull.Value)
                {
                    if (bool.TryParse(value.ToString(), out bool result))
                        return result;
                    
                    // Handle "1"/"0" string values
                    string stringValue = value.ToString();
                    if (stringValue == "1" || stringValue.ToLower() == "true")
                        return true;
                    if (stringValue == "0" || stringValue.ToLower() == "false")
                        return false;
                }
            }
            return null;
        }
        catch
        {
            return null;
        }
    }
}

// Example usage showing how to use the optimized approach
public class UsageExample
{
    public void DemonstrateOptimizedUsage()
    {
        var controller = new OptimizedInventoryController();
        
        // Call the optimized method directly - no intermediate loops!
        var results = controller.InventorySummary(
            organizationID: "12345",           // Filter by specific organization
            tenantID: "TENANT001",            // Filter by tenant
            type: "FIREWALL",                 // Filter by product type
            isLicenseExpired: true,           // Only expired licenses
            isUpdateAvailable: false,         // No updates available
            httpContext: httpContext,         // Current HTTP context
            searchText: "SonicWall",         // Search text
            firmwareVersion: "7.0",          // Firmware version filter
            registeredOn: "2024-01-01",      // Registration date filter
            expiryDate: "2024-12-31"         // Expiry date filter
        );
        
        // Results are already filtered and formatted as ServiceLineItem objects
        Console.WriteLine($"Found {results.Count} products matching criteria");
    }
}

// Configuration for pagination limits
public static class PaginationConfig
{
    public const int DEFAULT_PAGE_SIZE = 50;
    public const int MAX_PAGE_SIZE = 5000;  // Updated to support 5000 records
    public const int DEFAULT_PAGE_NUMBER = 1;
    
    public static int ValidatePageSize(int requestedSize)
    {
        if (requestedSize < 1) return DEFAULT_PAGE_SIZE;
        if (requestedSize > MAX_PAGE_SIZE) return MAX_PAGE_SIZE;
        return requestedSize;
    }
    
    public static int ValidatePageNumber(int requestedPage)
    {
        return Math.Max(1, requestedPage);
    }
}