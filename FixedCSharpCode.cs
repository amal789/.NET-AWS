using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

// =====================================================
// C# CODE FIX - Add Missing Parameters
// =====================================================

public DataSet GetAssociatedProducts(DataSet objInputDS)
{
    DataSet objResult = new DataSet();
    DataAccessHandler DAL = new DataAccessHandler();
    
    // ... existing variable declarations ...
    String strSerialNumber = "";
    String strOrderName = "";
    String strUserName = "";
    // ... (keep all your existing variables)
    
    // ADD THESE NEW VARIABLES for the missing parameters:
    string strSource = "";
    string strIsProductGroupTableNeeded = "";
    string strOrganizationID = "";
    string strIsLicenseExpiry = "";
    string strPageNo = "";
    string strPageSize = "";
    string strMinCount = "";
    string strMaxCount = "";
    
    try
    {
        // ... your existing parameter extraction code ...
        strUserName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "USERNAME", "");
        strOrderName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ORDERNAME", "");
        // ... (keep all your existing extractions)
        
        // ADD THESE NEW PARAMETER EXTRACTIONS:
        strSource = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "SOURCE", "");
        strIsProductGroupTableNeeded = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ISPRODUCTGROUPTABLENEEDED", "YES");
        strOrganizationID = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ORGANIZATIONID", "");
        strIsLicenseExpiry = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ISLICENSEEXPIRY", "");
        strPageNo = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "PAGENO", "1");
        strPageSize = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "PAGESIZE", "50");
        strMinCount = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "MINCOUNT", "");
        strMaxCount = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "MAXCOUNT", "");

        // ... your existing parameter setup code ...
        List<SqlParameter> lst = new List<SqlParameter>();
        
        // ... add all your existing parameters (sqlParam1 through sqlParam16) ...
        
        // ADD THESE NEW PARAMETERS TO YOUR LIST:
        
        // SOURCE parameter (already exists in your code, but make sure it's always added)
        SqlParameter sqlParamSource = new SqlParameter("@SOURCE", SqlDbType.VarChar);
        sqlParamSource.Size = 10;
        sqlParamSource.Value = string.IsNullOrEmpty(strSource) ? "" : strSource;
        lst.Add(sqlParamSource);

        // ISPRODUCTGROUPTABLENEEDED parameter
        SqlParameter sqlParamProductGroup = new SqlParameter("@ISPRODUCTGROUPTABLENEEDED", SqlDbType.VarChar);
        sqlParamProductGroup.Size = 10;
        sqlParamProductGroup.Value = strIsProductGroupTableNeeded;
        lst.Add(sqlParamProductGroup);

        // ORGANISATIONID parameter
        SqlParameter sqlParamOrgID = new SqlParameter("@ORGANISATIONID", SqlDbType.BigInt);
        if (String.IsNullOrEmpty(strOrganizationID))
            sqlParamOrgID.Value = System.Data.SqlTypes.SqlInt64.Null;
        else
            sqlParamOrgID.Value = System.Convert.ToInt64(strOrganizationID);
        lst.Add(sqlParamOrgID);

        // ISLICENSEEXPIRY parameter
        SqlParameter sqlParamLicenseExpiry = new SqlParameter("@ISLICENSEEXPIRY", SqlDbType.Bit);
        if (String.IsNullOrEmpty(strIsLicenseExpiry))
            sqlParamLicenseExpiry.Value = System.Data.SqlTypes.SqlBoolean.Null;
        else
        {
            if (strIsLicenseExpiry.ToLower() == "true" || strIsLicenseExpiry == "1")
                sqlParamLicenseExpiry.Value = true;
            else if (strIsLicenseExpiry.ToLower() == "false" || strIsLicenseExpiry == "0")
                sqlParamLicenseExpiry.Value = false;
            else
                sqlParamLicenseExpiry.Value = System.Data.SqlTypes.SqlBoolean.Null;
        }
        lst.Add(sqlParamLicenseExpiry);

        // PAGENO parameter
        SqlParameter sqlParamPageNo = new SqlParameter("@PAGENO", SqlDbType.Int);
        if (String.IsNullOrEmpty(strPageNo))
            sqlParamPageNo.Value = 1;
        else
        {
            if (int.TryParse(strPageNo, out int pageNo) && pageNo >= 1)
                sqlParamPageNo.Value = pageNo;
            else
                sqlParamPageNo.Value = 1;
        }
        lst.Add(sqlParamPageNo);

        // PAGESIZE parameter
        SqlParameter sqlParamPageSize = new SqlParameter("@PAGESIZE", SqlDbType.Int);
        if (String.IsNullOrEmpty(strPageSize))
            sqlParamPageSize.Value = 50;
        else
        {
            if (int.TryParse(strPageSize, out int pageSize) && pageSize >= 1 && pageSize <= 5000)
                sqlParamPageSize.Value = pageSize;
            else
                sqlParamPageSize.Value = 50;
        }
        lst.Add(sqlParamPageSize);

        // MINCOUNT parameter
        SqlParameter sqlParamMinCount = new SqlParameter("@MINCOUNT", SqlDbType.Int);
        if (String.IsNullOrEmpty(strMinCount))
            sqlParamMinCount.Value = System.Data.SqlTypes.SqlInt32.Null;
        else
        {
            if (int.TryParse(strMinCount, out int minCount) && minCount >= 0)
                sqlParamMinCount.Value = minCount;
            else
                sqlParamMinCount.Value = System.Data.SqlTypes.SqlInt32.Null;
        }
        lst.Add(sqlParamMinCount);

        // MAXCOUNT parameter
        SqlParameter sqlParamMaxCount = new SqlParameter("@MAXCOUNT", SqlDbType.Int);
        if (String.IsNullOrEmpty(strMaxCount))
            sqlParamMaxCount.Value = System.Data.SqlTypes.SqlInt32.Null;
        else
        {
            if (int.TryParse(strMaxCount, out int maxCount) && maxCount >= 0)
                sqlParamMaxCount.Value = maxCount;
            else
                sqlParamMaxCount.Value = System.Data.SqlTypes.SqlInt32.Null;
        }
        lst.Add(sqlParamMaxCount);

        // Execute the stored procedure
        objResult = DAL.ExecuteSQLDataSet("GETASSOCIATEDPRODUCTSWITHORDERLIST", lst);
        objResult.Tables.Add(Helper.BuildDefaultSuccessStatus());

    }
    catch (Exception ex)
    {
        // ... your existing error handling ...
    }
    
    return objResult;
}