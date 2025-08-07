using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

public class ProductManager
{
    public DataSet GetAssociatedProducts(DataSet objInputDS)
    {
        DataSet objResult = new DataSet();

        DataAccessHandler DAL = new DataAccessHandler();
        String strSerialNumber = "";
        String strOrderName = "";
        String strUserName = "";
        String strOrderType = "";
        String strAppName = "";
        String strLangCode = "";
        String strAssocTypeID = "";
        String strAssocType = "";
        String strSessionID = "";
        String strOemCode = "";
        String strProductList = "";
        String strCallFrom = "";
        String strismobile = "";
        string strSource = "";
        string strSearchSerial = "";
        string strIsProductGroupTableNeeded = "";
        
        // New filtering and pagination parameters
        string strOrganizationID = "";
        string strIsLicenseExpiry = "";
        string strPageNo = "";
        string strPageSize = "";
        string strMinCount = "";
        string strMaxCount = "";
        
        try
        {
            // Existing parameter extraction
            strUserName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "USERNAME", "");
            strOrderName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ORDERNAME", "");
            strOrderType = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ORDERTYPE", "");
            strAssocTypeID = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ASSOCTYPEID", "");
            strAssocType = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ASSOCTYPE", "");
            strSerialNumber = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "SERIALNUMBER", "");
            strLangCode = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "LANGUAGECODE", "EN");
            strSessionID = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "SESSIONID", "");
            strProductList = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "PRODUCTLIST", "");
            strOemCode = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "OEMCODE", "SNWL");
            strAppName = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "APPNAME", "MSW");
            strCallFrom = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "CALLFROM", "");
            strismobile = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ISMOBILE", "");
            strSource = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "SOURCE", "");
            strSearchSerial = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "SEARCHSERIALNUMBER", "");
            strIsProductGroupTableNeeded = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ISPRODUCTGROUPTABLENEEDED", "YES");
            
            // New parameter extraction
            strOrganizationID = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ORGANIZATIONID", "");
            strIsLicenseExpiry = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "ISLICENSEEXPIRY", "");
            strPageNo = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "PAGENO", "1");
            strPageSize = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "PAGESIZE", "50");
            strMinCount = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "MINCOUNT", "");
            strMaxCount = Helper.GetColValFrmDataSet(objInputDS, "INPUT", "MAXCOUNT", "");

            if (String.IsNullOrEmpty(strOemCode))
                strOemCode = "SNWL";

            if (String.IsNullOrEmpty(strLangCode))
                strLangCode = "EN";

            // Create parameters list
            List<SqlParameter> lst = new List<SqlParameter>();

            // Existing parameters
            SqlParameter sqlParam1 = new SqlParameter("@USERNAME", SqlDbType.NVarChar);
            sqlParam1.Value = strUserName;
            lst.Add(sqlParam1);

            SqlParameter sqlParam2 = new SqlParameter("@ORDERNAME", SqlDbType.VarChar);
            sqlParam2.Size = 50;
            sqlParam2.Value = strOrderName;
            lst.Add(sqlParam2);

            SqlParameter sqlParam3 = new SqlParameter("@ORDERTYPE", SqlDbType.VarChar);
            sqlParam3.Size = 30;
            sqlParam3.Value = strOrderType;
            lst.Add(sqlParam3);

            SqlParameter sqlParam4 = new SqlParameter("@ASSOCTYPEID", SqlDbType.Int);
            if (String.IsNullOrEmpty(strAssocTypeID))
                sqlParam4.Value = System.Data.SqlTypes.SqlInt32.Null;
            else
                sqlParam4.Value = System.Convert.ToInt32(strAssocTypeID);
            lst.Add(sqlParam4);

            SqlParameter sqlParam5 = new SqlParameter("@ASSOCTYPE", SqlDbType.VarChar);
            sqlParam5.Size = 30;
            sqlParam5.Value = strAssocType;
            lst.Add(sqlParam5);

            SqlParameter sqlParam6 = new SqlParameter("@SERIALNUMBER", SqlDbType.VarChar);
            sqlParam6.Size = 30;
            sqlParam6.Value = strSerialNumber;
            lst.Add(sqlParam6);

            SqlParameter sqlParam7 = new SqlParameter("@LANGUAGECODE", SqlDbType.Char);
            sqlParam7.Value = strLangCode;
            lst.Add(sqlParam7);

            SqlParameter sqlParam8 = new SqlParameter("@SESSIONID", SqlDbType.VarChar);
            sqlParam8.Size = 50;
            sqlParam8.Value = String.IsNullOrEmpty(strSessionID) ? System.Data.SqlTypes.SqlString.Null : strSessionID;
            lst.Add(sqlParam8);

            SqlParameter sqlParam9 = new SqlParameter("@PRODUCTLIST", SqlDbType.VarChar);
            sqlParam9.Size = 100;
            sqlParam9.Value = strProductList;
            lst.Add(sqlParam9);

            SqlParameter sqlParam10 = new SqlParameter("@OEMCODE", SqlDbType.Char);
            sqlParam10.Value = strOemCode;
            lst.Add(sqlParam10);

            SqlParameter sqlParam11 = new SqlParameter("@APPNAME", SqlDbType.VarChar);
            sqlParam11.Size = 50;
            sqlParam11.Value = strAppName;
            lst.Add(sqlParam11);

            SqlParameter sqlParam12 = new SqlParameter("@OutformatXML", SqlDbType.Int);
            sqlParam12.Value = 0;
            lst.Add(sqlParam12);

            SqlParameter sqlParam13 = new SqlParameter("@CallFrom", SqlDbType.VarChar);
            sqlParam13.Size = 50;
            sqlParam13.Value = strCallFrom;
            lst.Add(sqlParam13);

            SqlParameter sqlParam14 = new SqlParameter("@IsMobile", SqlDbType.VarChar);
            sqlParam14.Size = 10;
            sqlParam14.Value = strismobile;
            lst.Add(sqlParam14);

            // Add SOURCE parameter if not empty
            if (!string.IsNullOrEmpty(strSource))
            {
                SqlParameter sqlParam15 = new SqlParameter("@SOURCE", SqlDbType.VarChar);
                sqlParam15.Value = strSource;
                lst.Add(sqlParam15);
            }

            SqlParameter sqlParam16 = new SqlParameter("@SEARCHSERIALNUMBER", SqlDbType.VarChar);
            sqlParam16.Size = 30;
            sqlParam16.Value = string.IsNullOrEmpty(strSearchSerial) ? "" : strSearchSerial;
            lst.Add(sqlParam16);

            SqlParameter sqlParam17 = new SqlParameter("@ISPRODUCTGROUPTABLENEEDED", SqlDbType.VarChar);
            sqlParam17.Size = 10;
            sqlParam17.Value = strIsProductGroupTableNeeded;
            lst.Add(sqlParam17);

            // New filtering parameters
            SqlParameter sqlParam18 = new SqlParameter("@ORGANISATIONID", SqlDbType.BigInt);
            if (String.IsNullOrEmpty(strOrganizationID))
                sqlParam18.Value = System.Data.SqlTypes.SqlInt64.Null;
            else
                sqlParam18.Value = System.Convert.ToInt64(strOrganizationID);
            lst.Add(sqlParam18);

            SqlParameter sqlParam19 = new SqlParameter("@ISLICENSEEXPIRY", SqlDbType.Bit);
            if (String.IsNullOrEmpty(strIsLicenseExpiry))
                sqlParam19.Value = System.Data.SqlTypes.SqlBoolean.Null;
            else
            {
                // Handle boolean conversion (accepts "true"/"false", "1"/"0")
                if (strIsLicenseExpiry.ToLower() == "true" || strIsLicenseExpiry == "1")
                    sqlParam19.Value = true;
                else if (strIsLicenseExpiry.ToLower() == "false" || strIsLicenseExpiry == "0")
                    sqlParam19.Value = false;
                else
                    sqlParam19.Value = System.Data.SqlTypes.SqlBoolean.Null;
            }
            lst.Add(sqlParam19);

            // Pagination parameters
            SqlParameter sqlParam20 = new SqlParameter("@PAGENO", SqlDbType.Int);
            if (String.IsNullOrEmpty(strPageNo))
                sqlParam20.Value = 1;
            else
            {
                if (int.TryParse(strPageNo, out int pageNo) && pageNo >= 1)
                    sqlParam20.Value = pageNo;
                else
                    sqlParam20.Value = 1;
            }
            lst.Add(sqlParam20);

            SqlParameter sqlParam21 = new SqlParameter("@PAGESIZE", SqlDbType.Int);
            if (String.IsNullOrEmpty(strPageSize))
                sqlParam21.Value = 50;
            else
            {
                if (int.TryParse(strPageSize, out int pageSize) && pageSize >= 1 && pageSize <= 5000)
                    sqlParam21.Value = pageSize;
                else
                    sqlParam21.Value = 50;
            }
            lst.Add(sqlParam21);

            SqlParameter sqlParam22 = new SqlParameter("@MINCOUNT", SqlDbType.Int);
            if (String.IsNullOrEmpty(strMinCount))
                sqlParam22.Value = System.Data.SqlTypes.SqlInt32.Null;
            else
            {
                if (int.TryParse(strMinCount, out int minCount) && minCount >= 0)
                    sqlParam22.Value = minCount;
                else
                    sqlParam22.Value = System.Data.SqlTypes.SqlInt32.Null;
            }
            lst.Add(sqlParam22);

            SqlParameter sqlParam23 = new SqlParameter("@MAXCOUNT", SqlDbType.Int);
            if (String.IsNullOrEmpty(strMaxCount))
                sqlParam23.Value = System.Data.SqlTypes.SqlInt32.Null;
            else
            {
                if (int.TryParse(strMaxCount, out int maxCount) && maxCount >= 0)
                    sqlParam23.Value = maxCount;
                else
                    sqlParam23.Value = System.Data.SqlTypes.SqlInt32.Null;
            }
            lst.Add(sqlParam23);

            // Execute the stored procedure with all parameters
            objResult = DAL.ExecuteSQLDataSet("GETASSOCIATEDPRODUCTSWITHORDERLIST", lst);
            objResult.Tables.Add(Helper.BuildDefaultSuccessStatus());

        }
        catch (Microsoft.Data.SqlClient.SqlException dex)
        {
            EHL.LogError(dex, Latte.Library.ErrorHandlerConstants.PolicyType.DatabaseLayerPolicy);
            LAT.DoLoggingAndTrace(Helper.GetFailureMessage("ProductManager", "GetAssociatedProducts", dex.ToString(), 
                "Serialnumber:" + strSerialNumber, "ApplicationName:" + strAppName, "UserName:" + strUserName, 
                "OEMCODE:" + strOemCode, "OrganizationID:" + strOrganizationID, "PageSize:" + strPageSize), 
                Category.DBEvents, Priority.High, System.Diagnostics.TraceEventType.Error);
            objResult.Tables.Clear();
            objResult.Tables.Add(Helper.BuildDefaultFailureStatus());
        }
        catch (Exception ex)
        {
            EHL.LogError(ex, Latte.Library.ErrorHandlerConstants.PolicyType.UnhandledPolicy);
            LAT.DoLoggingAndTrace(Helper.GetFailureMessage("ProductManager", "GetAssociatedProducts", ex.ToString(), 
                "Serialnumber:" + strSerialNumber, "ApplicationName:" + strAppName, "UserName:" + strUserName, 
                "OEMCODE:" + strOemCode, "OrganizationID:" + strOrganizationID, "PageSize:" + strPageSize), 
                Category.General, Priority.High, System.Diagnostics.TraceEventType.Error);
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

    // Helper method to build input dataset with new parameters
    public DataSet BuildGetAssociatedProductsDataset(string userName, string locale, string sessionId, 
        string orderName, string appName, string oemCode, string searchSerial, 
        string organizationID = null, bool? isLicenseExpiry = null, int? pageNo = null, 
        int? pageSize = null, int? minCount = null, int? maxCount = null)
    {
        DataSet dsInput = new DataSet();
        DataTable dtInput = new DataTable("INPUT");
        
        // Add all columns
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
        dtInput.Columns.Add("SOURCE", typeof(string));
        dtInput.Columns.Add("SEARCHSERIALNUMBER", typeof(string));
        dtInput.Columns.Add("ISPRODUCTGROUPTABLENEEDED", typeof(string));
        
        // New parameter columns
        dtInput.Columns.Add("ORGANIZATIONID", typeof(string));
        dtInput.Columns.Add("ISLICENSEEXPIRY", typeof(string));
        dtInput.Columns.Add("PAGENO", typeof(string));
        dtInput.Columns.Add("PAGESIZE", typeof(string));
        dtInput.Columns.Add("MINCOUNT", typeof(string));
        dtInput.Columns.Add("MAXCOUNT", typeof(string));

        // Add data row
        DataRow row = dtInput.NewRow();
        row["USERNAME"] = userName;
        row["ORDERNAME"] = orderName;
        row["ORDERTYPE"] = "DESC";
        row["ASSOCTYPEID"] = "0";
        row["ASSOCTYPE"] = "";
        row["SERIALNUMBER"] = "";
        row["LANGUAGECODE"] = locale;
        row["SESSIONID"] = sessionId;
        row["PRODUCTLIST"] = "";
        row["OEMCODE"] = oemCode;
        row["APPNAME"] = appName;
        row["CALLFROM"] = "";
        row["ISMOBILE"] = "NO";
        row["SOURCE"] = "";
        row["SEARCHSERIALNUMBER"] = searchSerial ?? "";
        row["ISPRODUCTGROUPTABLENEEDED"] = "YES";
        
        // New parameters
        row["ORGANIZATIONID"] = organizationID ?? "";
        row["ISLICENSEEXPIRY"] = isLicenseExpiry?.ToString() ?? "";
        row["PAGENO"] = pageNo?.ToString() ?? "1";
        row["PAGESIZE"] = pageSize?.ToString() ?? "50";
        row["MINCOUNT"] = minCount?.ToString() ?? "";
        row["MAXCOUNT"] = maxCount?.ToString() ?? "";
        
        dtInput.Rows.Add(row);
        dsInput.Tables.Add(dtInput);
        
        return dsInput;
    }

    // Usage example for 5000 records
    public DataSet GetInventoryData(string userName, string sessionId, string organizationID = null, 
        bool? isLicenseExpiry = null, int pageSize = 5000)
    {
        // Build input dataset with new parameters
        DataSet inputDS = BuildGetAssociatedProductsDataset(
            userName: userName,
            locale: "EN",
            sessionId: sessionId,
            orderName: "REGISTEREDDATE",
            appName: "MSW",
            oemCode: "SNWL",
            searchSerial: "",
            organizationID: organizationID,
            isLicenseExpiry: isLicenseExpiry,
            pageNo: 1,
            pageSize: pageSize  // Can be up to 5000
        );
        
        // Call the modified method
        return GetAssociatedProducts(inputDS);
    }
}