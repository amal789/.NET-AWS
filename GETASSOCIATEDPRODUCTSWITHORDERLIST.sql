  
     
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
      
    IF ISNULL(@LANGUAGECODE, '') = ''             
        SELECT  @LANGUAGECODE = 'EN'                 
                    
    IF ISNULL(@OEMCODE, '') = ''             
        SELECT  @OEMCODE = 'SNWL'              
                                      
    IF ISNULL(@APPNAME, '') = ''             
        SELECT  @APPNAME = 'MSW'              
                    
    IF ISNULL(@IsMobile, '') = ''             
        SELECT  @IsMobile = 'NO'             
              
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
 DECLARE @ORGBASEDASSETOWNSERSHIPENABLED VARCHAR(3) = 'NO', @ROLEIDORGBASED INT      
      
 DECLARE @IT INT =0        
       DECLARE @CNT INT        
       DECLARE @ISER VARCHAR(40)        
       DECLARE @ICONNECTORNAME VARCHAR(100)   
   DECLARE @CONNECTORNAME NVARCHAR(255)  
 SELECT @APPLICATIONNAME = APPLICATIONNAME FROM SESSIONREV WITH (NOLOCK) WHERE USERNAME = @USERNAME        
       
 SELECT  @CONTACTID = CONTACTID  , @ORGID = ORGANIZATIONID ,@ISLARGEUSER = ISNULL(LARGECUSTOMER,'NO'), @ISORGBASEDACCOUNT = ORGBASEDACCOUNT, @PARTYID = PARTYID          
    FROM    dbo.VCUSTOMER WITH ( NOLOCK )            
    WHERE   USERNAME = @USERNAME           
      
      
SELECT @ENABLEORGBASEDASSET = APPLICATIONCONFIGVALUE  FROM APPLICATIONCONFIGVALUE (NOLOCK)       
WHERE APPLICATIONCONFIGNAME='ENABLEORGBASEDASSET'       
      
SELECT @ROLEIDORGBASED = APPLICATIONROLEID FROM APPLICATIONROLE WITH (NOLOCK) WHERE ROLENAME = 'ORGBASED' AND APPLICATIONNAME = 'MSW' AND OEMCODE = 'SNWL'       
       
SELECT @ORGBASEDASSETOWNSERSHIPENABLED = CASE       
      WHEN ISNULL(@ENABLEORGBASEDASSET,'') = 'YES' THEN 'YES'      
      WHEN ISNULL(@ENABLEORGBASEDASSET,'') = 'ROLEBASED' AND @ISORGBASEDACCOUNT = 'YES' THEN 'YES'      
      --WHEN ISNULL(@ENABLEORGBASEDASSET,'') = 'ROLEBASED' AND EXISTS (SELECT 1 FROM APPLICATIONPARTYROLE WITH(NOLOCK) WHERE PARTYID = @PARTYID       
      --AND APPLICATIONROLEID = @ROLEIDORGBASED) THEN 'YES'      
      ELSE 'NO'      
     END      
      
      
 SELECT @ISMSSPUSER = DBO.FNISMSSPUSER(@USERNAME)       
                     
 SELECT @MOBILESERVERPRODUCTLISTORGANIZATIONID = APPLICATIONCONFIGVALUE  FROM APPLICATIONCONFIGVALUE      
   WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTORGANIZATIONIDS'        
      
     SELECT @RECENTCOUNT=CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT'      
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
 ORGID INT,
    --,REGCODE VARCHAR(30)          
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
--AND PTG.ADMINPARTYID IN (SELECT PARTYID FROM PARTY WITH (NOLOCK)      
 --WHERE STATUS = 'ACTIVE' AND ORGANIZATIONID IN (SELECT ORGANIZATIONID FROM PARTY WITH (NOLOCK)      
 --WHERE CONTACTID = @CONTACTID))      
  and contactid=@CONTACTID         
      
      
    IF @ASSOCTYPE ='CHILDASSOCIATE' AND   
  @ASSOCTYPEID IN ( SELECT PRODUCTASSOCIATIONTYPEID FROM PRODUCTASSOCIATIONTYPE WITH (NOLOCK) WHERE INTERNALDESCRIPTION='FIREWALL_CONNECTOR')  
  BEGIN  
  IF NOT EXISTS (SELECT PRODUCTID FROM  CUSTOMERPRODUCTS WITH (NOLOCK) WHERE SERIALNUMBER=@SERIALNUMBER   AND  PRODUCTID=409)  
  BEGIN   
   SET  @ASSOCTYPE ='PARENTASSOCIATE'  
    SELECT @CONNECTORNAME =CONNECTORNAME FROM DEVICEASSOCIATION WITH (NOLOCK) WHERE CHILDSERIALNUMBER=@SERIALNUMBER AND PRODUCTASSOCIATIONTYPEID=@ASSOCTYPEID   
     
   END  
  END      
       
               
    IF ISNULL(@ASSOCTYPEID, 0) = 0             
        BEGIN      
   IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
   BEGIN      
         
    IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND @ISSELECTEDPARTNER=1)      
    BEGIN       
      
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY,         
        PRODUCTLINE,          
        ACTIVEPROMOTION           
                
                    )            
                     SELECT TOP (@RECENTCOUNT)      
        CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
          
       FROM              
         CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
       WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                            AND CP.USEDSTATUS = 1           
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
        AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
          
       INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
        SERIALNUMBER ,                                
      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      )            
                     SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
      CP.SERIALNUMBER ,                                        
        CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE  CP.USERNAME = @USERNAME  and CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)           
      AND CP.USEDSTATUS = 1                                    
     AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
          
             
       END       
       ELSE      
       BEGIN      
                                    
       INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                  PRODUCTFAMILY,          
        PRODUCTLINE,          
        ACTIVEPROMOTION           
                
                    )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
          
       FROM              
         CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
       WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                        FROM   #tempPRGD)            
                            AND CP.USEDSTATUS = 1           
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
        AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
          
       INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
        SERIALNUMBER ,                                
      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      )            
                    SELECT  CP.PRODUCTID ,            
      CP.SERIALNUMBER ,                                        
        CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE  CP.USERNAME = @USERNAME  and CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)           
      AND CP.USEDSTATUS = 1                                    
     AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
          
      END      
      --INCLUDE CLIENTLICESES                      
      IF @SOURCE='RESTAPI'          
                                                                                                BEGIN          
               
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      )            
                    SELECT CP.PRODUCTID ,            
     CP.SERIALNUMBER ,                                        
                    CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
       PRODUCTLINE,          
       ACTIVEPROMOTION          
      FROM              
       CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE  CP.USERNAME = @USERNAME             
       --and CP.SERIALNUMBER IN (            
       -- SELECT  SERIALNUMBER            
       -- FROM    #tempPRGD)                    
                    and CP.PRODUCTFAMILY IN ( 'CLIENTLICENSE' )          
     AND CP.SERIALNUMBER NOT IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)           
     AND CP.USEDSTATUS = 1         
                 
                     -- get shared client licenses product as well          
                     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                
      PRODUCTFAMILY,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
                    )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                      
                            CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
      FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)                                       
              AND CP.PRODUCTFAMILY IN ( 'CLIENTLICENSE')                 
                            AND CP.SERIALNUMBER NOT IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)                                
                    AND CP.USEDSTATUS = 1         
                END                                     
                                          
      END        
    ELSE       
    BEGIN       
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY,          
        PRODUCTLINE,          
        ACTIVEPROMOTION           
                
                    )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,  
       CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
         PRODUCTLINE,          
         ACTIVEPROMOTION       
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                            AND CP.USEDSTATUS = 1           
       AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)         
          
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                                
                     PRODUCTFAMILY ,          
     PRODUCTLINE,          
       ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                        
        CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE  CP.USERNAME = @USERNAME  and CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)           
    AND CP.USEDSTATUS = 1                                    
     AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
    AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
              
     --INCLUDE CLIENTLICESES                      
     IF @SOURCE='RESTAPI'          
     BEGIN          
               
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,           
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
       PRODUCTLINE,          
       ACTIVEPROMOTION          
     )            
                    SELECT CP.PRODUCTID ,            
     CP.SERIALNUMBER ,                                        
                    CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
       PRODUCTLINE,          
       ACTIVEPROMOTION          
      FROM              
       CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE  CP.USERNAME = @USERNAME             
       --and CP.SERIALNUMBER IN (            
       -- SELECT  SERIALNUMBER            
       -- FROM    #tempPRGD)                    
                    and CP.PRODUCTFAMILY IN ( 'CLIENTLICENSE' )          
     AND CP.SERIALNUMBER NOT IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)           
     AND CP.USEDSTATUS = 1         
     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
           
                     -- get shared client licenses product as well          
                     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,      
      PRODUCTFAMILY,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
                    )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                      
                            CP.PRODUCTFAMILY 'PRODUCTFAMILY',          
       PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)                                       
                            AND CP.PRODUCTFAMILY IN ( 'CLIENTLICENSE')                 
                            AND CP.SERIALNUMBER NOT IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)                                
                    AND CP.USEDSTATUS = 1         
     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
                END                                     
                                          
        END      
   END          
    IF ISNULL(@ASSOCTYPEID, 0) = 70             
        BEGIN         
   IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
   BEGIN        
         
    IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)       
    BEGIN      
    PRINT '1234 '      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                      SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                    SELECT  SERIALNUMBER            
     FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                      SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                        
        CP.PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      AND @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         AND @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    AND CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
    FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
          SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                            And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                     And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)                        
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )        
      And (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)      
   END                                    
        END                         
  ELSE             
   IF ISNULL(@ASSOCTYPEID, 0) <> 0            
       AND ISNULL(@ASSOCTYPEID, 0) <> 70             
            BEGIN        
    IF ISNULL(@SEARCHSERIALNUMBER,'') = ''      
    BEGIN       
          
          
     IF ((ISNULL(@APPLICATIONNAME,'') = 'MSWANDROID'  OR ISNULL(@APPLICATIONNAME,'') = 'MSWIOS')  AND  @ISSELECTEDPARTNER=1)    
                begin               
        INSERT  INTO #TEMPLISTTABLE            
        ( PRODUCTID ,            
          SERIALNUMBER ,                                     
           PRODUCTFAMILY  ,          
          PRODUCTLINE,          
          ACTIVEPROMOTION          
         )            
        SELECT TOP (@RECENTCOUNT)      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,            
       CP.PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION            
       FROM              
      CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
                                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE',            
                           'FLEXSPEND' )          
                                AND CP.USEDSTATUS = 1                                          
                                AND CP.SERIALNUMBER IN (            
                                SELECT  CHILDSERIALNUMBER            
                                FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND PRIMARYSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE = 'CHILDASSOCIATE'            
                                UNION            
                                SELECT  PRIMARYSERIALNUMBER            
                           FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                                WHERE PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )                                                  
                          
        INSERT  INTO #TEMPLISTTABLE            
                        ( PRODUCTID ,            
                          SERIALNUMBER ,                                     
                          PRODUCTFAMILY  ,          
      PRODUCTLINE,          
      ACTIVEPROMOTION          
                  )            
                        SELECT TOP (SELECT CAST(APPLICATIONCONFIGVALUE AS int)        
        FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE  APPLICATIONCONFIGNAME='MOBILESERVERPRODUCTLISTCOUNT')      
          CP.PRODUCTID ,            
                                CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
      
    END      
    ELSE      
    BEGIN      
     INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          
         PRODUCTLINE,          
         ACTIVEPROMOTION          
     FROM    
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
                    WHERE   CP.SERIALNUMBER IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
     AND CP.USEDSTATUS = 1         
                    AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
     AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )        
                    AND CP.USEDSTATUS = 1                                    
                    AND CP.SERIALNUMBER IN (            
                    SELECT  CHILDSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
              And PRIMARYSERIALNUMBER = @SERIALNUMBER            
                            And @ASSOCTYPE = 'CHILDASSOCIATE'            
                    UNION            
                    SELECT  PRIMARYSERIALNUMBER            
                    FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                    WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
                                    And @ASSOCTYPE <> 'CHILDASSOCIATE' )                 
                                             
                          
    INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
      SERIALNUMBER ,                           
                      PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                                       
                            CP.PRODUCTFAMILY  ,          
         PRODUCTLINE,          
       ACTIVEPROMOTION          
     FROM              
     CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
     WHERE   CP.SERIALNUMBER NOT IN (            
                            SELECT  SERIALNUMBER            
                            FROM    #tempPRGD)            
        AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE','FLEXSPEND' )           
       AND CP.PRODUCTLINE NOT IN ('STORAGE MODULE','SATA MODULE','NSspTenant','M2 STORAGE MODULE' )          
                            AND CP.USEDSTATUS = 1                                     
       AND CP.SERIALNUMBER  IN (            
                            SELECT  CHILDSERIALNUMBER            
                            FROM    dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And PRIMARYSERIALNUMBER = @SERIALNUMBER            
         And @ASSOCTYPE = 'CHILDASSOCIATE'            
         UNION            
                            SELECT  PRIMARYSERIALNUMBER            
          FROM   dbo.DEVICEASSOCIATION WITH ( NOLOCK )            
                            WHERE   PRODUCTASSOCIATIONTYPEID IN ( 5, 6, 70 )--@ASSOCTYPEID            
                                    And CHILDSERIALNUMBER = @SERIALNUMBER            
      And @ASSOCTYPE <> 'CHILDASSOCIATE' )         
    END      
         
              
           
   END      
   ELSE      
   BEGIN       
      INSERT  INTO #TEMPLISTTABLE            
                    ( PRODUCTID ,            
                      SERIALNUMBER ,                                 
                      PRODUCTFAMILY ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
     )            
                    SELECT  CP.PRODUCTID ,            
                            CP.SERIALNUMBER ,                       
                            CP.PRODUCTFAMILY ,          