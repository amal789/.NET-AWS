using System;
using System.Data;

// =====================================================
// DEBUGGING UNIVERSAL SEARCH - TROUBLESHOOTING GUIDE
// =====================================================

public class UniversalSearchDebugger
{
    // *** WHAT PassesUniversalSearchFilter DOES ***
    /*
    The PassesUniversalSearchFilter method:
    
    1. Takes a DataRow and a search string (queryStr)
    2. Converts the search string to lowercase: "organisationgarg" → "organisationgarg"
    3. Checks if ANY of these 5 fields contains the search term:
       - PRODUCTGROUPNAME (TenantName)
       - NAME (FriendlyName) 
       - SERIALNUMBER
       - PRODUCTNAME
       - FIRMWAREVERSION
    4. Uses StringComparison.OrdinalIgnoreCase (case-insensitive)
    5. Returns TRUE if found in ANY field, FALSE if not found in any field
    */

    // DEBUG VERSION - Shows exactly what's happening
    private bool PassesUniversalSearchFilter_DEBUG(DataRow row, string queryStr)
    {
        Console.WriteLine("=== DEBUGGING UNIVERSAL SEARCH ===");
        Console.WriteLine($"Search Term: '{queryStr}'");
        
        // If no search query, pass all records
        if (string.IsNullOrEmpty(queryStr))
        {
            Console.WriteLine("No search term provided - returning TRUE");
            return true;
        }

        string searchQuery = queryStr.ToLower();
        Console.WriteLine($"Search Term (lowercase): '{searchQuery}'");
        
        // Get all field values
        string productGroupName = SafeGetString(row, "PRODUCTGROUPNAME");
        string friendlyName = SafeGetString(row, "NAME");
        string serialNumber = SafeGetString(row, "SERIALNUMBER");
        string productName = SafeGetString(row, "PRODUCTNAME");
        string firmwareVersion = SafeGetString(row, "FIRMWAREVERSION");
        
        // Debug output for each field
        Console.WriteLine("=== FIELD VALUES ===");
        Console.WriteLine($"1. TenantName (PRODUCTGROUPNAME): '{productGroupName}'");
        Console.WriteLine($"2. FriendlyName (NAME): '{friendlyName}'");
        Console.WriteLine($"3. SerialNumber: '{serialNumber}'");
        Console.WriteLine($"4. ProductName: '{productName}'");
        Console.WriteLine($"5. FirmwareVersion: '{firmwareVersion}'");
        
        // Check each field individually
        bool match1 = SafeContains(productGroupName, searchQuery);
        bool match2 = SafeContains(friendlyName, searchQuery);
        bool match3 = SafeContains(serialNumber, searchQuery);
        bool match4 = SafeContains(productName, searchQuery);
        bool match5 = SafeContains(firmwareVersion, searchQuery);
        
        Console.WriteLine("=== MATCH RESULTS ===");
        Console.WriteLine($"1. TenantName match: {match1}");
        Console.WriteLine($"2. FriendlyName match: {match2}");
        Console.WriteLine($"3. SerialNumber match: {match3}");
        Console.WriteLine($"4. ProductName match: {match4}");
        Console.WriteLine($"5. FirmwareVersion match: {match5}");
        
        bool finalResult = match1 || match2 || match3 || match4 || match5;
        Console.WriteLine($"=== FINAL RESULT: {finalResult} ===");
        Console.WriteLine();
        
        return finalResult;
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

    private bool SafeContains(string source, string searchText)
    {
        if (string.IsNullOrEmpty(source) || string.IsNullOrEmpty(searchText))
            return false;
            
        bool result = source.Contains(searchText, StringComparison.OrdinalIgnoreCase);
        Console.WriteLine($"   SafeContains('{source}', '{searchText}') = {result}");
        return result;
    }
}

// =====================================================
// POSSIBLE ISSUES WITH YOUR SEARCH
// =====================================================

/*
🔍 WHY "organisationgarg" MIGHT NOT BE FINDING RECORDS:

1. **EXACT SPELLING MISMATCH**
   - Search: "organisationgarg"
   - Actual: "organisationarg" (missing 'g')
   - Actual: "organization" (different spelling)
   - Actual: "org" (abbreviated)

2. **WHITESPACE/SPECIAL CHARACTERS**
   - Search: "organisationgarg"
   - Actual: "organisation garg" (space in between)
   - Actual: "organisation-garg" (hyphen)
   - Actual: "organisation_garg" (underscore)

3. **DATA NOT IN EXPECTED FIELD**
   - You expect it in FriendlyName (NAME field)
   - But it might be in ProductName or TenantName instead
   - Or the column mapping is different

4. **NULL/EMPTY VALUES**
   - The field might be NULL or empty in the database
   - SafeGetString returns "" for NULL values

5. **DATA FILTERING HAPPENING ELSEWHERE**
   - Records might be filtered out BEFORE reaching PassesUniversalSearchFilter
   - Check if the SQL stored procedure is already filtering them out
   - Check if other client-side filters are removing them

6. **DATABASE VS CLIENT-SIDE FILTERING**
   - The SQL stored procedure might be doing the filtering first
   - If SQL already removes records, they never reach the C# code
*/

// =====================================================
// DEBUGGING STEPS TO FIND THE ISSUE
// =====================================================

public class DebuggingSteps
{
    public void Step1_CheckRawData()
    {
        /*
        1. First, check what data is actually coming from the stored procedure:
        
        // In your C# code, add this debug output:
        if (objDS != null && objDS.Tables.Count > 0 && objDS.Tables[0].Rows.Count > 0)
        {
            Console.WriteLine($"Total rows from SP: {objDS.Tables[0].Rows.Count}");
            
            // Print first few rows to see actual data
            for (int i = 0; i < Math.Min(5, objDS.Tables[0].Rows.Count); i++)
            {
                var row = objDS.Tables[0].Rows[i];
                Console.WriteLine($"Row {i}:");
                Console.WriteLine($"  NAME: '{row["NAME"]}'");
                Console.WriteLine($"  PRODUCTGROUPNAME: '{row["PRODUCTGROUPNAME"]}'");
                Console.WriteLine($"  PRODUCTNAME: '{row["PRODUCTNAME"]}'");
                Console.WriteLine($"  SERIALNUMBER: '{row["SERIALNUMBER"]}'");
                Console.WriteLine($"  FIRMWAREVERSION: '{row["FIRMWAREVERSION"]}'");
            }
        }
        */
    }

    public void Step2_CheckSQLFiltering()
    {
        /*
        2. Check if SQL stored procedure is already filtering:
        
        Run these two SQL commands and compare results:
        
        -- Without universal search filter
        EXEC GETASSOCIATEDPRODUCTSWITHORDERLIST 
            @USERNAME = N'4_37687189',
            @QUERYSTR = NULL;  -- Should return all records
        
        -- With your search term
        EXEC GETASSOCIATEDPRODUCTSWITHORDERLIST 
            @USERNAME = N'4_37687189',
            @QUERYSTR = 'organisationgarg';  -- Should return filtered records
            
        Compare the row counts to see if SQL is doing the filtering.
        */
    }

    public void Step3_CheckActualFieldValues()
    {
        /*
        3. Search for partial matches to find the actual data:
        
        Try these searches to narrow down the issue:
        - queryStr = "org" (shorter term)
        - queryStr = "organisation" (without 'garg')
        - queryStr = "garg" (just the end part)
        - queryStr = "" (empty - should return all)
        
        This will help you see what's actually in the fields.
        */
    }

    public void Step4_UseDebugVersion()
    {
        /*
        4. Replace your PassesUniversalSearchFilter with the DEBUG version above
        
        This will show you:
        - Exact search term being used
        - Actual values in all 5 fields for each record
        - Which fields match and which don't
        - Final result for each record
        */
    }
}

// =====================================================
// IMPROVED UNIVERSAL SEARCH WITH BETTER DEBUGGING
// =====================================================

public class ImprovedUniversalSearch
{
    // Enhanced version with better error handling and debugging
    private bool PassesUniversalSearchFilter_Enhanced(DataRow row, string queryStr, bool enableDebug = false)
    {
        if (enableDebug)
            Console.WriteLine($"=== Searching for: '{queryStr}' ===");
            
        // If no search query, pass all records
        if (string.IsNullOrEmpty(queryStr?.Trim()))
        {
            if (enableDebug) Console.WriteLine("Empty search term - returning TRUE");
            return true;
        }

        string searchQuery = queryStr.Trim().ToLower();
        
        // Get all field values with null checking
        string[] fieldNames = { "PRODUCTGROUPNAME", "NAME", "SERIALNUMBER", "PRODUCTNAME", "FIRMWAREVERSION" };
        string[] friendlyNames = { "TenantName", "FriendlyName", "SerialNumber", "ProductName", "FirmwareVersion" };
        
        for (int i = 0; i < fieldNames.Length; i++)
        {
            string fieldValue = SafeGetString(row, fieldNames[i]);
            bool isMatch = !string.IsNullOrEmpty(fieldValue) && 
                          fieldValue.Contains(searchQuery, StringComparison.OrdinalIgnoreCase);
            
            if (enableDebug)
                Console.WriteLine($"{friendlyNames[i]}: '{fieldValue}' → Match: {isMatch}");
                
            if (isMatch)
            {
                if (enableDebug) Console.WriteLine($"✓ FOUND in {friendlyNames[i]}!");
                return true;
            }
        }
        
        if (enableDebug) Console.WriteLine("✗ NOT FOUND in any field");
        return false;
    }

    // Fuzzy search - finds partial matches even with typos
    private bool PassesUniversalSearchFilter_Fuzzy(DataRow row, string queryStr)
    {
        if (string.IsNullOrEmpty(queryStr?.Trim()))
            return true;

        string[] searchTerms = queryStr.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        string[] fieldNames = { "PRODUCTGROUPNAME", "NAME", "SERIALNUMBER", "PRODUCTNAME", "FIRMWAREVERSION" };
        
        // Check if ANY search term is found in ANY field
        foreach (string term in searchTerms)
        {
            foreach (string fieldName in fieldNames)
            {
                string fieldValue = SafeGetString(row, fieldName);
                if (!string.IsNullOrEmpty(fieldValue) && 
                    fieldValue.Contains(term, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
        }
        
        return false;
    }

    private string SafeGetString(DataRow row, string columnName)
    {
        try
        {
            object value = row[columnName];
            return value?.ToString()?.Trim() ?? "";
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error reading column '{columnName}': {ex.Message}");
            return "";
        }
    }
}

// =====================================================
// QUICK FIX SUGGESTIONS
// =====================================================

/*
🛠️ IMMEDIATE SOLUTIONS TO TRY:

1. **Try Shorter Search Terms**
   queryStr = "org"     // Instead of "organisationgarg"
   queryStr = "garg"    // Just the ending part

2. **Try Fuzzy Search**
   Split your search into words and search for each:
   "organisation garg" → searches for "organisation" OR "garg"

3. **Check SQL First**
   Run the SQL directly to see if data exists:
   SELECT * FROM #TEMPLISTTABLE WHERE NAME LIKE '%organisationgarg%'

4. **Use Debug Mode**
   enableDebug = true in the enhanced version above

5. **Check Column Names**
   Make sure the friendly name is really in the "NAME" column
   Maybe it's in "PRODUCTNAME" or "PRODUCTGROUPNAME" instead

6. **Remove Other Filters Temporarily**
   Comment out all other filters to test just the universal search
*/