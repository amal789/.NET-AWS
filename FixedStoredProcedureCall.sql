-- =====================================================
-- ISSUE ANALYSIS AND FIX
-- =====================================================

-- ❌ BROKEN CALL (From your code - missing new parameters):
/*
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER=''
    -- MISSING: SOURCE, ISPRODUCTGROUPTABLENEEDED, ORGANISATIONID, ISLICENSEEXPIRY, PAGENO, PAGESIZE, MINCOUNT, MAXCOUNT
*/

-- ✅ FIXED CALL (Add missing parameters):
exec GETASSOCIATEDPRODUCTSWITHORDERLIST 
    @USERNAME=N'4_37687189',
    @ORDERNAME='REGISTEREDDATE',
    @ORDERTYPE='',
    @ASSOCTYPEID=NULL,
    @ASSOCTYPE='',
    @SERIALNUMBER='',
    @LANGUAGECODE='EN',
    @SESSIONID=NULL,
    @PRODUCTLIST='',
    @OEMCODE='SNWL',
    @APPNAME='MSW',
    @OutformatXML=0,
    @CallFrom='',
    @IsMobile='',
    @SEARCHSERIALNUMBER='',
    -- ADD THESE MISSING PARAMETERS:
    @SOURCE='',                           -- Add this
    @ISPRODUCTGROUPTABLENEEDED='YES',     -- Add this
    @ORGANISATIONID=NULL,                 -- Add this
    @ISLICENSEEXPIRY=NULL,                -- Add this
    @PAGENO=1,                           -- Add this
    @PAGESIZE=50,                        -- Add this (or 5000 for more records)
    @MINCOUNT=NULL,                      -- Add this
    @MAXCOUNT=NULL;                      -- Add this

-- =====================================================
-- ROOT CAUSE: Missing Parameters in C# Code
-- =====================================================

/*
PROBLEM: Your C# code is not passing the new parameters we added to the stored procedure.
When you added the new parameters to the stored procedure, you need to also update 
the C# code to pass these parameters.

CURRENT C# CODE ISSUE:
- Your DataAccessHandler is only passing the old parameters
- The new parameters (SOURCE, ISPRODUCTGROUPTABLENEEDED, etc.) are missing
- SQL Server requires ALL parameters to be provided for stored procedures
*/