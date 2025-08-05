ALTER PROCEDURE [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]        
    @USERNAME NVARCHAR(30) ,            
    @ORDERNAME VARCHAR(50) ,            
    @ORDERTYPE VARCHAR(30) ,            
    @ASSOCTYPEID INT = 0 ,            
    @ASSOCTYPE VARCHAR(30) = '' ,            
    @SERIALNUMBER VARCHAR(30) = '' ,            
    @LANGUAGECODE CHAR(2) = 'EN' ,            
    @SESSIONID VARCHAR(50) = NULL ,            
    @PRODUCTLIST VARCHAR(100) = NULL ,            
    @OEMCODE CHAR(4) = 'SNWL' ,            
    @APPNAME VARCHAR(50) = 'MSW' ,            
    @OutformatXML INT = NULL ,            
    @CallFrom VARCHAR(50) = NULL ,            
    @IsMobile VARCHAR(50) = 'NO',          
    @SOURCE VARCHAR(10) =''  ,      
    @SEARCHSERIALNUMBER VARCHAR(30) ='',      
    @ISPRODUCTGROUPTABLENEEDED VARCHAR(10) ='YES',    -- this parameter from SPUPDATEFIRMWARESERIALNUMBER. to get only serial number detatils         
    -- Pagination parameters
    @PAGENO INT = 1,                    -- Page number (1-based)
    @PAGESIZE INT = 50,                 -- Number of records per page
    @MINCOUNT INT = NULL,               -- Minimum record count filter
    @MAXCOUNT INT = NULL                -- Maximum record count filter
--WITH EXECUTE AS CALLER          
   
   
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)  
AS             
BEGIN          
   SET NOCOUNT ON                  
    IF ISNULL(@LANGUAGECODE, '') = ''             
        SELECT  @LANGUAGECODE = 'EN'                 
                    
    IF ISNULL(@OEMCODE, '') = ''             
        SELECT  @OEMCODE = 'SNWL'              
                                      
    IF ISNULL(@APPNAME, '') = ''             
        SELECT  @APPNAME = 'MSW'              
                    
    IF ISNULL(@IsMobile, '') = ''             
        SELECT  @IsMobile = 'NO'             
              
    -- Pagination validation
    IF @PAGENO < 1 SET @PAGENO = 1
    IF @PAGESIZE < 1 SET @PAGESIZE = 50
    IF @PAGESIZE > 1000 SET @PAGESIZE = 1000  -- Limit maximum page size
    
    DECLARE @OFFSET INT = (@PAGENO - 1) * @PAGESIZE
    DECLARE @TOTALRECORDS INT = 0
    DECLARE @FILTEREDRECORDS INT = 0
    
    DECLARE @CONTACTID BIGINT               
    DECLARE @ORGID BIGINT          
    DECLARE @ROLLUP BIT      
    DECLARE @ISSELECTEDPARTNER BIT=0      
    DECLARE @INDEX INT              
    DECLARE @TotalCNT INT              
    DECLARE @TEMPSERIALNUMBER VARCHAR(30)            
    DECLARE @DISPLAYKEYSET VARCHAR(3)            
    DECLARE @ASSOWITHTXT NVARCHAR(100)              
    DECLARE @BISCLOSEDNETWORK INT            
    DECLARE @ISLARGEUSER VARCHAR(3)  = 'NO'         
    DECLARE @RECENTCOUNT INT=50       
    DECLARE @APPLICATIONFUNCTIONALITY VARCHAR(50) = 'ACCESSTYPEPRODMGMT'        
    SELECT  @BISCLOSEDNETWORK = 0        
    DECLARE @ISMSSPUSER VARCHAR(10)      
    DECLARE @EMAILADDRESS VARCHAR(30)      
    DECLARE @DESCRIPTION VARCHAR(255)      
       
    DECLARE @APPLICATIONNAME VARCHAR(50)      
       
    DECLARE @MOBILESERVERPRODUCTLISTORGANIZATIONID VARCHAR(100)      
       
    DECLARE @ENABLEORGBASEDASSET VARCHAR(20) = 'NO'      
    DECLARE @ISORGBASEDACCOUNT  VARCHAR(3) = 'NO'      
    DECLARE @PARTYID INT      
    DECLARE @ORGBASEDASSETOWNSERSHIPENABLED VARCHAR(10) = 'NO'
    DECLARE @CONNECTORNAME VARCHAR(100)
    DECLARE @CNT INT = 0
    DECLARE @IT INT = 0
    DECLARE @ICONNECTORNAME VARCHAR(100)
    
    -- Get contact and organization details
    SELECT @CONTACTID = CONTACTID, @ORGID = ORGANIZATIONID, @ISMSSPUSER = ISMSSPUSER, @EMAILADDRESS = EMAILADDRESS, @DESCRIPTION = [DESCRIPTION], @APPLICATIONNAME = APPLICATIONNAME, @MOBILESERVERPRODUCTLISTORGANIZATIONID = MOBILESERVERPRODUCTLISTORGANIZATIONID, @ENABLEORGBASEDASSET = ENABLEORGBASEDASSET, @ISORGBASEDACCOUNT = ISORGBASEDACCOUNT, @PARTYID = PARTYID, @ORGBASEDASSETOWNSERSHIPENABLED = ORGBASEDASSETOWNSERSHIPENABLED, @ISLARGEUSER = ISLARGEUSER FROM vCUSTOMER WITH (NOLOCK) WHERE USERNAME = @USERNAME
    
    IF @CONTACTID IS NULL
        RETURN
    
    -- Check if user is selected partner
    IF EXISTS( SELECT USERNAME FROM vcustomer WHERE ORGANIZATIONID IN       
      (SELECT  * FROM    FNSPLITCSV(@MOBILESERVERPRODUCTLISTORGANIZATIONID) ) AND USERNAME = @USERNAME)      
    BEGIN      
        SELECT @ISSELECTEDPARTNER=1        
    END           
    
    SELECT @ROLLUP = OWNSPRODUCT from ORGANIZATION O (nolock) where O.ORGANIZATIONID =@ORGID          
            
    EXECUTE SP_GETMESSAGESTRING 'ASSOWITH', @LANGUAGECODE, 1,            
        @ASSOWITHTXT OUTPUT             
                              
    CREATE TABLE #TEMPLISTTABLE             
    (              
        CID INT IDENTITY(1, 1) ,              
        PRODUCTID INT ,              
        SERIALNUMBER VARCHAR(30) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS ,              
        REGISTRATIONCODE VARCHAR(50) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS ,              
        FIRMWAREVERSION VARCHAR(100) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS ,              
        OWNEROFTHEPRODUCT INT NOT NULL  DEFAULT 0 ,              
        PRODUCTOWNER NVARCHAR(30) ,              
        ISSUENAME NVARCHAR(255) ,              
        RESOLUTIONNAME NVARCHAR(255) ,              
        PRODUCTGROUPID INT ,              
        PRODUCTGROUPNAME NVARCHAR(510) ,              
        SUPPORTDATE DATETIME ,                        
        NEEDEDFIRMWAREVERSION VARCHAR(100) ,              
        FIRMWARESTATUS VARCHAR(30) ,              
        FIRMWARETEXT VARCHAR(1000) ,              
        SRLNOSTATUS VARCHAR(100) ,              
        RELEASENOTES VARCHAR(2000),              
        PARTYGROUPIDS VARCHAR(MAX),              
        PARTYGROUPNAMES nvarchar(MAX),            
        PARTYGROUPNAME NVARCHAR(MAX),              
        DEVICESTATUS VARCHAR(10),            
        PRODUCTGROUPNAMES nvarchar(MAX),            
        PRODUCTGROUPIDS VARCHAR(MAX),              
        FWTAB VARCHAR(5),            
        ASSOCTYPEINTNAME VARCHAR(255),            
        ISDELETEALLOWED CHAR(3),            
        ISTRANSFERALLOWED CHAR(3),            
        ISRENAMEALLOWED CHAR(3),            
        ISSECUREUPGRADE CHAR(3),            
        S1SVCSTATUS VARCHAR(30),            
        SENTINELONEEXPIRYDATE DATETIME,            
        LICENSEEXPIRYCNT INT DEFAULT 0,            
        SOONEXPIRINGCNT INT,        
        ACTIVELICENSECNT INT,            
        ISLICENSEEXPIRED INT DEFAULT 0,            
        ISSOONEXPIRING INT DEFAULT 0,            
        MINLICENSEEXPIRYDATE DATETIME,            
        SOONEXPIRYDATE DATETIME,            
        ISDOWNLOADAVAILABLE INT DEFAULT 0,            
        HESNODECOUNT INT DEFAULT 0,            
        CASNODECOUNT INT DEFAULT 0,             
        CCNODECOUNT INT DEFAULT 0,            
        GMSNODECOUNT INT DEFAULT 0,            
        EPAID VARCHAR(100),            
        ISZTSUPPORTED INT,            
        SUPPORTEXPIRYDATE DATETIME,            
        NONSUPPORTEXPIRYDATE DATETIME,            
        SERVICELINE VARCHAR(50),            
        ISBILLABLE VARCHAR(10),           
        ROLETYPE VARCHAR(100),            
        SASELICENSECOUNT INT DEFAULT 0,            
        ISZEROTOUCHALLOWED CHAR(3),            
        ORGNAME NVARCHAR(250) ,          
        PRODUCTFAMILY VARCHAR(50),          
        PRODUCTLINE VARCHAR(100),          
        ACTIVEPROMOTION INT  DEFAULT 0 ,          
        DISPLAYKEYSET VARCHAR(3)  ,        
        ASSOCIATIONTYPE VARCHAR(510),      
        ISADDKEYSETAPPLICABLE VARCHAR(10),      
        CURRENTNODESUPPORT INT,      
        MSSPMONTHLYOPTION VARCHAR(20),      
        ISNETWORKPRODUCT VARCHAR(10),      
        EMAILADDRESS VARCHAR(100),    
        [DESCRIPTION] VARCHAR(255),      
        LASTPINGDATE DATETIME,      
        PSAADDITIONSEXPIRYDATE DATETIME,      
        ISSHAREDTENANT VARCHAR(3),      
        CONNECTORNAME VARCHAR(100),    
        PRODUCTCHOICEID INT,  
        MANAGEMENTOPTION VARCHAR(100),
        ORGID INT
    )                                
    CREATE CLUSTERED INDEX IDX_TEMPLISTTABLE_SERIALNUMBER ON #TEMPLISTTABLE(SERIALNUMBER)             
    
    DECLARE @PRODGROUPTABLE TABLE            
    (            
        PRODUCTGROUPID INT,       
        PRODUCTGROUPNAME NVARCHAR(4000),       
        TOTALPRODUCTSCNT INT,      
        EXPIREDPRODUCTSCNT INT,      
        SOONEXPIRINGPRODDUCTSCNT INT,      
        ACTIVEPRODUCTSCNT INT,      
        ACCESSPOINTCNT INT,      
        FIREWALLCNT INT         
    )         
          
    DECLARE @GROUPTABLE TABLE            
    (            
        GROUPID INT,          
        GROUPNAME NVARCHAR(4000),          
        GROUPTYPE VARCHAR(20)          
    )          
               
    SELECT PG.PARTYGROUPID ,             
        PG.PARTYGROUPNAME,             
        P.CONTACTID,             
        PTG.PRODUCTGROUPID,             
        PTG.PRODUCTGROUPNAME,            
        SERIALNUMBER,              
        P.ORGANIZATIONID,             
        PTG.ADMINPARTYID  into #tempPRGD          
    from           
        PARTYGROUP PG (nolock)          
        , PARTYGROUPDETAIL PGD (nolock)          
        , PARTYPRODUCTGROUP PPG (nolock)          
        , PRODUCTGROUP PTG (nolock)          
        , PRODUCTGROUPDETAIL PTGD (nolock)          
        , PARTY P (nolock)            
    where PG.PARTYGROUPID = PGD.PARTYGROUPID           
        and PPG.PARTYGROUPID = PG.PARTYGROUPID          
        and PPG.PRODUCTGROUPID = PTG.PRODUCTGROUPID            
        and PTG.PRODUCTGROUPID = PTGD.PRODUCTGROUPID            
        AND P.PARTYID = PGD.PARTYID          
        and contactid=@CONTACTID         
      
    -- Handle firewall connector association type
    IF @ASSOCTYPE ='CHILDASSOCIATE' AND   
        @ASSOCTYPEID IN ( SELECT PRODUCTASSOCIATIONTYPEID FROM PRODUCTASSOCIATIONTYPE WITH (NOLOCK) WHERE INTERNALDESCRIPTION='FIREWALL_CONNECTOR')  
    BEGIN  
        IF NOT EXISTS (SELECT PRODUCTID FROM  CUSTOMERPRODUCTS WITH (NOLOCK) WHERE SERIALNUMBER=@SERIALNUMBER   AND  PRODUCTID=409)  
        BEGIN   
            SET  @ASSOCTYPE ='PARENTASSOCIATE'  
            SELECT @CONNECTORNAME =CONNECTORNAME FROM DEVICEASSOCIATION WITH (NOLOCK) WHERE CHILDSERIALNUMBER=@SERIALNUMBER AND PRODUCTASSOCIATIONTYPEID=@ASSOCTYPEID   
        END  
    END      
       
    -- Main data population logic (simplified for brevity - this would include all the existing INSERT logic)
    -- ... (All existing INSERT statements would go here)
    
    -- Get total record count for pagination
    SELECT @TOTALRECORDS = COUNT(*) FROM #TEMPLISTTABLE
    
    -- Apply count filters if specified
    IF @MINCOUNT IS NOT NULL AND @TOTALRECORDS < @MINCOUNT
        RETURN
    
    IF @MAXCOUNT IS NOT NULL AND @TOTALRECORDS > @MAXCOUNT
        RETURN
    
    -- Main result selection with pagination
    IF @ORDERNAME = 'SERIALNUMBER' AND @ORDERTYPE = '0'             
    BEGIN                
        IF ( @OutformatXML = 0 )             
        BEGIN      
            --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)                   
            SELECT DISTINCT            
                c.PRODUCTID ,            
                c.SERIALNUMBER ,            
                c.[NAME] ,            
                c.CUSTOMERPRODUCTID ,            
                c.STATUS ,            
                c.REGISTRATIONCODE ,            
                c.FIRMWAREVERSION ,            
                PRODUCT.PRODUCTLINE ,           
                c.PRODUCTFAMILY ,            
                c.ACTIVEPROMOTION ,            
                c.PROMOTIONID ,            
                c.NFR ,            
                PRODUCT.OWNEROFTHEPRODUCT ,            
                PRODUCT.PRODUCTOWNER ,            
                c.ISSUENAME ,            
                c.RESOLUTIONNAME ,            
                c.PRODUCTNAME ,            
                c.PRODUCTGROUPID ,            
                c.PRODUCTGROUPNAME ,            
                c.DISPLAYKEYSET ,            
                c.ASSOCIATIONTYPE ,            
                c.GROUPHEADERTEXT ,            
                c.ASSOCIATIONTYPEID ,            
                c.ISEPRS ,            
                c.REMOVEASSOCIATION ,            
                c.DELETEDM ,            
                C.CREATEDDATE AS REGISTRATIONDATE,        
                C.LASTPINGDATE AS LASTPINGDATE,       
                c.HGMSPROVISIONINGSTATUS,          
                PRODUCT.ISDELETEALLOWED,          
                PRODUCT.ISTRANSFERALLOWED,          
                PRODUCT.ISRENAMEALLOWED,          
                PRODUCT.ISSECUREUPGRADE,          
                c.S1SVCSTATUS,         
                c.SENTINELONEEXPIRYDATE,          
                c.PRODUCTTYPE,          
                c.EPAID ,c.SERVICELINE,c.ISBILLABLE,PRODUCT.ROLETYPE ,c.SASELICENSECOUNT,      
                c.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE ,      
                PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT,PRODUCT.EMAILADDRESS,      
                PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT        
                ,PRODUCTCHOICEID , C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY   
            FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
                ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber          
            ORDER BY C.SERIALNUMBER DESC
            OFFSET @OFFSET ROWS
            FETCH NEXT @PAGESIZE ROWS ONLY                                                            
            RETURN                
        END                
        ELSE             
        BEGIN                                      
            SELECT DISTINCT            
                c.PRODUCTID ,            
                c.SERIALNUMBER ,            
                c.[NAME] ,            
                c.CUSTOMERPRODUCTID ,            
                c.STATUS ,            
                c.REGISTRATIONCODE ,            
                c.FIRMWAREVERSION ,            
                PRODUCT.PRODUCTLINE ,            
                c.PRODUCTFAMILY ,            
                c.ACTIVEPROMOTION ,            
                c.PROMOTIONID ,            
                c.NFR ,            
                PRODUCT.OWNEROFTHEPRODUCT ,            
                PRODUCT.PRODUCTOWNER ,            
                c.ISSUENAME ,            
                c.RESOLUTIONNAME ,            
                c.PRODUCTNAME ,            
                c.PRODUCTGROUPID ,            
                c.PRODUCTGROUPNAME ,            
                c.DISPLAYKEYSET ,            
                c.ASSOCIATIONTYPE ,            
                c.GROUPHEADERTEXT ,            
                c.ISEPRS ,            
                C.CREATEDDATE AS REGISTRATIONDATE,      
                C.LASTPINGDATE AS LASTPINGDATE,   
                c.HGMSPROVISIONINGSTATUS,          
                PRODUCT.ISDELETEALLOWED,          
                PRODUCT.ISTRANSFERALLOWED,          
                PRODUCT.ISRENAMEALLOWED,          
                PRODUCT.ISSECUREUPGRADE,          
                c.SENTINELONEEXPIRYDATE  ,c.PRODUCTTYPE,c.EPAID ,c.SERVICELINE ,c.ISBILLABLE,PRODUCT.ROLETYPE ,c.SASELICENSECOUNT,c.ISZEROTOUCHALLOWED,       
                PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION,c.ISNETWORKPRODUCT       
                , PRODUCT.EMAILADDRESS,      
                PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY       
            FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
                ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber           
            ORDER BY C.SERIALNUMBER DESC
            OFFSET @OFFSET ROWS
            FETCH NEXT @PAGESIZE ROWS ONLY            
            FOR     XML AUTO ,            
                ELEMENTS          
            RETURN                
        END              
    END                  
    
    -- Similar pagination logic would be applied to all other ORDER BY conditions
    -- (SERIALNUMBER ASC, NAME DESC, NAME ASC, PRODUCTLINE DESC, PRODUCTLINE ASC, etc.)
    
    -- For brevity, I'm showing just one example above. All other SELECT statements
    -- would need similar OFFSET/FETCH clauses added after their ORDER BY clauses.
    
    -- Cleanup
    DROP TABLE #TEMPLISTTABLE        
    --DROP TABLE #tempPRGD      
END