// =====================================================
// QUICK DEBUG PATCH - ADD THIS TO YOUR EXISTING CODE
// =====================================================

// 🔍 WHAT PassesUniversalSearchFilter DOES:
/*
1. Takes your search term: "organisationgarg"
2. Converts to lowercase: "organisationgarg"
3. Checks if ANY of these 5 fields contains the term:
   - PRODUCTGROUPNAME (TenantName)
   - NAME (FriendlyName) ← You expect it to be here
   - SERIALNUMBER
   - PRODUCTNAME
   - FIRMWAREVERSION
4. Returns TRUE if found in any field, FALSE if not found
*/

// ⚠️ LIKELY ISSUES WITH "organisationgarg":

/*
1. SPELLING MISMATCH:
   - You search: "organisationgarg"
   - Actual data: "organisation garg" (with space)
   - Actual data: "organization" (American spelling)
   - Actual data: "org-garg" (with hyphen)

2. DATA IS IN DIFFERENT FIELD:
   - You expect in FriendlyName (NAME)
   - But it's actually in TenantName (PRODUCTGROUPNAME)
   - Or in ProductName (PRODUCTNAME)

3. SQL FILTERING FIRST:
   - SQL stored procedure already filtered out the records
   - Records never reach the C# PassesUniversalSearchFilter method
*/

// 🛠️ IMMEDIATE DEBUG STEPS:

// Step 1: Add this debug code RIGHT AFTER you get data from stored procedure
public void DebugStep1_CheckRawData(DataSet objDS)
{
    if (objDS != null && objDS.Tables.Count > 0 && objDS.Tables[0].Rows.Count > 0)
    {
        Console.WriteLine($"=== RAW DATA FROM SQL ===");
        Console.WriteLine($"Total rows from stored procedure: {objDS.Tables[0].Rows.Count}");
        
        // Check first 3 rows for your search term
        for (int i = 0; i < Math.Min(3, objDS.Tables[0].Rows.Count); i++)
        {
            var row = objDS.Tables[0].Rows[i];
            Console.WriteLine($"\nRow {i + 1}:");
            Console.WriteLine($"  FriendlyName (NAME): '{row["NAME"]}'");
            Console.WriteLine($"  TenantName (PRODUCTGROUPNAME): '{row["PRODUCTGROUPNAME"]}'");
            Console.WriteLine($"  ProductName: '{row["PRODUCTNAME"]}'");
            Console.WriteLine($"  SerialNumber: '{row["SERIALNUMBER"]}'");
            Console.WriteLine($"  FirmwareVersion: '{row["FIRMWAREVERSION"]}'");
            
            // Check if any field contains your search term
            string searchTerm = "organisationgarg";
            bool foundInName = row["NAME"]?.ToString()?.ToLower().Contains(searchTerm.ToLower()) ?? false;
            bool foundInTenant = row["PRODUCTGROUPNAME"]?.ToString()?.ToLower().Contains(searchTerm.ToLower()) ?? false;
            bool foundInProduct = row["PRODUCTNAME"]?.ToString()?.ToLower().Contains(searchTerm.ToLower()) ?? false;
            
            if (foundInName || foundInTenant || foundInProduct)
            {
                Console.WriteLine($"  ✓ FOUND '{searchTerm}' in this row!");
            }
        }
    }
    else
    {
        Console.WriteLine("⚠️ NO DATA returned from stored procedure!");
    }
}

// Step 2: Replace your PassesUniversalSearchFilter with this DEBUG version
private bool PassesUniversalSearchFilter_DEBUG(DataRow row, string queryStr)
{
    Console.WriteLine($"\n=== TESTING ROW FOR: '{queryStr}' ===");
    
    if (string.IsNullOrEmpty(queryStr))
        return true;

    string searchQuery = queryStr.ToLower();
    
    // Get all field values
    string tenantName = row["PRODUCTGROUPNAME"]?.ToString() ?? "";
    string friendlyName = row["NAME"]?.ToString() ?? "";
    string serialNumber = row["SERIALNUMBER"]?.ToString() ?? "";
    string productName = row["PRODUCTNAME"]?.ToString() ?? "";
    string firmwareVersion = row["FIRMWAREVERSION"]?.ToString() ?? "";
    
    Console.WriteLine($"TenantName: '{tenantName}'");
    Console.WriteLine($"FriendlyName: '{friendlyName}'");
    Console.WriteLine($"SerialNumber: '{serialNumber}'");
    Console.WriteLine($"ProductName: '{productName}'");
    Console.WriteLine($"FirmwareVersion: '{firmwareVersion}'");
    
    // Check each field
    bool match1 = !string.IsNullOrEmpty(tenantName) && tenantName.ToLower().Contains(searchQuery);
    bool match2 = !string.IsNullOrEmpty(friendlyName) && friendlyName.ToLower().Contains(searchQuery);
    bool match3 = !string.IsNullOrEmpty(serialNumber) && serialNumber.ToLower().Contains(searchQuery);
    bool match4 = !string.IsNullOrEmpty(productName) && productName.ToLower().Contains(searchQuery);
    bool match5 = !string.IsNullOrEmpty(firmwareVersion) && firmwareVersion.ToLower().Contains(searchQuery);
    
    Console.WriteLine($"Match in TenantName: {match1}");
    Console.WriteLine($"Match in FriendlyName: {match2}");
    Console.WriteLine($"Match in SerialNumber: {match3}");
    Console.WriteLine($"Match in ProductName: {match4}");
    Console.WriteLine($"Match in FirmwareVersion: {match5}");
    
    bool result = match1 || match2 || match3 || match4 || match5;
    Console.WriteLine($"FINAL RESULT: {result}");
    
    return result;
}

// Step 3: Test with different search terms
public void TestDifferentSearchTerms()
{
    /*
    Try these search terms to narrow down the issue:
    
    1. queryStr = ""                 // Empty - should return all records
    2. queryStr = "org"              // Short term
    3. queryStr = "organisation"     // Without "garg"
    4. queryStr = "garg"             // Just the ending
    5. queryStr = "organisation garg" // With space
    6. queryStr = "organization"     // American spelling
    
    This will help you find the exact spelling in your data.
    */
}

// Step 4: Check if SQL is doing the filtering
public void TestSQLFiltering()
{
    /*
    Run these SQL commands to test:
    
    -- Test 1: Get all records (no filter)
    EXEC GETASSOCIATEDPRODUCTSWITHORDERLIST 
        @USERNAME = N'4_37687189',
        @QUERYSTR = NULL;
    
    -- Test 2: Search for your term
    EXEC GETASSOCIATEDPRODUCTSWITHORDERLIST 
        @USERNAME = N'4_37687189',
        @QUERYSTR = 'organisationgarg';
    
    -- Test 3: Search for shorter term
    EXEC GETASSOCIATEDPRODUCTSWITHORDERLIST 
        @USERNAME = N'4_37687189',
        @QUERYSTR = 'org';
        
    Compare the row counts. If Test 1 returns 100 rows but Test 2 returns 0,
    then SQL is filtering out your records before they reach C#.
    */
}

// =====================================================
// MOST LIKELY FIXES
// =====================================================

/*
🎯 MOST LIKELY ISSUE: Your data probably contains:
   - "organisation garg" (with space)
   - "organization" (American spelling)
   - "org garg" (abbreviated)

🛠️ QUICK FIXES TO TRY:

1. Use shorter search term:
   queryStr = "org"

2. Use fuzzy search:
   Split "organisation garg" and search for either word

3. Check actual data:
   Add the debug code above to see what's really in the fields

4. Test SQL directly:
   Run the SQL commands to see if filtering happens in database
*/

// Example of fuzzy search fix:
private bool PassesUniversalSearchFilter_Fuzzy(DataRow row, string queryStr)
{
    if (string.IsNullOrEmpty(queryStr))
        return true;

    // Split search terms and check if ANY word is found in ANY field
    string[] searchWords = queryStr.ToLower().Split(new char[] { ' ', '-', '_' }, StringSplitOptions.RemoveEmptyEntries);
    string[] fields = { 
        row["PRODUCTGROUPNAME"]?.ToString() ?? "",
        row["NAME"]?.ToString() ?? "",
        row["SERIALNUMBER"]?.ToString() ?? "",
        row["PRODUCTNAME"]?.ToString() ?? "",
        row["FIRMWAREVERSION"]?.ToString() ?? ""
    };

    foreach (string word in searchWords)
    {
        foreach (string field in fields)
        {
            if (!string.IsNullOrEmpty(field) && field.ToLower().Contains(word))
            {
                return true; // Found at least one word in at least one field
            }
        }
    }

    return false;
}