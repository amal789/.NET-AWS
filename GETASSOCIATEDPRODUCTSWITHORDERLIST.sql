  
     
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
 @ISPRODUCTGROUPTABLENEEDED VARCHAR(10) ='YES'    -- this parameter from SPUPDATEFIRMWARESERIALNUMBER. to get only serial number detatils         
 , @ISDOWNLOADAVAILABLE INT = NULL
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
     FROM #tempPRGD)            
                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE', 'FLEXSPEND' )          
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
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                            AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
       END      
       ELSE      
       BEGIN      
       print 'eeee'      
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
                         SELECT       
          CP.PRODUCTID ,            
    CP.SERIALNUMBER ,                                        
        CP.PRODUCTFAMILY  ,          
        PRODUCTLINE,          
        ACTIVEPROMOTION          
                      FROM              
        CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
      WHERE   CP.SERIALNUMBER NOT IN (            
      SELECT  SERIALNUMBER           
     FROM #tempPRGD)            
                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE', 'FLEXSPEND' )          
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
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
       END      
    END      
 ELSE      
    BEGIN      
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
      SELECT  SERIALNUMBER           
     FROM #tempPRGD)            
                AND CP.PRODUCTFAMILY NOT IN ( 'CLIENTLICENSE', 'FLEXSPEND' )          
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
                                WHERE   PRODUCTASSOCIATIONTYPEID = @ASSOCTYPEID            
                                        AND CHILDSERIALNUMBER = @SERIALNUMBER            
                                        AND @ASSOCTYPE <> 'CHILDASSOCIATE' )        
    AND (CP.SERIALNUMBER = @SEARCHSERIALNUMBER OR CP.NAME = @SEARCHSERIALNUMBER)       
    END               
                                             
 END         
      
          
 -- UPDATE  #TEMPLISTTABLE            
 -- SET     FIRMWAREVERSION = DISPLAYFIRMWAREVERSION,                              
 ----REGCODE = F.REGISTRATIONCODE,          
 --DEVICESTATUS =  CASE WHEN DATEDIFF(DD, ISNULL(LASTPINGDATE,100), GETDATE())<=2 THEN 'Online' ELSE 'Offline'          
 --   END            
 --FROM #TEMPLISTTABLE T,  FIREWALLINSTANCES F WITH ( NOLOCK )          
 --WHERE T.SERIALNUMBER = F.SERIALNUMBER        
               
       
 --   END           
 --ELSE        
 --BEGIN        
             
 --   UPDATE  #TEMPLISTTABLE            
 -- SET     PRODUCTGROUPNAMES = stuff((select distinct ',' + vw.PRODUCTGROUPNAME from VWPARTYPRODUCTGROUPDETAIL vw    (NOLOCK)          
 -- where vw.SERIALNUMBER = TMP.SERIALNUMBER and VW.CONTACTID = @CONTACTID  for xml path('')),1,1,'') + ','             
 -- FROM    #TEMPLISTTABLE TMP            
           
 -- -- To return productgroup names even if no user group is associated to it-- Fix for productgroup filter not working          
 -- Update #TEMPLISTTABLE          
 -- Set PRODUCTGROUPNAMES = stuff((select distinct ',' +  PRODUCTGROUPNAME FROM PRODUCTGROUP P (nolock), PRODUCTGROUPDETAIL PGD(NOLOCK)          
 -- where PGD.PRODUCTGROUPID = P.PRODUCTGROUPID AND PGD.SERIALNUMBER= TMP.SERIALNUMBER for xml path('')),1,1,'') + ','           
 -- FROM #TEMPLISTTABLE TMP WHERE ISNULL(TMP.PRODUCTGROUPNAMES,'') = ''          
        
 --END        
            
             
    INSERT INTO @GROUPTABLE(GROUPID,GROUPNAME,GROUPTYPE)          
    SELECT DISTINCT VW.PRODUCTGROUPID,VW.PRODUCTGROUPNAME,'PRODUCTGROUP'          
     FROM    VWPARTYPRODUCTGROUPDETAIL VW  (NOLOCK) ,          
            #TEMPLISTTABLE TMP          
    WHERE   vw.SERIALNUMBER = TMP.SERIALNUMBER           
    AND        VW.CONTACTID = @CONTACTID           
              
    UNION            
 SELECT DISTINCT PARTYGROUPID,VW.PARTYGROUPNAME,'USERGROUP'          
     FROM    VWPARTYPRODUCTGROUPDETAIL VW  (NOLOCK),          
            #TEMPLISTTABLE TMP          
    WHERE   vw.SERIALNUMBER = TMP.SERIALNUMBER           
    AND        VW.CONTACTID = @CONTACTID           
              
    UPDATE  #TEMPLISTTABLE          
       set     PARTYGROUPNAME = ISNULL(VW.PARTYGROUPNAME,'')          
    FROM    VWPARTYPRODUCTGROUPDETAIL VW  (NOLOCK),          
            #TEMPLISTTABLE TMP          
    WHERE   vw.SERIALNUMBER = TMP.SERIALNUMBER           
    AND        VW.CONTACTID = @CONTACTID            
            
                                     
          
 IF @APPNAME IN ( 'SNB' )             
    BEGIN            
            
           
  --DECLARE @TMPGETSERIAL TABLE          
  --      (          
  --          ID INT IDENTITY(1, 1) ,          
  --          SERIALNUMBER VARCHAR(30),          
  -- EPAID VARCHAR(30)          
  --)              
            
  --INSERT INTO @TMPGETSERIAL          
  -- SELECT SERIALNUMBER,EPAID FROM DEAREGISTRATION NOLOCK WHERE SERIALNUMBER IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)          
            
  --select * from dearegistration nolock where serialnumber in (select SERIALNUMBER from   
         
  UPDATE  #TEMPLISTTABLE          
  SET     EPAID = DEA.EPAID          
  FROM    DEAREGISTRATION DEA WITH (NOLOCK) ,          
  #TEMPLISTTABLE TMP          
  WHERE DEA.SERIALNUMBER = TMP.SERIALNUMBER           
            
             
 END           
          
      
      
  update #TEMPLISTTABLE SET      
  CURRENTNODESUPPORT  = CASE WHEN T.PRODUCTID = 7636      
  THEN (SELECT ISNULL(NODECOUNT,1)        
            FROM    dbo.SERVICESSUMMARY WITH ( NOLOCK )        
        WHERE   SERIALNUMBER = F.SERIALNUMBER        
                    AND SERVICEFAMILY = 'NETWORKSECURITYMANAGER' )      
  WHEN T.PRODUCTID != 300 THEN F.CURRENTNODESUPPORT END      
  from #TEMPLISTTABLE t         
  inner join  FIREWALLINSTANCES F with (nolock)         
  on t.SERIALNUMBER=F.serialnumber       
      
 update #TEMPLISTTABLE SET CCNODECOUNT=CP.CCNODECOUNT,        
  CASNODECOUNT=CP.CASNODECOUNT,        
  HESNODECOUNT= CASE WHEN T.PRODUCTID = 300 THEN CP.HESNODECOUNT       
  WHEN T.PRODUCTID = 401 THEN 0      
  WHEN T.PRODUCTID = 408 THEN 0      
  WHEN T.PRODUCTID = 7636 THEN (CASE WHEN CURRENTNODESUPPORT = 0 THEN 1 ELSE CURRENTNODESUPPORT END)       
  ELSE (CASE WHEN CURRENTNODESUPPORT = -1 THEN '5555' ELSE CURRENTNODESUPPORT END)       
  END,      
  GMSNODECOUNT=CP.GMSNODECOUNT,        
  SASELICENSECOUNT=CP.SASELICENSECOUNT,        
  PRODUCTGROUPID=CP.PRODUCTGROUPID,        
  PRODUCTGROUPNAME=CP.PRODUCTGROUPNAME,        
  SUPPORTDATE=CP.SUPPORTDATE,        
  SOONEXPIRYDATE=CP.SOONEXPIRYDATE,        
  MINLICENSEEXPIRYDATE=CP.MINLICENSEEXPIRYDATE,        
  ASSOCIATIONTYPE=CP.ASSOCIATIONTYPE,        
  LICENSEEXPIRYCNT=CP.LICENSEEXPIRYCNT,        
  SOONEXPIRINGCNT=CP.SOONEXPIRINGCNT,        
  ACTIVELICENSECNT =CP.ACTIVELICENSECNT,      
  ISNETWORKPRODUCT=CP.ISNETWORKPRODUCT,      
  --LASTPINGDATE= CASE WHEN @APPNAME='SNB' THEN CP.LASTPINGDATE  END     
  LASTPINGDATE=CP.LASTPINGDATE,  
  ISDOWNLOADAVAILABLE = CP.UPDATESAVAILABLE   
  from #TEMPLISTTABLE t         
  inner join  CUSTOMERPRODUCTSSUMMARY cp with (nolock)         
  on t.SERIALNUMBER=CP.serialnumber        
        
           
  IF EXISTS (SELECT T.SERIALNUMBER FROM #TEMPLISTTABLE T         
  INNER JOIN  CUSTOMERPRODUCTSSUMMARYACTIVITY CP WITH (NOLOCK)  ON T.SERIALNUMBER=CP.SERIALNUMBER        
  AND STATUS=0 AND ACTION='ALL')        
  BEGIN         
        
   UPDATE #TEMPLISTTABLE SET CCNODECOUNT = ISNULL((SELECT TOP 1 ISNULL(NODECOUNT,0) FROM              
  SERVICESSUMMARY SM WITH ( NOLOCK )             
  WHERE  SM.SERIALNUMBER = T.SERIALNUMBER              
  AND  SM.SERVICEFAMILY IN ('SENTINELONE','SENTINELONEADVANCED','SENTINELONEPREMIER','CCMDR')  ),0),            
  CASNODECOUNT = CASE WHEN T.PRODUCTID = 402 THEN ISNULL((SELECT ISNULL(NODECOUNT,0) FROM              
  SERVICESSUMMARY SM WITH ( NOLOCK )             
  WHERE  SM.SERIALNUMBER = T.SERIALNUMBER              
  AND  SM.SERVICEFAMILY ='CAS'),0)            
  ELSE 0 END,            
  HESNODECOUNT = CASE WHEN T.PRODUCTID = 300 THEN ISNULL((SELECT ISNULL(NODECOUNT,0) FROM              
  SERVICESSUMMARY SM WITH ( NOLOCK )             
  WHERE  SM.SERIALNUMBER = T.SERIALNUMBER              
  AND  SM.SERVICEFAMILY ='EMAILTHREAT'),0)         
  WHEN T.PRODUCTID = 404 THEN ISNULL((SELECT  TOP 1 ISNULL(NODECOUNT,0) FROM                
 SERVICESSUMMARY SM WITH ( NOLOCK )               
 WHERE  SM.SERIALNUMBER = T.SERIALNUMBER             
 AND  SM.SERVICEFAMILY IN ('CESADVANCED','CESESSENTIAL')),0)       
  ELSE ISNULL(HESNODECOUNT,0) END,         
  GMSNODECOUNT = ISNULL((SELECT ISNULL(NODECOUNT,0) FROM              
  SERVICESSUMMARY SM WITH ( NOLOCK )             
  WHERE  SM.SERIALNUMBER = T.SERIALNUMBER              
  AND  SM.SERVICEFAMILY ='GMSMANAGEMENT'),0) ,          
   SASELICENSECOUNT = ISNULL((SELECT ISNULL(NODECOUNT,0) FROM              
  SERVICESSUMMARY SM WITH ( NOLOCK )             
  WHERE  SM.SERIALNUMBER = T.SERIALNUMBER              
  AND  SM.SERVICEFAMILY ='ZTNA'),0)                          
  FROM #TEMPLISTTABLE T        
        
  UPDATE  #TEMPLISTTABLE            
    SET     PRODUCTGROUPID = PG.PRODUCTGROUPID ,            
            PRODUCTGROUPNAME = PG.PRODUCTGROUPNAME        
    FROM    PRODUCTGROUP PG WITH ( NOLOCK ) ,            
            PRODUCTGROUPDETAIL PGD WITH ( NOLOCK ) ,            
            #TEMPLISTTABLE TMP            
    WHERE   PG.PRODUCTGROUPID = PGD.PRODUCTGROUPID            
            AND PGD.SERIALNUMBER = TMP.SERIALNUMBER          
           
         
 --UPDATE #TEMPLISTTABLE          
 --  SET ROLETYPE = dbo.FNGETTENANTGROUPPERMISSION(@USERNAME,T.PRODUCTGROUPID,'ACCESSTYPEPRODMGMT','USER')          
 --  FROM #TEMPLISTTABLE T           
           
 UPDATE  #TEMPLISTTABLE              
 SET     LICENSEEXPIRYCNT = (SELECT COUNT(*) FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)                 
 WHERE EXPIRATIONDATE < CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE >= CAST(GETDATE()-90 AS DATE)             
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER AND CP.PRODUCTID <> 401 AND ISNULL(UPPER(ASSOCIATIONTYPE),'') NOT IN ('HA PRIMARY')),  -- to not to consider expired count for CC client           
            
 SOONEXPIRINGCNT = (SELECT COUNT(*) FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)               
 WHERE EXPIRATIONDATE >= CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE < CAST(GETDATE()+90 AS DATE)             
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER AND ISNULL(UPPER(ASSOCIATIONTYPE),'') NOT IN ('HA PRIMARY')),  -- to not to consider expiring count for CC client           
           
 ACTIVELICENSECNT = (SELECT COUNT(*) FROM SERVICESSUMMARY SM WITH ( NOLOCK ) , productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)                
 WHERE EXPIRATIONDATE > CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE >= CAST(GETDATE()+90 AS DATE)             
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER AND CP.PRODUCTID <> 401 AND ISNULL(UPPER(ASSOCIATIONTYPE),'') NOT IN ('HA PRIMARY'))        
FROM #TEMPLISTTABLE T           
      
  UPDATE  #TEMPLISTTABLE      
 SET SOONEXPIRINGCNT = CASE WHEN EXISTS(SELECT 0 FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)               
 WHERE EXPIRATIONDATE >= CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE < CAST(GETDATE()+90 AS DATE)             
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER AND CP.PRODUCTID = 401 AND ISNULL(UPPER(ASSOCIATIONTYPE),'') IN ('HA PRIMARY'))       
THEN 0 ELSE SOONEXPIRINGCNT END      
FROM #TEMPLISTTABLE T        
        
          
   UPDATE #TEMPLISTTABLE             
  SET     SUPPORTEXPIRYDATE = CASE WHEN ISNULL(T.SUPPORTDATE,'') <> ''             
                   THEN (SELECT MAX(EXPIRATIONDATE) FROM SERVICESSUMMARY SM WITH ( NOLOCK ) , productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)          
    WHERE SM.SERIALNUMBER =  T.SERIALNUMBER AND SM.SERVICEFAMILY IN ( 'SUPPORT8X5',              
                                                 'SUPPORT24X7',              
                                                                   'MSSPSUPPORT8x5',              
                     'MSSPSUPPORT24X7',                     
               'GMS24x7',              
                                                                   'GMSCGSSUPPORT24x7')          
     AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER          
AND EXPIRATIONDATE >= CAST(GETDATE()-90 AS DATE))            
                   END,  -- consider max of expiration dates in case of support services            
  NONSUPPORTEXPIRYDATE = CASE WHEN ISNULL(T.SUPPORTDATE,'') <> ''             
                   THEN (SELECT MIN(EXPIRATIONDATE) FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)             
    WHERE SM.SERIALNUMBER =  T.SERIALNUMBER AND SM.SERVICEFAMILY NOT IN ( 'SUPPORT8X5',              
                                                                   'SUPPORT24X7',              
                                                                   'MSSPSUPPORT8x5',              
                        'MSSPSUPPORT24X7',                     
                                                                   'GMS24x7',              
                                                                   'GMSCGSSUPPORT24x7')          
                             AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER          
AND EXPIRATIONDATE >= CAST(GETDATE()-90 AS DATE))           
ELSE          
(SELECT MIN(EXPIRATIONDATE) FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)             
    WHERE SM.SERIALNUMBER =  T.SERIALNUMBER AND SM.SERVICEFAMILY NOT IN ( 'SUPPORT8X5',              
                                                                   'SUPPORT24X7',              
                                                                   'MSSPSUPPORT8x5',              
                                                                   'MSSPSUPPORT24X7',                      
                                                                   'GMS24x7',              
                                                                   'GMSCGSSUPPORT24x7')          
                                                                   AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER          
AND EXPIRATIONDATE >= CAST(GETDATE()-90 AS DATE))            
 END  -- consider min of expiration dates in case of non support services                            
      FROM  #TEMPLISTTABLE T         
        
 UPDATE #TEMPLISTTABLE -- when theres is no support services for the serialnumber            
 SET SOONEXPIRYDATE = CASE WHEN ISNULL(T.SUPPORTDATE,'') = ''           
                   THEN            
(SELECT TOP 1 EXPIRATIONDATE FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)              
 WHERE EXPIRATIONDATE >= CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE < CAST(GETDATE()+90 AS DATE)               
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER        
AND ISNULL(UPPER(ASSOCIATIONTYPE),'') NOT IN ('HA PRIMARY'))             
 END            
 FROM #TEMPLISTTABLE T            
          
 UPDATE  #TEMPLISTTABLE  -- when theres is support services for the serialnumber            
 SET  SOONEXPIRYDATE = CASE WHEN ISNULL(T.SUPPORTDATE,'') <> ''           
                   THEN CASE WHEN SUPPORTEXPIRYDATE < NONSUPPORTEXPIRYDATE AND             
 SUPPORTEXPIRYDATE >= CAST(GETDATE() AS DATE) AND  SUPPORTEXPIRYDATE < CAST(GETDATE()+90 AS DATE)           
 THEN SUPPORTEXPIRYDATE -- if support service is lesser than non support services, and it has got expired within next 90 days            
 WHEN  NONSUPPORTEXPIRYDATE <= SUPPORTEXPIRYDATE AND NONSUPPORTEXPIRYDATE >= CAST(GETDATE() AS DATE)             
 AND  NONSUPPORTEXPIRYDATE < CAST(GETDATE()+90 AS DATE)          
 THEN NONSUPPORTEXPIRYDATE -- if non-support service is lesser than support services, and it has got expired within next 90 days           
 ELSE SOONEXPIRYDATE           
 END           
 ELSE SOONEXPIRYDATE               
 END          
  FROM #TEMPLISTTABLE T           
        
           
   UPDATE #TEMPLISTTABLE -- when theres is no support case for the serialnumber            
 SET MINLICENSEEXPIRYDATE = CASE WHEN ISNULL(T.SUPPORTDATE,'') = ''           
                   THEN            
(SELECT TOP 1 EXPIRATIONDATE FROM SERVICESSUMMARY SM WITH ( NOLOCK ), productservices PS with(NOLOCK) , CUSTOMERPRODUCTS CP with(NOLOCK)              
 WHERE EXPIRATIONDATE < CAST(GETDATE() AS DATE) AND  EXPIRATIONDATE >= CAST(GETDATE()-90 AS DATE)             
 AND SM.SERIALNUMBER = T.SERIALNUMBER AND SM.serviceid = PS.serviceid          
AND isdisplayable = 1          
AND CP.PRODUCTID = PS.PRODUCTID          
AND CP.SERIALNUMBER = SM.SERIALNUMBER)             
   -- when theres is  support case for the serialnumber            
 WHEN ISNULL(T.SUPPORTDATE,'') <> '' THEN           
 (CASE WHEN SUPPORTEXPIRYDATE < NONSUPPORTEXPIRYDATE AND             
 SUPPORTEXPIRYDATE < CAST(GETDATE() AS DATE) AND  SUPPORTEXPIRYDATE >= CAST(GETDATE()-90 AS DATE)              
 THEN SUPPORTEXPIRYDATE -- if support service is lesser than non support services, and it has got expired within last 30 days           
 WHEN  NONSUPPORTEXPIRYDATE <= SUPPORTEXPIRYDATE AND NONSUPPORTEXPIRYDATE < CAST(GETDATE() AS DATE)             
 AND  NONSUPPORTEXPIRYDATE >= CAST(GETDATE()-90 AS DATE)              
 THEN NONSUPPORTEXPIRYDATE END) -- if non-support service is lesser than support services, and it has got expired within last 30 days            
 ELSE MINLICENSEEXPIRYDATE          
 END           
 FROM #TEMPLISTTABLE T  WHERE T.PRODUCTID <> 401           
        
  end        
      
 UPDATE T SET PRODUCTCHOICEID = M.PRODUCTCHOICEID  
 FROM #TEMPLISTTABLE T, MASTERMSSPPRODUCTSERVICES M WITH(NOLOCK) WHERE M.PRODUCTID = T.PRODUCTID  
        
  DECLARE @ROLETYPELOGIC VARCHAR(5)          
  SELECT  TOP 1 @ROLETYPELOGIC= APPLICATIONCONFIGVALUE FROM APPLICATIONCONFIGVALUE WITH (NOLOCK) WHERE APPLICATIONCONFIGNAME='USEGROUPMGMTSUMMARYTABLE'        
        
IF(@ROLETYPELOGIC='YES')        
  BEGIN         
        
 /*UPDATE #TEMPLISTTABLE        
    SET ROLETYPE =        
  CASE        
  (SELECT TOP 1 ISSUPERADMIN FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID) WHEN 'YES' THEN 'SUPERADMIN'        
  ELSE (SELECT TOP 1 ACCESSTYPEPRODMGMTROLETYPE         
  FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID ) END       
  FROM #TEMPLISTTABLE P  WITH (NOLOCK)*/        
--Adding ISNULL to check and return the roletype using FNGETTENANTGROUPPERMISSION function,incase TENANTGROUPPERMISSIONSUMMARY has NULL values for roletype columns.        
UPDATE #TEMPLISTTABLE        
    SET ROLETYPE =        
  CASE        
  (SELECT TOP 1 ISSUPERADMIN FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID        
  AND PARTYID IN (SELECT PARTYID FROM PARTY(NOLOCK) WHERE CONTACTID = @CONTACTID)) WHEN 'YES' THEN 'SUPERADMIN'        
  ELSE         
  ISNULL((SELECT TOP 1 ACCESSTYPEPRODMGMTROLETYPE         
  FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID AND PARTYID IN (SELECT PARTYID FROM PARTY(NOLOCK) WHERE CONTACTID = @CONTACTID))         
  ,dbo.FNGETTENANTGROUPPERMISSION(@USERNAME,P.PRODUCTGROUPID,@APPLICATIONFUNCTIONALITY,'USER', DEFAULT))        
  END        
  FROM #TEMPLISTTABLE P  WITH (NOLOCK)        
        
END         
IF(@ROLETYPELOGIC='NO') OR          
 EXISTS(SELECT T.PRODUCTGROUPID FROM #TEMPLISTTABLE T   WITH (NOLOCK)        
   INNER JOIN  TENANTACTIVITYSTAGING CP WITH (NOLOCK)          
   ON T.PRODUCTGROUPID=CP.PRODUCTGROUPID        
   AND PROCESSED='NO')         
BEGIN         
 UPDATE #TEMPLISTTABLE          
   SET ROLETYPE = DBO.FNGETTENANTGROUPPERMISSION(@USERNAME,T.PRODUCTGROUPID,'ACCESSTYPEPRODMGMT','USER', DEFAULT)          
   FROM #TEMPLISTTABLE T        
END        
        
        
          
UPDATE #TEMPLISTTABLE            
 SET ORGNAME = IO.ORGANIZATIONNAME, ORGID=@ORGID,      
 ISSHAREDTENANT = CASE WHEN @ORGID <> PR.ORGANIZATIONID THEN 'YES' ELSE 'NO' END      
 FROM  #TEMPLISTTABLE T , PARTY PR (NOLOCK), PRODUCTGROUP PG (NOLOCK),  ORGANIZATION IO (NOLOCK)              
 WHERE PR.PARTYID = PG.ADMINPARTYID AND PG.PRODUCTGROUPID= T.PRODUCTGROUPID            
  AND IO.ORGANIZATIONID = PR.ORGANIZATIONID          
              
                       
 --  IF EXISTS (SELECT * FROM APPLICATIONCONFIGVALUE (NOLOCK) WHERE APPLICATIONCONFIGNAME = 'ISRBACPERMISSIONNEEDED' AND APPLICATIONCONFIGVALUE = 'TRUE')          
 --BEGIN          
  DECLARE @APPLICATIONFUNCATIONALITYID INT=0          
  SELECT  TOP 1 @APPLICATIONFUNCATIONALITYID= APPLICATIONFUNCATIONALITYID from applicationfunctionality nolock where internaldescription='ACCESSTYPEPRODMGMT'          
          
  --UPDATE T           
  --SET ROLETYPE = G.ACCESSTYPEPRODMGMTROLETYPE          
  --FROM #TEMPLISTTABLE T WITH (NOLOCK)           
  --inner join CUSTOMERPRODUCTSSUMMARY cp with (nolock)        
  --on cp.serialnumber=t.serialnumber        
  --INNER JOIN TENANTGROUPPERMISSIONSUMMARY G WITH (NOLOCK)           
  --ON t.PRODUCTGROUPID=G.PRODUCTGROUPID          
  --AND G.USERNAME=@USERNAME          
        
      UPDATE #TEMPLISTTABLE SET      
    HESNODECOUNT = CASE WHEN #TEMPLISTTABLE.PRODUCTID = 404 THEN ISNULL((SELECT  TOP 1 ISNULL(NODECOUNT,0) FROM                
 SERVICESSUMMARY SM WITH ( NOLOCK )               
 WHERE  SM.SERIALNUMBER = #TEMPLISTTABLE.SERIALNUMBER             
 AND  SM.SERVICEFAMILY IN ('CESADVANCED','CESESSENTIAL')),0)       
 ELSE HESNODECOUNT END        
        
            
   DELETE FROM #TEMPLISTTABLE            
   WHERE PRODUCTGROUPID IN (            
   SELECT PRODUCTGROUPID FROM PARTYPRODUCTGROUP(NOLOCK)            
   WHERE PARTYGROUPID IN ( SELECT PARTYGROUPID FROM PARTYPRODUCTGROUPDETAIL(NOLOCK) WHERE PERMISSIONTYPEDETAILID IN             
   (SELECT PERMISSIONTYPEDETAILID FROM PERMISSIONTYPEDETAIL(NOLOCK) WHERE EXTERNALNAME = 'NOACCESS' AND             
   APPLICATIONFUNCATIONALITYID=@APPLICATIONFUNCATIONALITYID ))          
   AND PARTYGROUPID IN (SELECT PARTYGROUPID FROM PARTYGROUPDETAIL (NOLOCK) WHERE PARTYID IN (          
      SELECT PARTYID FROM PARTY(NOLOCK) WHERE CONTACTID =@CONTACTID)))          
    AND ROLETYPE <> 'SUPERADMIN'          
          
 --END          
                
--300 Hosted Email Security        
--310 Cloud Manager        
--320 ON-PREM ANALYZER        
--321 On-Prem Syslog Analytics        
--400 Cloud GMS        
--401 Capture Client        
--402 CAS        
--403 Cloud Edge        
--300,400, 401,402,403        
        
  --IF EXISTS (SELECT * FROM APPLICATIONCONFIGVALUE (NOLOCK) WHERE APPLICATIONCONFIGNAME = 'ISRBACPERMISSIONNEEDED' AND APPLICATIONCONFIGVALUE = 'TRUE') AND           
  IF EXISTS (SELECT APPLICATIONPARTYROLEID FROM APPLICATIONPARTYROLE NOLOCK WHERE PARTYID=(SELECT TOP 1 PARTYID FROM VCUSTOMER(NOLOCK) WHERE USERNAME=@USERNAME) AND           
  APPLICATIONROLEID IN(SELECT APPLICATIONROLEID FROM APPLICATIONROLE NOLOCK WHERE ROLENAME='WORKSPACEBETA' AND APPLICATIONNAME='MSW')) OR          
  EXISTS(SELECT * FROM APPLICATIONCONFIGVALUE NOLOCK WHERE APPLICATIONCONFIGNAME='ISWORKSPACEENABLED' AND APPLICATIONCONFIGVALUE='FORCED')           
  BEGIN          
   UPDATE #TEMPLISTTABLE            
   SET ISRENAMEALLOWED = CASE WHEN PRODUCTID IN (  401,402,403,408 ) THEN 'NO' ELSE 'YES' END , -- Rename is restricted for CC, CAS and SASE tenants          
   ISTRANSFERALLOWED =CASE WHEN PRODUCTID IN (  400  ) THEN 'NO' WHEN ACTIVEPROMOTION =1 AND @ROLLUP = 0 THEN 'NO'           
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END,          
   ISDELETEALLOWED =CASE WHEN PRODUCTID IN (  400  ) THEN 'NO' WHEN ACTIVEPROMOTION =1 THEN 'NO'           
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END,          
   ISSECUREUPGRADE = CASE WHEN ACTIVEPROMOTION =1 THEN 'YES' ELSE 'NO' END           
          
    UPDATE #TEMPLISTTABLE           
  SET ISRENAMEALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY') THEN 'NO'  ELSE ISRENAMEALLOWED END,          
  ISDELETEALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY','OPERATOR') THEN 'NO' ELSE ISDELETEALLOWED END,          
  ISTRANSFERALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY','OPERATOR') THEN 'NO' ELSE ISTRANSFERALLOWED END,          
  ISZEROTOUCHALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY') THEN 'NO' END          
   FROM    #TEMPLISTTABLE TMP           
  END          
  ELSE          
  BEGIN          
  UPDATE #TEMPLISTTABLE            
   SET ISRENAMEALLOWED = CASE WHEN PRODUCTID IN ( 401,402,403,408 ) THEN 'NO' ELSE 'YES' END , -- Rename is restricted for CC, CAS and SASE tenants          
   ISTRANSFERALLOWED =CASE WHEN OWNEROFTHEPRODUCT!=1 THEN 'NO' WHEN PRODUCTID IN ( 401 ) THEN 'NO' WHEN ACTIVEPROMOTION =1 AND @ROLLUP = 0 THEN 'NO'            
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END,          
   ISDELETEALLOWED =CASE WHEN OWNEROFTHEPRODUCT!=1 THEN 'NO'  WHEN ACTIVEPROMOTION =1 THEN 'NO'           
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END,          
   ISSECUREUPGRADE = CASE WHEN ACTIVEPROMOTION =1 THEN 'YES' ELSE 'NO' END ,          
   ISZEROTOUCHALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY') THEN 'NO' END           
  END          
      
  IF ISNULL(@ISMSSPUSER, '') <> ''      
 UPDATE #TEMPLISTTABLE              
 SET MSSPMONTHLYOPTION = CASE WHEN #TEMPLISTTABLE.PRODUCTID IN (SELECT MS.PRODUCTID      
     FROM MASTERMSSPPRODUCTSERVICES MS WITH (NOLOCK), CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
      CP.SERIALNUMBER = #TEMPLISTTABLE.SERIALNUMBER AND MS.STATUS='ACTIVE' AND CP.MSSPMONTHLY = 'YES')      
  THEN 'DISABLE' -- MSSP Monthly is enabled, hence show disable option      
      
  WHEN #TEMPLISTTABLE.PRODUCTID IN (SELECT MS.PRODUCTID      
     FROM MASTERMSSPPRODUCTSERVICES MS WITH (NOLOCK), CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
     CP.SERIALNUMBER = #TEMPLISTTABLE.SERIALNUMBER AND MS.STATUS='ACTIVE' AND ISNULL(CP.MSSPMONTHLY,'NO') = 'NO')      
  THEN 'ENABLE' END -- MSSP Monthly is disabled, hence show enable option      
        
 -- UPDATE #TEMPLISTTABLE              
 --SET MSSPMONTHLYOPTION = CASE WHEN ISNULL(PG.MASTERMSSPID,0)=0 THEN ''       
 --WHEN ISNULL(PG.MASTERMSSPID,0)>0 AND PG.ISMAPPEDMSSPID=1 THEN '' ELSE MSSPMONTHLYOPTION END      
 --FROM #TEMPLISTTABLE T,  DBO.FNNONMSSPTENANTSLIST(@USERNAME) PG       
 --WHERE T.PRODUCTGROUPID=PG.PRODUCTGROUPID      
       
      
  --In case primary product is NSM then enable isAddKeySetApplicable      
  IF EXISTS (select producttype from genericproducts WITH (NOLOCK) where producttype='NSM ON-PREM' and PRODUCTID IN (SELECT PRODUCTID FROM PRODUCTSERIALNUMBERS WITH (NOLOCK) WHERE SERIALNUMBER=@SERIALNUMBER) )      
  BEGIN      
  UPDATE #TEMPLISTTABLE SET ISADDKEYSETAPPLICABLE = 'YES'      
  END      
      
   UPDATE #TEMPLISTTABLE      
   SET PSAADDITIONSEXPIRYDATE= (SELECT MAX(SM.EXPIRATIONDATE ) FROM  SERVICESSUMMARY SM (NOLOCK)      
   WHERE #TEMPLISTTABLE.SERIALNUMBER=SM.SERIALNUMBER AND SM.EXPIRATIONDATE IS NOT NULL)      
   FROM  #TEMPLISTTABLE, SERVICESSUMMARY SM (NOLOCK)      
         
   UPDATE #TEMPLISTTABLE      
   SET ISBILLABLE=CASE WHEN DATEDIFF(DD, GETDATE(), #TEMPLISTTABLE.PSAADDITIONSEXPIRYDATE) <0 THEN 'NO' ELSE #TEMPLISTTABLE.ISBILLABLE END      
   FROM  #TEMPLISTTABLE, CUSTOMERPRODUCTSSUMMARY C (NOLOCK)      
   WHERE #TEMPLISTTABLE.SERIALNUMBER=C.SERIALNUMBER AND ISNULL(C.PRODUCTTYPE,'') !='FIREWALL'       
      
  UPDATE #TEMPLISTTABLE            
   SET ISDELETEALLOWED = 'NO' WHERE SERIALNUMBER IN(SELECT CHILDSERIALNUMBER FROM DEVICEASSOCIATION (NOLOCK) WHERE  
   PRODUCTASSOCIATIONTYPEID=(SELECT PRODUCTASSOCIATIONTYPEID FROM PRODUCTASSOCIATIONTYPE WITH (NOLOCK)  
   WHERE INTERNALDESCRIPTION='VL_ASSOCIATION') AND CHILDSERIALNUMBER IN  
   (SELECT SERIALNUMBER FROM #TEMPLISTTABLE))      
              
          
    UPDATE #TEMPLISTTABLE         
   SET ISDELETEALLOWED = 'NO',ISZEROTOUCHALLOWED='NO'  WHERE SERIALNUMBER IN (SELECT SERIALNUMBER FROM  PUBLICCLOUDINSTANCESREGISTER (NOLOCK) WHERE PUBLICCLOUDNAME='VOLUMELICENSING')      
              
   UPDATE #TEMPLISTTABLE            
   SET ISDELETEALLOWED = 'NO'      
   WHERE SERIALNUMBER IN (SELECT SERIALNUMBER FROM  MSSPPRODUCTSERVICESSUMMARY with(NOLOCK)       
   WHERE STATUS='ACTIVE')        
         
          
IF EXISTS(SELECT 1 FROM DEVICEASSOCIATION DA with (nolock),#TEMPLISTTABLE T WHERE CHILDSERIALNUMBER=T.SERIALNUMBER        
 AND PRODUCTASSOCIATIONTYPEID IN (SELECT  PRODUCTASSOCIATIONTYPEID       
 FROM DBO.PRODUCTASSOCIATIONTYPE WITH ( NOLOCK ) WHERE INTERNALDESCRIPTION  ='HA_ASSOCIATION' ))      
BEGIN      
  UPDATE T            
   SET ISDELETEALLOWED = 'NO'      
   FROM DEVICEASSOCIATION DA with (nolock),#TEMPLISTTABLE T WHERE CHILDSERIALNUMBER=T.SERIALNUMBER        
    AND PRODUCTASSOCIATIONTYPEID IN (SELECT PRODUCTASSOCIATIONTYPEID FROM DBO.PRODUCTASSOCIATIONTYPE WITH (NOLOCK)       
 WHERE INTERNALDESCRIPTION ='HA_ASSOCIATION' )      
   AND  SERIALNUMBER IN (SELECT HASECONDARY FROM  MSSPPRODUCTSERVICESSUMMARY with(NOLOCK)       
   WHERE STATUS='ACTIVE')       
 END           
       
 UPDATE #TEMPLISTTABLE SET       
 EMAILADDRESS = VC.EMAILADDRESS,      
 DESCRIPTION=CP.FRIENDLYNAME  
 --MANAGEMENTOPTION=CP.MANAGEMENTOPTION  
 FROM vCUSTOMER VC, #TEMPLISTTABLE T,      
 CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
 CP.SERIALNUMBER = T.SERIALNUMBER AND      
 CP.USERNAME=VC.USERNAME AND ISNULL(VC.ISORGADMIN,0)=0      
  
 --ONBOX-AMAL  
  UPDATE #TEMPLISTTABLE SET     
MANAGEMENTOPTION=CP.MANAGEMENTOPTION  
 FROM  #TEMPLISTTABLE T,      
 CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
 CP.SERIALNUMBER = T.SERIALNUMBER       
  
  
 --select  * from #TEMPLISTTABLE where SERIALNUMBER ='0040103F9108'  
      
  UPDATE #TEMPLISTTABLE SET       
 EMAILADDRESS = VC.EMAILADDRESS,      
 DESCRIPTION=CP.FRIENDLYNAME      
 FROM vCUSTOMER VC, #TEMPLISTTABLE T,      
 CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
 CP.SERIALNUMBER = T.SERIALNUMBER AND      
 CP.REGISTEREDUSERNAME=VC.USERNAME AND ISNULL(VC.ISORGADMIN,0)=0      
          
  UPDATE  T SET PRODUCTLINE= GP.PRODUCTTYPE      
  FROM #TEMPLISTTABLE   T       
  ,GENERICPRODUCTS GP WITH (NOLOCK)      
        
  ,PRODUCTS P WITH (NOLOCK)      
  WHERE T.PRODUCTID=GP.PRODUCTID AND P.PRODUCTID=GP.PRODUCTID      
  AND P.PRODUCTLINE='NSM ON-PREM'      
 IF @ASSOCTYPEID=(SELECT PRODUCTASSOCIATIONTYPEID FROM PRODUCTASSOCIATIONTYPE (NOLOCK) WHERE INTERNALDESCRIPTION='FIREWALL_CONNECTOR')    
      BEGIN        
       --DECLARE @IT INT =0        
       --DECLARE @CNT INT        
       --DECLARE @ISER VARCHAR(40)        
       --DECLARE @ICONNECTORNAME VARCHAR(100)        
       SELECT @CNT=COUNT(*) FROM #TEMPLISTTABLE        
        
       WHILE @IT < @CNT        
       BEGIN        
        SELECT @IT=@IT +1              
         SELECT @ICONNECTORNAME=D.CONNECTORNAME FROM DEVICEASSOCIATION D (NOLOCK) WHERE D.CHILDSERIALNUMBER=(SELECT TOP 1 SERIALNUMBER FROM #TEMPLISTTABLE (NOLOCK) WHERE CID=@IT) AND D.PRODUCTASSOCIATIONTYPEID=@ASSOCTYPEID         
   if @ICONNECTORNAME is null  
   set @ICONNECTORNAME =@CONNECTORNAME   
        UPDATE #TEMPLISTTABLE SET CONNECTORNAME=@ICONNECTORNAME WHERE CID=@IT        
       END        
              
      END    
    IF @ORDERNAME = 'SERIALNUMBER'            
        AND @ORDERTYPE = '0'             
        BEGIN                
            IF ( @OutformatXML = 0 )             
BEGIN      
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)                   
          SELECT DISTINCT TOP 10            
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
       --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,  
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
    --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,   
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
                    FOR     XML AUTO ,            
                                ELEMENTS          
   RETURN                
   END              
        END                  
                                  
    IF @ORDERNAME = 'SERIALNUMBER'            
        AND @ORDERTYPE = '1'             
        BEGIN      
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)    
            IF ( @OutformatXML = 0 )             
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
      c.ASSOCIATIONTYPEID ,            
      C.SUPPORTDATE,            
      c.ISEPRS ,            
      c.REMOVEASSOCIATION ,            
      c.DELETEDM ,            
      C.CREATEDDATE AS REGISTRATIONDATE,       
  -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,   
   C.LASTPINGDATE  AS LASTPINGDATE,  
      c.HGMSPROVISIONINGSTATUS,          
      PRODUCT.ISDELETEALLOWED,          
      PRODUCT.ISTRANSFERALLOWED,  
   PRODUCT.ISRENAMEALLOWED,          
      PRODUCT.ISSECUREUPGRADE,          
      c.S1SVCSTATUS,          
      c.SENTINELONEEXPIRYDATE,          
      c.PRODUCTTYPE,          
      c.EPAID ,          
      c.SERVICELINE,          
      c.ISBILLABLE,          
      PRODUCT.ROLETYPE ,          
      c.SASELICENSECOUNT,          
      c.ISZEROTOUCHALLOWED,          
      PRODUCT.ORGNAME,      
   PRODUCT.ISADDKEYSETAPPLICABLE,          
   PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT  , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT,PRODUCTCHOICEID,  
 C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY  
                    FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber             
                    ORDER BY C.SERIALNUMBER ASC                                                             
                    RETURN                 
                END                
    ELSE             
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
      c.ISEPRS ,            
      C.CREATEDDATE AS REGISTRATIONDATE,      
 --  CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,     
   C.LASTPINGDATE AS LASTPINGDATE,  
      c.HGMSPROVISIONINGSTATUS,          
      PRODUCT.ISDELETEALLOWED,          
      PRODUCT.ISTRANSFERALLOWED,          
      PRODUCT.ISRENAMEALLOWED,          
      PRODUCT.ISSECUREUPGRADE,          
      C.SUPPORTDATE,          
      c.SENTINELONEEXPIRYDATE,          
      c.PRODUCTTYPE,          
      c.EPAID ,          
      c.SERVICELINE,          
      c.ISBILLABLE,          
      PRODUCT.ROLETYPE ,          
      c.SASELICENSECOUNT,          
      c.ISZEROTOUCHALLOWED,          
      PRODUCT.ORGNAME,       
   PRODUCT.ISADDKEYSETAPPLICABLE,          
   PRODUCT.MSSPMONTHLYOPTION,      
   C.ISNETWORKPRODUCT  , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID,  
  C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY  
                    FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber             
              ORDER BY C.SERIALNUMBER ASC            
                    FOR     XML AUTO ,            
                                ELEMENTS                                     
                    RETURN                
                END                                   
        END                                    
                      
    IF @ORDERNAME = 'NAME'            
        AND @ORDERTYPE = '0'             
        BEGIN           
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)    
            IF ( @OutformatXML = 0 )             
BEGIN                
            IF ( @CallFrom = 'MYGROUPS' )             
                        BEGIN            
                         SELECT DISTINCT            
           C.PRODUCTID ,            
                                  C.SERIALNUMBER ,            
                                    C.PRIMARYSERIALNUMBER ,            
                                    C.ASSOCIATIONNAME ,            
                                    C.[NAME] ,            
                                    C.CUSTOMERPRODUCTID ,            
                                    C.STATUS ,            
                                    REPLACE(ISNULL(C.REGISTRATIONCODE, ''), ' ', '-') 'REGISTRATIONCODE' ,            
                                    C.FIRMWAREVERSION ,            
                                     PRODUCT.PRODUCTLINE ,            
                                    C.PRODUCTFAMILY ,            
                                    C.ACTIVEPROMOTION ,            
          C.PROMOTIONID ,            
                                    C.NFR ,            
                                    PRODUCT.OWNEROFTHEPRODUCT ,            
                              PRODUCT.PRODUCTOWNER ,            
                 C.ISSUENAME ,            
                                    C.RESOLUTIONNAME ,            
                                    C.PRODUCTNAME ,            
          PGD.PRODUCTGROUPID ,            
         PG.PRODUCTGROUPNAME ,            
                                    C.DISPLAYKEYSET ,            
                                    C.ASSOCIATIONTYPE ,            
                                    C.GROUPHEADERTEXT ,            
                                    C.ASSOCIATIONTYPEID ,            
                                    C.ISEPRS ,            
         C.REMOVEASSOCIATION ,            
                                    C.DELETEDM ,            
                                    C.CREATEDDATE AS REGISTRATIONDATE,       
         --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,     
   C.LASTPINGDATE AS LASTPINGDATE,     
         C.HGMSPROVISIONINGSTATUS,          
         PRODUCT.ISDELETEALLOWED,          
         PRODUCT.ISTRANSFERALLOWED,          
         PRODUCT.ISRENAMEALLOWED,          
         PRODUCT.ISSECUREUPGRADE,          
         C.SUPPORTDATE ,          
         C.S1SVCSTATUS,          
         C.SENTINELONEEXPIRYDATE ,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE,C.ISBILLABLE,PRODUCT.ROLETYPE,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
   PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT   , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY,CU.MANAGEMENTOPTION           
                            FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber  
    Left join CUSTOMERPRODUCTS CU WITH (NOLOCK) ON CU.SERIALNUMBER = C.serialnumber  
                                    LEFT OUTER JOIN PRODUCTGROUPDETAIL PGD            
                WITH ( NOLOCK ) ON PGD.SERIALNUMBER = PRODUCT.SERIALNUMBER            
                                    LEFT OUTER JOIN PRODUCTGROUP PG WITH ( NOLOCK ) ON PG.PRODUCTGROUPID = PGD.PRODUCTGROUPID            
                  ORDER BY C.[NAME] DESC ,            
                                    C.PRIMARYSERIALNUMBER DESC                                                             
                            RETURN                 
 END                
                    ELSE             
              BEGIN                
                       --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                            SELECT DISTINCT            
                              C.PRODUCTID ,            
                                C.SERIALNUMBER ,            
                                    C.PRIMARYSERIALNUMBER ,            
                                    C.ASSOCIATIONNAME ,            
                                    C.[NAME] ,            
  C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
  REPLACE(ISNULL(C.REGISTRATIONCODE, ''), ' ',            
   '-') 'REGISTRATIONCODE' ,            
                                    C.FIRMWAREVERSION ,            
                                     PRODUCT.PRODUCTLINE ,            
     C.PRODUCTFAMILY ,            
                                    C.ACTIVEPROMOTION ,            
C.PROMOTIONID ,            
           C. NFR ,            
                            PRODUCT. OWNEROFTHEPRODUCT ,            
                               PRODUCT. PRODUCTOWNER ,            
                                     C.ISSUENAME ,            
      C.RESOLUTIONNAME ,            
          C.PRODUCTNAME ,            
        C. PRODUCTGROUPID ,            
     C.PRODUCTGROUPNAME ,            
                                     C.DISPLAYKEYSET ,            
          C.ASSOCIATIONTYPE ,         
                                    C. GROUPHEADERTEXT ,            
                                   C.ASSOCIATIONTYPEID ,            
    C.ISEPRS ,            
                                    C. REMOVEASSOCIATION ,            
                                     C.DELETEDM ,            
                                    C.CREATEDDATE AS REGISTRATIONDATE,      
         --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,    
   C.LASTPINGDATE AS LASTPINGDATE,  
          C.HGMSPROVISIONINGSTATUS,          
          C.MCAFEEORDER,          
          C.RELEASESTATUS,          
         PRODUCT.PARTYGROUPIDS,          
          C.PARTYGROUPNAME 'PARTYGROUPNAME',          
         PRODUCT.PARTYGROUPNAMES,          
          C.DEVICESTATUS,          
         PRODUCT.PRODUCTGROUPNAMES,          
         PRODUCT.PRODUCTGROUPIDS,          
          C.FWTAB ,          
          C.PTAB ,          
          C.LTAB ,          
          C.CBKUPTAB,          
      C.ASSOCTYPEINTNAME,          
         PRODUCT.ISDELETEALLOWED,          
         PRODUCT.ISTRANSFERALLOWED,          
         PRODUCT.ISRENAMEALLOWED,          
         PRODUCT.ISSECUREUPGRADE,          
          C.S1SVCSTATUS,          
          C.SENTINELONEEXPIRYDATE, C.PRODUCTTYPE, C.EPAID , C.SERVICELINE , C.ISBILLABLE,PRODUCT.ROLETYPE, C.SASELICENSECOUNT, C.ISZEROTOUCHALLOWED ,        
    PRODUCT.ORGNAME , PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT   , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY,CU.MANAGEMENTOPTION        
                            FROM     CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber  
    Left join CUSTOMERPRODUCTS CU WITH (NOLOCK) ON CU.SERIALNUMBER = C.serialnumber  
                            ORDER BY C.[NAME] DESC ,            
                                    C.PRIMARYSERIALNUMBER DESC           
                                      
       IF @IsMobile<>'APPS'                  
        SELECT * FROM @GROUPTABLE               
  RETURN            
    END             
                END                
            ELSE             
                BEGIN      
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                    SELECT DISTINCT            
                            C.PRODUCTID ,            
                            C.SERIALNUMBER ,            
                            C.[NAME] ,            
                            C.CUSTOMERPRODUCTID ,            
                            C.STATUS ,            
                            C.REGISTRATIONCODE ,            
                            C.FIRMWAREVERSION ,            
                             PRODUCT.PRODUCTLINE ,            
                            C.PRODUCTFAMILY ,            
                            C.ACTIVEPROMOTION ,            
            C.PROMOTIONID ,            
                            C.NFR ,            
                            PRODUCT.OWNEROFTHEPRODUCT ,            
                            PRODUCT.PRODUCTOWNER ,            
                            C.ISSUENAME ,            
                           C. RESOLUTIONNAME ,            
         C.PRODUCTNAME ,            
                            C.PRODUCTGROUPID ,            
                            C.PRODUCTGROUPNAME ,            
                       C.DISPLAYKEYSET ,            
                          C.  ASSOCIATIONTYPE ,            
                            C.GROUPHEADERTEXT ,            
                            C.ISEPRS ,            
                            C.CREATEDDATE AS REGISTRATIONDATE,        
       --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,      
    C.LASTPINGDATE AS LASTPINGDATE,  
       C.HGMSPROVISIONINGSTATUS,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.SUPPORTDATE,          
       C.SENTINELONEEXPIRYDATE,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,      
    PRODUCT. ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT    , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY,CU.MANAGEMENTOPTION        
                    FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber  
    Left join CUSTOMERPRODUCTS CU WITH (NOLOCK) ON CU.SERIALNUMBER = C.serialnumber  
                    ORDER BY C.[NAME] DESC            
                  FOR     XML AUTO ,            
  ELEMENTS                                     
                    RETURN                  
                END                                
        END                  
                                  
    IF @ORDERNAME = 'NAME'            
        AND @ORDERTYPE = '1'             
        BEGIN       
      
            IF ( @OutformatXML = 0 )             
             BEGIN              
                    IF ( @CallFrom = 'MYGROUPS' )             
                        BEGIN            
                                                  
                            SELECT DISTINCT            
       C.PRODUCTID ,            
       C.SERIALNUMBER ,            
       C.PRIMARYSERIALNUMBER ,            
       C.ASSOCIATIONNAME ,            
       C.[NAME] ,            
       C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
       REPLACE(ISNULL(C.REGISTRATIONCODE, ''), ' ',            
       '-') 'REGISTRATIONCODE' ,            
       C.FIRMWAREVERSION ,            
        PRODUCT.PRODUCTLINE ,            
       C.PRODUCTFAMILY ,            
       C.ACTIVEPROMOTION ,            
       C. PROMOTIONID ,            
       C.NFR ,            
       PRODUCT.OWNEROFTHEPRODUCT ,            
       PRODUCT. PRODUCTOWNER ,            
       C.ISSUENAME ,            
       C.RESOLUTIONNAME ,            
       C.PRODUCTNAME ,            
       PGD.PRODUCTGROUPID ,            
       PG.PRODUCTGROUPNAME ,            
       C.DISPLAYKEYSET ,            
       C. ASSOCIATIONTYPE ,          
       C.GROUPHEADERTEXT ,            
  C.ASSOCIATIONTYPEID ,            
       CONVERT(DATETIME,C. REGISTRATIONCODE) 'SUPPORTDATE' ,            
       C.ISEPRS ,            
       C.REMOVEASSOCIATION ,            
       C.DELETEDM ,            
       C.CREATEDDATE AS REGISTRATIONDATE,      
    --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,     
 C.LASTPINGDATE AS LASTPINGDATE,  
       C.HGMSPROVISIONINGSTATUS,          
       C.MCAFEEORDER,          
       C.RELEASESTATUS,          
       PRODUCT.PARTYGROUPIDS,          
       C.PARTYGROUPNAME 'PARTYGROUPNAME',          
       PRODUCT.PARTYGROUPNAMES,          
       C.DEVICESTATUS,          
       PRODUCT.PRODUCTGROUPNAMES,          
       PRODUCT.PRODUCTGROUPIDS,          
       C.FWTAB ,          
       C.PTAB ,          
       C.LTAB ,          
       C.CBKUPTAB,          
       C.ASSOCTYPEINTNAME,          
       PRODUCT. ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.S1SVCSTATUS,          
       C.SENTINELONEEXPIRYDATE,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
    PRODUCT.ORGNAME  , PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT    , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY        
                            FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
                                    LEFT OUTER JOIN PRODUCTGROUPDETAIL PGD            
                                    WITH ( NOLOCK ) ON PGD.SERIALNUMBER = PRODUCT.SERIALNUMBER            
                                    LEFT OUTER JOIN PRODUCTGROUP PG WITH ( NOLOCK ) ON PG.PRODUCTGROUPID = PGD.PRODUCTGROUPID            
   ORDER BY [NAME] ASC ,            
                              C.PRIMARYSERIALNUMBER DESC             
                                   
            SELECT * FROM @GROUPTABLE                                
                 RETURN                 
          END                
                    ELSE             
                        BEGIN                
      
           --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)  
      
      
                            SELECT DISTINCT            
       C.PRODUCTID ,            
       C.SERIALNUMBER ,            
       C.PRIMARYSERIALNUMBER ,            
       C.ASSOCIATIONNAME ,            
       C.[NAME] ,            
       C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
       REPLACE(ISNULL(C.REGISTRATIONCODE, ''), ' ',            
        '-') 'REGISTRATIONCODE' ,            
       C.FIRMWAREVERSION ,            
        PRODUCT.PRODUCTLINE ,            
       C.PRODUCTFAMILY ,            
       C.ACTIVEPROMOTION ,            
       C.PROMOTIONID ,            
       C.NFR ,            
       PRODUCT.OWNEROFTHEPRODUCT ,            
       PRODUCT.PRODUCTOWNER ,            
       C.ISSUENAME ,            
       C.RESOLUTIONNAME ,            
       C.PRODUCTNAME ,            
       C.PRODUCTGROUPID ,            
       C.PRODUCTGROUPNAME ,            
       C.DISPLAYKEYSET ,            
       C.ASSOCIATIONTYPE ,            
       C.GROUPHEADERTEXT ,            
       C.ASSOCIATIONTYPEID ,            
       CONVERT(DATETIME, C.REGISTRATIONCODE) 'SUPPORTDATE' ,            
       C.ISEPRS ,            
       C.REMOVEASSOCIATION,            
       C.DELETEDM ,            
       C.CREATEDDATE AS REGISTRATIONDATE,       
    --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,   
   C.LASTPINGDATE AS LASTPINGDATE,  
       C.HGMSPROVISIONINGSTATUS,          
       C.MCAFEEORDER,          
       C.RELEASESTATUS,          
      PRODUCT.PARTYGROUPIDS,          
       C.PARTYGROUPNAME 'PARTYGROUPNAME',          
 PRODUCT.PARTYGROUPNAMES,          
       C.DEVICESTATUS,          
       PRODUCT.PRODUCTGROUPNAMES,          
       PRODUCT.PRODUCTGROUPIDS,          
       C.FWTAB ,          
       C.PTAB ,          
       C.LTAB ,          
       C.CBKUPTAB,          
       C.ASSOCTYPEINTNAME,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE ,          
       C.S1SVCSTATUS,          
       C.SENTINELONEEXPIRYDATE ,C.PRODUCTTYPE ,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
    PRODUCT.ORGNAME , PRODUCT.ISADDKEYSETAPPLICABLE , PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT  , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT , PRODUCT.CONNECTORNAME   ,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY      
                           FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
                            ORDER BY C.[NAME] ASC ,            
                                    C.PRIMARYSERIALNUMBER DESC          
                         
        SELECT * FROM @GROUPTABLE               
        RETURN            
             END             
                END               
            ELSE             
                BEGIN         
         --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)  
                    SELECT DISTINCT            
      C.PRODUCTID ,            
      C.SERIALNUMBER ,            
      C.[NAME] ,            
      C.CUSTOMERPRODUCTID ,            
      C.STATUS ,            
      C.REGISTRATIONCODE ,            
      C.FIRMWAREVERSION ,            
       PRODUCT.PRODUCTLINE ,            
      C.PRODUCTFAMILY ,            
      C.ACTIVEPROMOTION ,            
      C.PROMOTIONID ,            
      C.NFR ,            
      PRODUCT.OWNEROFTHEPRODUCT ,            
      PRODUCT.PRODUCTOWNER ,            
      C.ISSUENAME ,            
      C.RESOLUTIONNAME ,            
      C.PRODUCTNAME ,            
      C.PRODUCTGROUPID ,           
      C.PRODUCTGROUPNAME ,            
      C.DISPLAYKEYSET ,            
      C.ASSOCIATIONTYPE ,            
      C.GROUPHEADERTEXT ,            
      C.ISEPRS ,            
      C.CREATEDDATE AS REGISTRATIONDATE,      
  -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,   
  C.LASTPINGDATE AS LASTPINGDATE,  
      C.HGMSPROVISIONINGSTATUS,                 
      PRODUCT.ISDELETEALLOWED,     
      PRODUCT.ISTRANSFERALLOWED,          
      PRODUCT.ISRENAMEALLOWED,          
      PRODUCT.ISSECUREUPGRADE,          
      C.SENTINELONEEXPIRYDATE  ,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
   PRODUCT.ORGNAME    , PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT, PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT  , PRODUCT.CONNECTORNAME  ,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY      
                  FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
                    ORDER BY C.[NAME] ASC            
                    FOR     XML AUTO ,            
                                ELEMENTS                                     
                    RETURN                
                END                    
        END                
                                  
   IF @ORDERNAME = 'PRODUCTLINE'            
        AND @ORDERTYPE = '0'             
        BEGIN   
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)    
            IF ( @OutformatXML = 0 )             
                BEGIN                                     
                    SELECT DISTINCT            
      C.PRODUCTID ,            
      C.SERIALNUMBER ,            
      C.PRIMARYSERIALNUMBER ,            
      C.ASSOCIATIONNAME ,            
      C.[NAME] ,            
      C.CUSTOMERPRODUCTID ,            
      C.STATUS ,            
      C.REGISTRATIONCODE ,            
      C.FIRMWAREVERSION ,            
       PRODUCT.PRODUCTLINE ,            
      C.PRODUCTFAMILY ,            
      C.ACTIVEPROMOTION ,            
      C.PROMOTIONID ,            
      C.NFR ,            
      PRODUCT.OWNEROFTHEPRODUCT ,            
      PRODUCT.PRODUCTOWNER ,            
      C.ISSUENAME ,            
      C.RESOLUTIONNAME ,            
      C.PRODUCTNAME ,            
      C.PRODUCTGROUPID ,            
      C.PRODUCTGROUPNAME ,            
      C.DISPLAYKEYSET ,            
      C.ASSOCIATIONTYPE ,            
      C.GROUPHEADERTEXT ,            
      C.ASSOCIATIONTYPEID ,            
      C.ISEPRS ,            
      C.REMOVEASSOCIATION ,            
      C.DELETEDM ,            
      C.REGCODE ,            
      C.CREATEDDATE AS REGISTRATIONDATE,      
  -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,     
     C.LASTPINGDATE AS LASTPINGDATE,  
      C.HGMSPROVISIONINGSTATUS,          
      C.MCAFEEORDER,          
      PRODUCT.ISDELETEALLOWED,          
      PRODUCT.ISTRANSFERALLOWED,          
      PRODUCT.ISRENAMEALLOWED,          
      PRODUCT.ISSECUREUPGRADE,          
      C.S1SVCSTATUS,          
      C.SENTINELONEEXPIRYDATE,          
      C.PRODUCTTYPE,          
      C.EPAID ,          
      C.SERVICELINE ,C.ISBILLABLE,          
      PRODUCT.ROLETYPE,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION , C.ISNETWORKPRODUCT   , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT      ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY     
                     FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber            
                    ORDER BY  PRODUCT.PRODUCTLINE DESC                                                            
                    RETURN                  
              END                
      ELSE             
                BEGIN    
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                    SELECT DISTINCT            
     C.PRODUCTID ,            
     C.SERIALNUMBER ,            
     C.[NAME] ,            
     C.CUSTOMERPRODUCTID ,            
     C.STATUS ,            
     C.REGISTRATIONCODE ,            
     C.FIRMWAREVERSION ,            
      PRODUCT.PRODUCTLINE ,            
     C.PRODUCTFAMILY ,            
     C.ACTIVEPROMOTION ,            
     C.PROMOTIONID ,            
  C.NFR ,            
     PRODUCT.OWNEROFTHEPRODUCT ,            
     PRODUCT.PRODUCTOWNER ,            
     C.ISSUENAME ,         
     C.RESOLUTIONNAME ,            
     C.PRODUCTNAME ,            
     C.PRODUCTGROUPID ,            
     C.PRODUCTGROUPNAME ,            
     C.DISPLAYKEYSET ,            
     C.ASSOCIATIONTYPE ,            
     C.GROUPHEADERTEXT ,            
     C.ISEPRS ,            
     C.REGCODE ,            
     C.CREATEDDATE AS REGISTRATIONDATE,       
  --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,    
  C.LASTPINGDATE AS LASTPINGDATE,  
     C.HGMSPROVISIONINGSTATUS,          
     PRODUCT.ISDELETEALLOWED,          
     PRODUCT.ISTRANSFERALLOWED,          
     PRODUCT.ISRENAMEALLOWED,          
     PRODUCT.ISSECUREUPGRADE,          
     C.SENTINELONEEXPIRYDATE,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
  PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT         
  , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID , C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY   
                      FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
                    ORDER BY  PRODUCT.PRODUCTLINE DESC            
                    FOR     XML AUTO ,            
                                ELEMENTS               
   RETURN                
                END                                  
        END                                  
    IF @ORDERNAME = 'PRODUCTLINE'            
        AND @ORDERTYPE = '1'             
        BEGIN                
            IF ( @OutformatXML = 0 )             
                BEGIN                                      
                    SELECT DISTINCT            
    C. PRODUCTID ,            
    C.SERIALNUMBER ,            
    C.PRIMARYSERIALNUMBER ,            
    C.ASSOCIATIONNAME ,            
    C.[NAME] ,            
    C.CUSTOMERPRODUCTID ,            
    C.STATUS ,            
    C.REGISTRATIONCODE ,            
    C.FIRMWAREVERSION ,            
     PRODUCT.PRODUCTLINE ,            
    C.PRODUCTFAMILY ,            
    C.ACTIVEPROMOTION ,            
    C.PROMOTIONID ,        
    C.NFR ,            
    PRODUCT.OWNEROFTHEPRODUCT ,            
    PRODUCT.PRODUCTOWNER ,            
    C.ISSUENAME ,            
    C.RESOLUTIONNAME ,            
    C.PRODUCTNAME ,            
    C.PRODUCTGROUPID ,            
    C.PRODUCTGROUPNAME ,            
    C.DISPLAYKEYSET ,            
    C.ASSOCIATIONTYPE ,            
    C.GROUPHEADERTEXT ,            
    C.ASSOCIATIONTYPEID ,            
    C.ISEPRS ,            
    C.REMOVEASSOCIATION ,            
    C.DELETEDM ,            
    C.CREATEDDATE AS REGISTRATIONDATE,      
 --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,  
   C.LASTPINGDATE AS LASTPINGDATE,  
    C.HGMSPROVISIONINGSTATUS,          
    C.MCAFEEORDER,          
    PRODUCT.ISDELETEALLOWED,          
    PRODUCT.ISTRANSFERALLOWED,          
    PRODUCT.ISRENAMEALLOWED,          
    PRODUCT.ISSECUREUPGRADE,          
    C.S1SVCSTATUS,          
    C.SENTINELONEEXPIRYDATE,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
 PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION, C.ISNETWORKPRODUCT        
 , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT  ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY      
                      FROM CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
                    ORDER BY  PRODUCT.PRODUCTLINE ASC                                   
                    RETURN                  
                END               
            ELSE             
                BEGIN       
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                    SELECT DISTINCT            
      C.PRODUCTID ,            
      C.SERIALNUMBER ,            
      C.[NAME] ,            
      C.CUSTOMERPRODUCTID ,            
C.STATUS ,            
      C.REGISTRATIONCODE ,            
      C.FIRMWAREVERSION ,            
       PRODUCT.PRODUCTLINE ,            
      C.PRODUCTFAMILY ,            
      C.ACTIVEPROMOTION ,            
      C.PROMOTIONID ,            
    C.NFR ,            
      PRODUCT. OWNEROFTHEPRODUCT ,            
      PRODUCT. PRODUCTOWNER ,            
      C.ISSUENAME ,            
      C.RESOLUTIONNAME ,            
      C.PRODUCTNAME ,            
      C.PRODUCTGROUPID ,            
      C.PRODUCTGROUPNAME ,            
      C.DISPLAYKEYSET ,            
      C.ASSOCIATIONTYPE ,            
      C.GROUPHEADERTEXT ,            
      C.ISEPRS ,            
      C.CREATEDDATE AS REGISTRATIONDATE,      
   --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,       
     C.LASTPINGDATE AS LASTPINGDATE,  
      C.HGMSPROVISIONINGSTATUS,          
      C.SENTINELONEEXPIRYDATE,C.PRODUCTTYPE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE,PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,       
   PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION ,C.ISNETWORKPRODUCT      
   , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT      ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY   
                     FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber           
          ORDER BY  PRODUCT.PRODUCTLINE ASC            
     FOR     XML AUTO ,            
                         ELEMENTS                        
     RETURN                
                END            
        END                
            
    IF @ORDERNAME = 'REGISTEREDDATE'            
        AND @ORDERTYPE = '0'             
        BEGIN          
          
   IF ISNULL(@ISMSSPUSER, '') <> ''  AND EXISTS (SELECT ORGANIZATIONID FROM ORGANIZATION WITH (NOLOCK)      
  WHERE ORGANIZATIONID = @ORGID AND MASTERMSSP = 1)      
 BEGIN -- Master MSSP user, show all products from mssp orgs which are marked as MSSPMONHTLY = YES      
      
  CREATE TABLE #tMSSPIDS         
  (        
  MSSPID INT,        
  MSSPNAME NVARCHAR(50),        
  MASTERMSSP BIT DEFAULT(0)        
  )          
        
  CREATE TABLE #MSSPTENANTS        
  (ID INT IDENTITY        
  ,TENANTNAME VARCHAR(255)        
  ,TENANTID INT        
  ,MSSPNAME VARCHAR(50)        
  ,MSSPID INT        
  )        
          
  CREATE TABLE #MSSPPRODUCTSERVICES        
  (          
  ID BIGINT IDENTITY(1,1)          
  ,TENANTID INT          
  ,SERIALNUMBER VARCHAR(50)       
  ,PRODUCTID INT           
  )        
        
  CREATE TABLE #UNLISTEDPRODUCTS        
  (TENANTID INT        
  ,PRODUCTID INT        
  ,SERIALNUMBER VARCHAR(50)        
  )        
      
   INSERT INTO #tMSSPIDS        
   SELECT MM.MASTERMSSPID,MM.MSSPNAME, MM.MSSPORGANIZATIONID FROM MASTERMSSP MM WITH (NOLOCK)        
      WHERE  MM.MASTERORGANIZATIONID = @ORGID AND ISNULL(MM.MSSPORGANIZATIONID,0) <> 0;       
      
    INSERT INTO #MSSPTENANTS(TENANTID, TENANTNAME, MSSPID, MSSPNAME)            
   SELECT P.PRODUCTGROUPID, P.PRODUCTGROUPNAME, M.MSSPID, M.MSSPNAME             
   FROM PRODUCTGROUP P WITH (NOLOCK), #tMSSPIDS M WITH ( NOLOCK ), DBO.FNMSSPTENANTSLIST (@USERNAME)MP      
   WHERE P.MASTERMSSPID = M.MSSPID AND MP.PRODUCTGROUPID = P.PRODUCTGROUPID          
       
   INSERT INTO #MSSPPRODUCTSERVICES ( TENANTID, SERIALNUMBER, PRODUCTID)        
   SELECT PD.PRODUCTGROUPID,  PD.SERIALNUMBER, M.PRODUCTID       
   FROM #MSSPTENANTS MT WITH (NOLOCK), PRODUCTGROUPDETAIL PD WITH (NOLOCK),       
   MSSPPRODUCTSERVICESSUMMARY M WITH (NOLOCK),       
   CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE MT.TENANTID = PD.PRODUCTGROUPID AND      
   PD.SERIALNUMBER = M.SERIALNUMBER AND PD.SERIALNUMBER = CP.SERIALNUMBER AND       
   CP.MSSPMONTHLY = 'YES' AND M.STATUS = 'ACTIVE'       
   GROUP BY PD.PRODUCTGROUPID, PD.SERIALNUMBER, M.PRODUCTID;      
       
         
   INSERT INTO #UNLISTEDPRODUCTS         
   SELECT PD.PRODUCTGROUPID, CP.PRODUCTID, PD.SERIALNUMBER         
   FROM #MSSPTENANTS MT, PRODUCTGROUPDETAIL PD WITH (NOLOCK), CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE       
   MT.TENANTID = PD.PRODUCTGROUPID AND PD.SERIALNUMBER = CP.SERIALNUMBER AND CP.MSSPMONTHLY = 'YES'       
   AND PD.SERIALNUMBER NOT IN (SELECT SERIALNUMBER  FROM #MSSPPRODUCTSERVICES (NOLOCK))      
   --EXCEPT        
   --SELECT TENANTID, PRODUCTID, SERIALNUMBER  FROM #MSSPPRODUCTSERVICES      
       
    --SELECT * from #UNLISTEDPRODUCTS      
        
   INSERT INTO #MSSPPRODUCTSERVICES ( TENANTID, SERIALNUMBER, PRODUCTID)        
   SELECT TENANTID, SERIALNUMBER, MMPS.PRODUCTID      
   FROM #UNLISTEDPRODUCTS U WITH (NOLOCK), MASTERMSSPPRODUCTSERVICES MMPS WITH (NOLOCK)       
   WHERE U.PRODUCTID = MMPS.PRODUCTID          
   GROUP BY TENANTID, SERIALNUMBER, MMPS.PRODUCTID;      
      
     --SELECT * from #MSSPPRODUCTSERVICES      
      
     INSERT  INTO #TEMPLISTTABLE            
       ( PRODUCTID ,            
         SERIALNUMBER ,                                 
         PRODUCTFAMILY,          
          PRODUCTLINE,          
          ACTIVEPROMOTION           
                
       )                                 
    SELECT CPS.PRODUCTID, CPS.SERIALNUMBER, PRODUCTFAMILY,      
    PRODUCTLINE, ACTIVEPROMOTION from #MSSPPRODUCTSERVICES M WITH (NOLOCK),      
    CUSTOMERPRODUCTSSUMMARY CPS WITH (NOLOCK)      
    WHERE M.SERIALNUMBER = CPS.SERIALNUMBER      
    AND CPS.SERIALNUMBER NOT IN (SELECT SERIALNUMBER FROM #TEMPLISTTABLE)        
      
    UPDATE #TEMPLISTTABLE              
 SET MSSPMONTHLYOPTION = CASE WHEN #TEMPLISTTABLE.PRODUCTID IN (SELECT MS.PRODUCTID      
     FROM MASTERMSSPPRODUCTSERVICES MS WITH (NOLOCK), CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
      CP.SERIALNUMBER = #TEMPLISTTABLE.SERIALNUMBER AND MS.STATUS='ACTIVE' AND CP.MSSPMONTHLY = 'YES')      
  THEN 'DISABLE' -- MSSP Monthly is enabled, hence show disable option      
      
  WHEN #TEMPLISTTABLE.PRODUCTID IN (SELECT MS.PRODUCTID      
     FROM MASTERMSSPPRODUCTSERVICES MS WITH (NOLOCK), CUSTOMERPRODUCTS CP WITH (NOLOCK) WHERE      
     CP.SERIALNUMBER = #TEMPLISTTABLE.SERIALNUMBER AND MS.STATUS='ACTIVE' AND ISNULL(CP.MSSPMONTHLY,'NO') = 'NO')      
  THEN 'ENABLE' END -- MSSP Monthly is disabled, hence show enable option      
      
  IF(@ROLETYPELOGIC='YES')        
  BEGIN         
        
        
UPDATE #TEMPLISTTABLE        
    SET ROLETYPE =        
  CASE        
  (SELECT TOP 1 ISSUPERADMIN FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID        
  AND PARTYID IN (SELECT PARTYID FROM PARTY(NOLOCK) WHERE CONTACTID = @CONTACTID)) WHEN 'YES' THEN 'SUPERADMIN'        
  ELSE         
  ISNULL((SELECT TOP 1 ACCESSTYPEPRODMGMTROLETYPE         
  FROM TENANTGROUPPERMISSIONSUMMARY WITH (NOLOCK) WHERE USERNAME=@USERNAME AND PRODUCTGROUPID=P.PRODUCTGROUPID AND PARTYID IN (SELECT PARTYID FROM PARTY(NOLOCK) WHERE CONTACTID = @CONTACTID))         
  ,dbo.FNGETTENANTGROUPPERMISSION(@USERNAME,P.PRODUCTGROUPID,@APPLICATIONFUNCTIONALITY,'MSSPUSER', DEFAULT))        
  END        
  FROM #TEMPLISTTABLE P  WITH (NOLOCK) WHERE MSSPMONTHLYOPTION='DISABLE'      
        
END         
IF(@ROLETYPELOGIC='NO') OR          
 EXISTS(SELECT T.PRODUCTGROUPID FROM #TEMPLISTTABLE T   WITH (NOLOCK)        
   INNER JOIN  TENANTACTIVITYSTAGING CP WITH (NOLOCK)          
   ON T.PRODUCTGROUPID=CP.PRODUCTGROUPID        
   AND PROCESSED='NO')         
BEGIN         
 UPDATE #TEMPLISTTABLE          
   SET ROLETYPE = DBO.FNGETTENANTGROUPPERMISSION(@USERNAME,T.PRODUCTGROUPID,'ACCESSTYPEPRODMGMT','MSSPUSER', DEFAULT)          
   FROM #TEMPLISTTABLE T        
END        
      
IF EXISTS (SELECT APPLICATIONPARTYROLEID FROM APPLICATIONPARTYROLE NOLOCK WHERE PARTYID=(SELECT TOP 1 PARTYID FROM VCUSTOMER(NOLOCK) WHERE USERNAME=@USERNAME) AND           
  APPLICATIONROLEID IN(SELECT APPLICATIONROLEID FROM APPLICATIONROLE NOLOCK WHERE ROLENAME='WORKSPACEBETA' AND APPLICATIONNAME='MSW')) OR          
  EXISTS(SELECT * FROM APPLICATIONCONFIGVALUE NOLOCK WHERE APPLICATIONCONFIGNAME='ISWORKSPACEENABLED' AND APPLICATIONCONFIGVALUE='FORCED')           
  BEGIN          
   UPDATE #TEMPLISTTABLE            
   SET ISTRANSFERALLOWED =CASE WHEN PRODUCTID IN (  400  ) THEN 'NO' WHEN ACTIVEPROMOTION =1 AND @ROLLUP = 0 THEN 'NO'           
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END          
          
    UPDATE #TEMPLISTTABLE           
  SET ISTRANSFERALLOWED = CASE WHEN UPPER(ROLETYPE) IN ('READONLY','OPERATOR') THEN 'NO' ELSE ISTRANSFERALLOWED END        
   FROM  #TEMPLISTTABLE TMP           
  END          
  ELSE          
  BEGIN          
  UPDATE #TEMPLISTTABLE            
   SET ISTRANSFERALLOWED =CASE WHEN OWNEROFTHEPRODUCT!=1 THEN 'NO' WHEN PRODUCTID IN ( 401 ) THEN 'NO' WHEN ACTIVEPROMOTION =1 AND @ROLLUP = 0 THEN 'NO'            
   WHEN  PRODUCTLINE='STORAGE MODULE' OR PRODUCTLINE='SATA MODULE' OR PRODUCTLINE='M2 STORAGE MODULE' THEN 'NO' WHEN S1SVCSTATUS = 'PENDING' THEN 'NO' ELSE 'YES' END           
  END        
      
 --UPDATE #TEMPLISTTABLE              
 --SET MSSPMONTHLYOPTION = CASE WHEN ISNULL(PG.MASTERMSSPID,0)=0 THEN ''       
 --WHEN ISNULL(PG.MASTERMSSPID,0)>0 AND PG.ISMAPPEDMSSPID=1 THEN '' ELSE MSSPMONTHLYOPTION END      
 --FROM #TEMPLISTTABLE T,  DBO.FNNONMSSPTENANTSLIST(@USERNAME) PG       
 --WHERE T.PRODUCTGROUPID=PG.PRODUCTGROUPID      
      
   DROP TABLE #MSSPTENANTS      
   DROP TABLE #tMSSPIDS      
   DROP TABLE #UNLISTEDPRODUCTS      
   DROP TABLE #MSSPPRODUCTSERVICES      
                
 END      
      
 UPDATE  #TEMPLISTTABLE            
    SET     OWNEROFTHEPRODUCT = 1            
    WHERE   SERIALNUMBER IN ( SELECT SERIALNUMBER            
                              FROM      CUSTOMERPRODUCTSSUMMARY WITH ( NOLOCK )            
                              WHERE     USERNAME = @USERNAME )         
      
      
IF @ORGBASEDASSETOWNSERSHIPENABLED = 'YES' AND @ISORGBASEDACCOUNT = 'YES'      
BEGIN      
      
 UPDATE  #TEMPLISTTABLE            
    SET     OWNEROFTHEPRODUCT = 1       
 WHERE OWNEROFTHEPRODUCT = 0  AND SERIALNUMBER IN (SELECT SERIALNUMBER            
                              FROM      CUSTOMERPRODUCTS WITH ( NOLOCK )            
                              WHERE  USERNAME IN (SELECT USERNAME FROM vCUSTOMER WHERE ORGANIZATIONID = @ORGID))      
                
      
END      
                                          
    UPDATE  #TEMPLISTTABLE            
    SET     PRODUCTOWNER = @USERNAME                    
                          
    UPDATE  #TEMPLISTTABLE              
    SET     PRODUCTOWNER = CP.USERNAME ,      
 PRODUCTGROUPID =   CP.PRODUCTGROUPID ,            
    PRODUCTGROUPNAME =  CP.PRODUCTGROUPNAME       
    FROM    #TEMPLISTTABLE T ,              
            CUSTOMERPRODUCTSSUMMARY CP WITH ( NOLOCK )              
    WHERE   T.SERIALNUMBER = CP.SERIALNUMBER              
            AND T.OWNEROFTHEPRODUCT = 0       
                     
                          
    IF ( @ORDERNAME IS NULL )            
        OR ( @ORDERNAME = '' )             
        SELECT  @ORDERNAME = 'NAME'                               
    IF ( @ORDERTYPE IS NULL )            
        OR ( @ORDERTYPE = '' )             
        SELECT  @ORDERTYPE = 0                    
          
                  
    IF @APPNAME IN ( 'MSW', 'CHANNEL' )             
    BEGIN            
  -- Dont show Cloud tenant 2.0(NFR = 10) and CSCMA 1.9(NFR = 11) tenant serial# My products only in MSW          
  DELETE  #TEMPLISTTABLE FROM #TEMPLISTTABLE T            
  WHERE   T.PRODUCTID = 400            
  AND T.SERIALNUMBER in (SELECT SERIALNUMBER FROM PRODUCTSERIALNUMBERS PSN (nolock) WHERE PSN.SERIALNUMBER = T.SERIALNUMBER AND PSN.PRODUCTID = 400 AND NFR IN (10, 11))            
            
          
  --If AppName = 'MSW', then only return those srl nos where OEMCode = @OEMCODE              
  DELETE  FROM #TEMPLISTTABLE            
    WHERE   PRODUCTID NOT IN ( SELECT   PRODUCTID            
             FROM     PRODUCTS WITH ( NOLOCK )            
  WHERE    OEMCODE = @OEMCODE )              
    END                  
                  
          
                             
                    
    IF ISNULL(@OEMCODE, '') = 'HGMS'             
        BEGIN            
            UPDATE  #TEMPLISTTABLE            
            SET     PRODUCTFAMILY = NULL            
            
            UPDATE  #TEMPLISTTABLE            
            SET     PRODUCTFAMILY = 'Click here to Login'            
            FROM    #TEMPLISTTABLE T ,            
                    HOSTEDGMSDETAILS H ( NOLOCK )            
            WHERE   T.SERIALNUMBER = H.SERIALNUMBER         
AND H.STATUS = 'SUCCESS'            
        END           
           
IF @ORGBASEDASSETOWNSERSHIPENABLED = 'YES' AND @ISORGBASEDACCOUNT = 'YES'      
BEGIN      
-- Restrict Product Operations such as Rename, Transfer and Delete when user has gained Access through Affiliation Tenant scope with Read-only Access (MSW-25825)      
      
 UPDATE  #TEMPLISTTABLE            
    SET     ISRENAMEALLOWED = 'NO',      
 ISDELETEALLOWED = 'NO',      
 ISTRANSFERALLOWED = 'NO'      
 WHERE OWNEROFTHEPRODUCT = 0  AND PRODUCTGROUPID IN       
  (SELECT PRODUCTGROUPID FROM PARTYPRODUCTGROUP WITH (NOLOCK)      
  WHERE ISNULL(COMANAGEORGTRACKERID,0) > 0 AND PERMISSIONTYPEID IN (SELECT PERMISSIONTYPEID FROM PERMISSIONTYPE WITH (NOLOCK) WHERE      
  INTERNALDESCRIPTION = 'READONLY'))      
                
END      
            
 if @SOURCE ='RESTAPI' AND @ISLARGEUSER = 'NO'          
  begin          
   DECLARE @TPARTYPRODUCTGRPDETAIL TABLE  
   (  
   CONTACTID INT,  
   SERIALNUMBER VARCHAR(30),  
   PARTYGROUPID INT,  
   PARTYGROUPNAME NVARCHAR(255)  
   )      
  INSERT INTO @TPARTYPRODUCTGRPDETAIL SELECT CONTACTID,SERIALNUMBER,PARTYGROUPID,PARTYGROUPNAME FROM VWPARTYPRODUCTGROUPDETAIL WITH (NOLOCK) WHERE CONTACTID=@CONTACTID     
  UPDATE  #TEMPLISTTABLE            
    SET     PARTYGROUPIDS = stuff((select  distinct ',' + convert(varchar,vw.PARTYGROUPID) from @TPARTYPRODUCTGRPDETAIL vw          
   where vw.SERIALNUMBER = TMP.SERIALNUMBER for xml path('')),1,1,'') + ','           
    FROM    #TEMPLISTTABLE TMP            
            
          
    UPDATE  #TEMPLISTTABLE            
    SET     PARTYGROUPNAMES = stuff((select distinct ',' + vw.PARTYGROUPNAME from @TPARTYPRODUCTGRPDETAIL vw        
    where vw.SERIALNUMBER = TMP.SERIALNUMBER for xml path('')),1,1,'') + ','             
    FROM    #TEMPLISTTABLE TMP            
           
 --   UPDATE  #TEMPLISTTABLE            
 --   SET     PRODUCTGROUPIDS = stuff((select  distinct ',' + convert(varchar,vw.PRODUCTGROUPID) from VWPARTYPRODUCTGROUPDETAIL vw    (NOLOCK)          
 --where vw.SERIALNUMBER = TMP.SERIALNUMBER and VW.CONTACTID = @CONTACTID  for xml path('')),1,1,'') + ','           
 --   FROM    #TEMPLISTTABLE TMP            
            
        
  end        
          
    --IF @SOURCE ='RESTAPI' AND @ISLARGEUSER = 'YES'        
    --BEGIN        
        UPDATE #TEMPLISTTABLE SET PRODUCTGROUPNAMES = ISNULL(CP.PRODUCTGROUPNAME,T.PRODUCTGROUPNAME)        
  ,PRODUCTGROUPIDS= ISNULL(CP.PRODUCTGROUPID, T.PRODUCTGROUPID)        
  FROM #TEMPLISTTABLE T WITH (NOLOCK)           
  inner join CUSTOMERPRODUCTSSUMMARY cp with (nolock)        
  on cp.serialnumber=t.serialnumber      
        
  --select * from #TEMPLISTTABLE      
               
   UPDATE  #TEMPLISTTABLE            
  SET  ISLICENSEEXPIRED = 1 , LICENSEEXPIRYCNT=1            
  WHERE   LICENSEEXPIRYCNT > 0          
  
  -- optional filter: only keep rows with matching isDownloadAvailable if provided
  IF @ISDOWNLOADAVAILABLE IS NOT NULL
  BEGIN
    DELETE FROM #TEMPLISTTABLE WHERE ISNULL(ISDOWNLOADAVAILABLE,-1) <> @ISDOWNLOADAVAILABLE
  END            
          
  UPDATE  #TEMPLISTTABLE            
  SET  ISSOONEXPIRING = 1 , SOONEXPIRINGCNT = 1            
  WHERE   SOONEXPIRINGCNT > 0          
          
  UPDATE  #TEMPLISTTABLE            
  SET   ACTIVELICENSECNT = 1            
  WHERE   ACTIVELICENSECNT > 0              
          
            IF ( @OutformatXML = 0 )             
                BEGIN             
              
              
              --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)  
               
            IF @PRODUCTLIST = 'LIMIT'             
                        BEGIN                                
                            SELECT DISTINCT TOP 10            
       C.PRODUCTID ,            
       C.SERIALNUMBER ,            
       C.[NAME] ,            
       C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
       C.REGISTRATIONCODE ,            
       C.FIRMWAREVERSION ,            
        PRODUCT.PRODUCTLINE ,            
       C.PRODUCTFAMILY ,            
       C.ACTIVEPROMOTION ,            
       C.PROMOTIONID ,            
       C.NFR ,            
       PRODUCT.OWNEROFTHEPRODUCT ,            
       PRODUCT.PRODUCTOWNER ,            
       C.ISSUENAME ,            
       C.RESOLUTIONNAME ,            
       C.PRODUCTNAME ,            
       C.PRODUCTGROUPID ,            
       C.PRODUCTGROUPNAME ,            
       PRODUCT.PARTYGROUPNAMES,          
       C.RELEASESTATUS,          
       C.DISPLAYKEYSET ,            
       C.ASSOCIATIONTYPE ,            
       C.GROUPHEADERTEXT ,            
       C.ASSOCIATIONTYPEID ,            
       C.ISEPRS ,            
       C.CREATEDDATE AS REGISTRATIONDATE ,      
    --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,    
 C.LASTPINGDATE AS LASTPINGDATE,  
       C.REMOVEASSOCIATION ,            
 C.DELETEDM ,            
       C.REGCODE ,            
       C.CREATEDDATE AS REGISTRATIONDATE,            
       C.HGMSPROVISIONINGSTATUS,          
     C.MCAFEEORDER,          
       C.DEVICESTATUS,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.PTAB,          
       C.LTAB,          
       C.CBKUPTAB,          
       C.FWTAB,          
       C.S1SVCSTATUS,          
       C.SENTINELONEEXPIRYDATE,          
       C.PRODUCTTYPE,          
       PRODUCT.LICENSEEXPIRYCNT,          
       PRODUCT.SOONEXPIRINGCNT,          
       PRODUCT.ACTIVELICENSECNT,          
       PRODUCT.ISLICENSEEXPIRED,          
  PRODUCT.ISSOONEXPIRING,          
       PRODUCT.MINLICENSEEXPIRYDATE,          
       PRODUCT.SOONEXPIRYDATE,          
       PRODUCT.CCNODECOUNT,          
       PRODUCT.HESNODECOUNT,          
       PRODUCT.CASNODECOUNT,          
     PRODUCT.GMSNODECOUNT,C.EPAID ,C.SERVICELINE,C.ISBILLABLE ,          
      -- C.ISDOWNLOADAVAILABLE,       
       C.UPDATESAVAILABLE 'ISDOWNLOADAVAILABLE',          
       C.ISZTSUPPORTED ,          
       C.SUPPORTEXPIRYDATE,          
       C.NONSUPPORTEXPIRYDATE,PRODUCT.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE, PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT      
    , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY, CU.MANAGEMENTOPTION       
                            FROM    CUSTOMERPRODUCTSSUMMARY C with (nolock)          
       inner join   #TEMPLISTTABLE   AS PRODUCT   on   C.serialnumber=PRODUCT.serialnumber  
    Left join CUSTOMERPRODUCTS CU WITH (NOLOCK) ON CU.SERIALNUMBER = C.serialnumber  
                         ORDER BY C.CREATEDDATE DESC                                                            
                            RETURN               
                        END             
                    ELSE             
                        BEGIN      
            
       --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)  
                 
          
                       SELECT DISTINCT              
     t.CID,             
     C.PRODUCTID ,              
     C.SERIALNUMBER ,              
     C.[NAME] ,              
     C.CUSTOMERPRODUCTID ,              
     C.STATUS ,              
     C.REGISTRATIONCODE ,              
     C.FIRMWAREVERSION ,              
      t.PRODUCTLINE ,                
     C.PRODUCTFAMILY ,              
     C.ACTIVEPROMOTION ,              
     C.PROMOTIONID ,              
     C.NFR ,              
    t.OWNEROFTHEPRODUCT ,              
     t.PRODUCTOWNER ,              
     C.ISSUENAME ,              
     C.RESOLUTIONNAME ,              
     C.PRODUCTNAME ,              
     C.PRODUCTGROUPID ,          
     C.PRODUCTGROUPNAME ,            
     t.PARTYGROUPNAMES,            
     C.RELEASESTATUS,            
     C.DISPLAYKEYSET ,              
     C.ASSOCIATIONTYPE ,              
     C.GROUPHEADERTEXT ,              
     C.ASSOCIATIONTYPEID ,              
     C.ISEPRS ,              
     C.CREATEDDATE AS REGISTRATIONDATE ,       
     --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,  
  C.LASTPINGDATE AS LASTPINGDATE,  
     C.REMOVEASSOCIATION ,              
     C.DELETEDM ,              
     C.REGCODE ,              
     t.NEEDEDFIRMWAREVERSION ,              
     t.FIRMWARESTATUS ,              
     t.FIRMWARETEXT ,              
     C.SRLNOSTATUS ,              
     C.RELEASENOTES ,              
     C.CREATEDDATE AS REGISTRATIONDATE,              
     C.HGMSPROVISIONINGSTATUS,            
     C.MCAFEEORDER,            
     C.DEVICESTATUS,            
     t.ISDELETEALLOWED,            
     t.ISTRANSFERALLOWED,            
     t.ISRENAMEALLOWED,            
     t.ISSECUREUPGRADE,            
     C.SUPPORTDATE,            
     t.PRODUCTGROUPNAMES,            
     C.PTAB,            
     C.LTAB,            
     C.CBKUPTAB,            
     C.FWTAB,            
     C.S1SVCSTATUS,            
     C.SENTINELONEEXPIRYDATE,            
     C.PRODUCTTYPE,            
     t.LICENSEEXPIRYCNT,            
     t.SOONEXPIRINGCNT,            
     t.ACTIVELICENSECNT,            
     t.ISLICENSEEXPIRED,            
     t.ISSOONEXPIRING,            
     t.MINLICENSEEXPIRYDATE,            
     t.SOONEXPIRYDATE,            
     t.CCNODECOUNT,            
     t.HESNODECOUNT,            
    t.CASNODECOUNT,            
     t.GMSNODECOUNT,          
     C.EPAID ,          
     C.SERVICELINE,          
     C.ISBILLABLE ,            
    --C.ISDOWNLOADAVAILABLE,       
                                 C.UPDATESAVAILABLE 'ISDOWNLOADAVAILABLE',            
     C.ISZTSUPPORTED,            
     C.SUPPORTEXPIRYDATE,            
     C.NONSUPPORTEXPIRYDATE ,            
     t.ROLETYPE ,          
     t.SASELICENSECOUNT,          
     C.ISZEROTOUCHALLOWED,           
     t.ORGNAME,      
     t.ISADDKEYSETAPPLICABLE,      
     t.MSSPMONTHLYOPTION,      
     C.ISNETWORKPRODUCT       
     , t.EMAILADDRESS,      
     t.DESCRIPTION , t.ISSHAREDTENANT    ,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY,t.MANAGEMENTOPTION,t.ORGID   
                   FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)  
         
        ,  #TEMPLISTTABLE   AS t   where   C.serialnumber=t.serialnumber          
                            ORDER BY C.CREATEDDATE DESC          
               
   INSERT INTO @PRODGROUPTABLE (PRODUCTGROUPID, PRODUCTGROUPNAME)      
       SELECT DISTINCT PRODUCTGROUPID, PRODUCTGROUPNAME FROM #TEMPLISTTABLE   AS t WHERE PRODUCTGROUPID IS NOT NULL        
        
UPDATE @PRODGROUPTABLE      
   SET TOTALPRODUCTSCNT = (SELECT COUNT(t.PRODUCTGROUPID)      
                   FROM #TEMPLISTTABLE t      
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID)      
  FROM @PRODGROUPTABLE P       
      
  UPDATE @PRODGROUPTABLE      
   SET EXPIREDPRODUCTSCNT = (SELECT COUNT(t.PRODUCTGROUPID)      
                   FROM #TEMPLISTTABLE t      
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID      
      AND ISLICENSEEXPIRED = 1 AND MINLICENSEEXPIRYDATE IS NOT NULL)      
  FROM @PRODGROUPTABLE P       
      
  UPDATE @PRODGROUPTABLE      
   SET SOONEXPIRINGPRODDUCTSCNT = (SELECT COUNT(t.PRODUCTGROUPID)      
                   FROM #TEMPLISTTABLE t      
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID      
      AND  ISSOONEXPIRING = 1 AND SOONEXPIRYDATE IS NOT NULL)      
  FROM @PRODGROUPTABLE P       
      
  UPDATE @PRODGROUPTABLE      
   SET ACTIVEPRODUCTSCNT = ISNULL((SELECT SUM(ACTIVELICENSECNT)       
                   FROM #TEMPLISTTABLE t      
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID),0)      
  FROM @PRODGROUPTABLE P       
      
   UPDATE @PRODGROUPTABLE      
    SET FIREWALLCNT =  (SELECT COUNT(t.PRODUCTGROUPID)      
                   FROM #TEMPLISTTABLE t,  CUSTOMERPRODUCTSSUMMARY C with (nolock)         
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID      
      AND C.serialnumber=t.serialnumber              
      AND  C.PRODUCTTYPE = 'Firewall')      
   FROM @PRODGROUPTABLE P      
      
  UPDATE @PRODGROUPTABLE      
    SET ACCESSPOINTCNT =  (SELECT COUNT(t.PRODUCTGROUPID)      
                  FROM #TEMPLISTTABLE t,  CUSTOMERPRODUCTSSUMMARY C with (nolock)         
                  WHERE t.PRODUCTGROUPID = P.PRODUCTGROUPID      
      AND C.serialnumber=t.serialnumber              
      AND  C.PRODUCTTYPE = 'Access Points')      
   FROM @PRODGROUPTABLE P       
      
       
  IF ISNULL(@APPLICATIONNAME,'') <> 'MSWANDROID' AND @ISPRODUCTGROUPTABLENEEDED = 'YES'      
 BEGIN      
  SELECT * FROM @PRODGROUPTABLE      
 END      
      
                  RETURN                    
                        END                 
              END                
            ELSE             
                BEGIN      
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                   IF @PRODUCTLIST = 'LIMIT'             
                        BEGIN              
                            SELECT DISTINCT TOP 10            
       C.PRODUCTID ,            
       C.SERIALNUMBER ,            
       C.[NAME] ,            
       C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
       C.REGISTRATIONCODE ,            
       C.FIRMWAREVERSION ,            
        PRODUCT.PRODUCTLINE ,            
       C.PRODUCTFAMILY ,            
       C.ACTIVEPROMOTION ,            
       C.PROMOTIONID ,            
       C.NFR ,            
       PRODUCT.OWNEROFTHEPRODUCT ,            
       PRODUCT.PRODUCTOWNER ,            
       C.ISSUENAME ,            
       C.RESOLUTIONNAME ,            
       C.PRODUCTNAME ,            
       C.PRODUCTGROUPID ,            
       C.PRODUCTGROUPNAME ,            
       C.DISPLAYKEYSET ,            
       C.ASSOCIATIONTYPE ,            
       C.GROUPHEADERTEXT ,            
       C.ISEPRS ,            
       C.CREATEDDATE AS REGISTRATIONDATE,       
    --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,   
 C.LASTPINGDATE AS LASTPINGDATE,  
       C.HGMSPROVISIONINGSTATUS,          
       C.DEVICESTATUS,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.LTAB,          
     C.CBKUPTAB,          
       C.FWTAB,          
       C.SENTINELONEEXPIRYDATE  ,         
       C.PRODUCTTYPE,          
       PRODUCT.LICENSEEXPIRYCNT,          
       PRODUCT.SOONEXPIRINGCNT,          
       PRODUCT.ACTIVELICENSECNT,     
       PRODUCT.MINLICENSEEXPIRYDATE,          
       PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE,C.ISBILLABLE ,          
       C.SUPPORTEXPIRYDATE,          
       C.NONSUPPORTEXPIRYDATE ,          
       PRODUCT.ROLETYPE  ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE,      
    PRODUCT.MSSPMONTHLYOPTION,      
    C.ISNETWORKPRODUCT , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT ,PRODUCTCHOICEID ,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY,PRODUCT.MANAGEMENTOPTION,PRODUCT.ORGID       
      FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber          
                            ORDER BY C.CREATEDDATE DESC            
                            FOR     XML AUTO ,            
           ELEMENTS                                     
    RETURN               
                        END            
 ELSE             
                        BEGIN       
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)        
                            SELECT DISTINCT            
     C.PRODUCTID ,            
        C.SERIALNUMBER ,            
        C.[NAME] ,            
        C.CUSTOMERPRODUCTID ,            
        C.STATUS ,            
        C.REGISTRATIONCODE ,            
        C.FIRMWAREVERSION ,            
         PRODUCT.PRODUCTLINE ,            
        C.PRODUCTFAMILY ,            
        C.ACTIVEPROMOTION ,            
        C.PROMOTIONID ,            
        C.NFR ,            
        PRODUCT.OWNEROFTHEPRODUCT ,            
        PRODUCT.PRODUCTOWNER ,            
        C.ISSUENAME ,            
        C.RESOLUTIONNAME ,            
        C.PRODUCTNAME ,            
        C.PRODUCTGROUPID ,            
        C.PRODUCTGROUPNAME ,            
        C.DISPLAYKEYSET ,            
        C.ASSOCIATIONTYPE ,            
        C.GROUPHEADERTEXT ,            
        C.ISEPRS ,            
        C.CREATEDDATE AS REGISTRATIONDATE,      
  --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,         
  C.LASTPINGDATE AS LASTPINGDATE,  
        C.HGMSPROVISIONINGSTATUS,          
        C.DEVICESTATUS,          
        PRODUCT.ISDELETEALLOWED,          
        PRODUCT.ISTRANSFERALLOWED,          
        PRODUCT.ISRENAMEALLOWED,          
        PRODUCT.ISSECUREUPGRADE,          
        C.PTAB,          
        C.LTAB,          
        C.CBKUPTAB,          
        C.FWTAB,          
        C.SENTINELONEEXPIRYDATE,          
        C.PRODUCTTYPE,          
        PRODUCT.LICENSEEXPIRYCNT,          
        PRODUCT.SOONEXPIRINGCNT,          
        PRODUCT.ACTIVELICENSECNT,          
        PRODUCT.MINLICENSEEXPIRYDATE,          
     PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE,C.ISBILLABLE ,          
        C.SUPPORTEXPIRYDATE,          
        C.NONSUPPORTEXPIRYDATE ,          
        PRODUCT.ROLETYPE ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE,      
  PRODUCT.MSSPMONTHLYOPTION,      
  C.ISNETWORKPRODUCT   , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION , PRODUCT.ISSHAREDTENANT     ,PRODUCTCHOICEID,C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY    
FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber           
        ORDER BY C.CREATEDDATE DESC            
                            FOR     XML AUTO ,            
                                        ELEMENTS                                     
       RETURN               
                        END            
                                
                END                                    
      END               
            
    IF @ORDERNAME = 'REGISTEREDDATE'            
        AND @ORDERTYPE = '1'             
        BEGIN    
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)    
            IF ( @OutformatXML = 0 )             
                BEGIN                       
                    SELECT DISTINCT            
       C.PRODUCTID ,            
       C.SERIALNUMBER ,            
       C.[NAME] ,            
       C.CUSTOMERPRODUCTID ,            
       C.STATUS ,            
       C.REGISTRATIONCODE ,            
       C.FIRMWAREVERSION ,            
        PRODUCT.PRODUCTLINE ,            
       C.PRODUCTFAMILY ,            
       C.ACTIVEPROMOTION ,            
       C.PROMOTIONID ,            
       C.NFR ,            
       PRODUCT.OWNEROFTHEPRODUCT ,            
       PRODUCT.PRODUCTOWNER ,            
       C.ISSUENAME ,            
       C.RESOLUTIONNAME ,          
       C.PRODUCTNAME ,            
       C.PRODUCTGROUPID ,            
       C.PRODUCTGROUPNAME ,           
       PRODUCT.PARTYGROUPNAMES,          
       C.RELEASESTATUS ,          
       C.DISPLAYKEYSET ,            
       C.ASSOCIATIONTYPE ,            
       C.GROUPHEADERTEXT ,            
       C.ASSOCIATIONTYPEID ,            
       C.ISEPRS ,            
       C.CREATEDDATE AS REGISTRATIONDATE ,      
   -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,       
   C.LASTPINGDATE AS LASTPINGDATE,  
 C.REMOVEASSOCIATION ,            
       C.DELETEDM ,            
       C.REGCODE,            
       C.HGMSPROVISIONINGSTATUS,          
       C.MCAFEEORDER,          
       C.DEVICESTATUS,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.S1SVCSTATUS,          
       C.SENTINELONEEXPIRYDATE,          
       C.PRODUCTTYPE,          
       C.LICENSEEXPIRYCNT,          
       C.SOONEXPIRINGCNT,          
       C.ACTIVELICENSECNT,          
       PRODUCT.MINLICENSEEXPIRYDATE,          
       PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE,C.ISBILLABLE ,          
       C.SUPPORTEXPIRYDATE,          
       C.NONSUPPORTEXPIRYDATE ,          
       PRODUCT.ROLETYPE  ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE,      
    PRODUCT.MSSPMONTHLYOPTION,      
    C.ISNETWORKPRODUCT ,      
    PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION, PRODUCT.ISSHAREDTENANT  ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY      
       FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber           
                    ORDER BY C.CREATEDDATE ASC               
                    RETURN                
       END                
            ELSE             
                BEGIN    
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)      
                    SELECT DISTINCT            
      C.PRODUCTID ,            
      C.SERIALNUMBER ,            
      C.[NAME] ,            
      C.CUSTOMERPRODUCTID ,            
      C.STATUS ,            
      C.REGISTRATIONCODE ,            
      C.FIRMWAREVERSION ,            
       PRODUCT.PRODUCTLINE ,            
      C.PRODUCTFAMILY ,            
      C.ACTIVEPROMOTION ,            
      C.PROMOTIONID ,            
      C.NFR ,            
      PRODUCT.OWNEROFTHEPRODUCT ,            
      PRODUCT.PRODUCTOWNER ,            
      C.ISSUENAME ,            
      C.RESOLUTIONNAME ,            
      C.PRODUCTNAME ,            
      C.PRODUCTGROUPID ,            
      C.PRODUCTGROUPNAME ,            
      PRODUCT.PARTYGROUPNAMES,          
      C.RELEASESTATUS ,          
      C.DISPLAYKEYSET ,            
      C.ASSOCIATIONTYPE ,            
      C.GROUPHEADERTEXT ,            
      C.ISEPRS ,            
      C.CREATEDDATE AS REGISTRATIONDATE ,       
  -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,          
  C.LASTPINGDATE AS LASTPINGDATE,  
      C.REGCODE,            
      C.HGMSPROVISIONINGSTATUS,          
      C.DEVICESTATUS,          
      PRODUCT.ISDELETEALLOWED,          
      PRODUCT.ISTRANSFERALLOWED,          
      PRODUCT.ISRENAMEALLOWED,          
      PRODUCT.ISSECUREUPGRADE,          
      C.SENTINELONEEXPIRYDATE ,          
      C.PRODUCTTYPE,          
     C.LICENSEEXPIRYCNT,          
      C.SOONEXPIRINGCNT,          
      C.ACTIVELICENSECNT,          
      PRODUCT.MINLICENSEEXPIRYDATE,          
      PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE,C.ISBILLABLE ,          
      C.SUPPORTEXPIRYDATE,          
       C.NONSUPPORTEXPIRYDATE ,          
       PRODUCT.ROLETYPE  ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE ,      
    PRODUCT.MSSPMONTHLYOPTION,      
    C.ISNETWORKPRODUCT,     PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION, PRODUCT.ISSHAREDTENANT  ,PRODUCTCHOICEID , C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY       
                    FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber           
                    ORDER BY C.CREATEDDATE ASC            
                    FOR     XML AUTO ,            
                   ELEMENTS                                     
                    RETURN                
                END                                    
        END               
                    
    IF @PRODUCTLIST = 'LIMIT'             
        BEGIN         
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)    
            IF ( @OutformatXML = 0 )             
                BEGIN                                    
                    SELECT DISTINCT TOP 10            
     C.PRODUCTID ,            
     C.SERIALNUMBER ,            
     C.[NAME] ,            
     C.CUSTOMERPRODUCTID ,            
     C.STATUS ,            
     C.REGISTRATIONCODE ,            
     C.FIRMWAREVERSION ,            
      PRODUCT.PRODUCTLINE ,            
     C.PRODUCTFAMILY ,            
     C.CREATEDDATE ,            
     C.NFR ,            
     PRODUCT.OWNEROFTHEPRODUCT ,            
     PRODUCT.PRODUCTOWNER ,            
     C.ISSUENAME ,            
     C.RESOLUTIONNAME ,            
     C.PRODUCTNAME ,            
     C.PRODUCTGROUPID ,            
     C.PRODUCTGROUPNAME ,            
     C.DISPLAYKEYSET ,            
     C.ASSOCIATIONTYPE ,            
     C.GROUPHEADERTEXT ,            
     C.ASSOCIATIONTYPEID ,            
     C.ISEPRS ,           
     C.REMOVEASSOCIATION ,            
     C.DELETEDM ,            
     C.REGCODE ,            
     C.CREATEDDATE AS REGISTRATIONDATE,      
  --CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,    
  C.LASTPINGDATE AS LASTPINGDATE,  
     C.HGMSPROVISIONINGSTATUS,          
     C.MCAFEEORDER,          
     C.DEVICESTATUS,          
     PRODUCT.ISDELETEALLOWED,          
     PRODUCT.ISTRANSFERALLOWED,          
     PRODUCT.ISRENAMEALLOWED,          
     PRODUCT.ISSECUREUPGRADE,          
     C.S1SVCSTATUS,          
     C.SENTINELONEEXPIRYDATE,          
     C.PRODUCTTYPE,          
     C.LICENSEEXPIRYCNT,          
     C.SOONEXPIRINGCNT,          
     C.ACTIVELICENSECNT,          
     PRODUCT.MINLICENSEEXPIRYDATE,          
     PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE ,          
     C.SUPPORTEXPIRYDATE,          
       C.NONSUPPORTEXPIRYDATE,          
       PRODUCT.ROLETYPE  ,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED, PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE,      
    PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT,     PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION, PRODUCT.ISSHAREDTENANT      ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY   
                 FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT   where   C.serialnumber=PRODUCT.serialnumber   
                    ORDER BY C.CREATEDDATE DESC                   
                    RETURN                
                END                
            ELSE             
   BEGIN              
 --Whenever changes added in this sp we have to add changes of this SPUPDATEFIRMWARESERIALNUMBER too. (changes in getting serial number details)     
                    SELECT DISTINCT TOP 10            
          C.PRODUCTID ,            
                            C.SERIALNUMBER ,            
                           C. [NAME] ,            
                           C. CUSTOMERPRODUCTID ,            
                           C. STATUS ,            
                           C. REGISTRATIONCODE ,            
                            C.FIRMWAREVERSION ,            
                       C. PRODUCTLINE ,            
                           C.PRODUCTFAMILY ,            
                           C. CREATEDDATE ,            
                           C. NFR ,            
                           PRODUCT. OWNEROFTHEPRODUCT ,            
                           PRODUCT. PRODUCTOWNER ,            
                           C. ISSUENAME ,            
                      C.RESOLUTIONNAME ,            
                           C. PRODUCTNAME ,            
                           C. PRODUCTGROUPID ,            
                           C. PRODUCTGROUPNAME ,            
                           C. DISPLAYKEYSET ,            
                           C. ASSOCIATIONTYPE ,            
        C. GROUPHEADERTEXT ,            
       C.ASSOCIATIONTYPEID ,            
  C.ISEPRS ,            
  C.REMOVEASSOCIATION ,            
                            C.DELETEDM ,            
                            C.REGCODE ,            
  C.CREATEDDATE AS REGISTRATIONDATE,      
 -- CASE WHEN @APPNAME ='SNB' THEN C.LASTPINGDATE END AS LASTPINGDATE,        
 C.LASTPINGDATE AS LASTPINGDATE,  
       C.HGMSPROVISIONINGSTATUS,          
       C.MCAFEEORDER,          
       C.DEVICESTATUS,          
       PRODUCT.ISDELETEALLOWED,          
       PRODUCT.ISTRANSFERALLOWED,          
       PRODUCT.ISRENAMEALLOWED,          
       PRODUCT.ISSECUREUPGRADE,          
       C.S1SVCSTATUS,          
       C.SENTINELONEEXPIRYDATE,          
       C.PRODUCTTYPE,          
       C.LICENSEEXPIRYCNT,          
       C.SOONEXPIRINGCNT,          
       C.ACTIVELICENSECNT,          
       PRODUCT.MINLICENSEEXPIRYDATE,          
       PRODUCT.SOONEXPIRYDATE,C.EPAID ,C.SERVICELINE ,C.ISBILLABLE ,          
       C.SUPPORTEXPIRYDATE,          
         C.NONSUPPORTEXPIRYDATE,          
         PRODUCT.ROLETYPE,C.SASELICENSECOUNT,C.ISZEROTOUCHALLOWED,PRODUCT.ORGNAME, PRODUCT.ISADDKEYSETAPPLICABLE,      
   PRODUCT.MSSPMONTHLYOPTION,C.ISNETWORKPRODUCT , PRODUCT.EMAILADDRESS,      
    PRODUCT.DESCRIPTION  , PRODUCT.ISSHAREDTENANT     ,PRODUCTCHOICEID, C.VULTOOLTIPTEXT, C.VULHREFTEXT,C.VULSEVERITY    
                    FROM  CUSTOMERPRODUCTSSUMMARY C with (nolock)          
        ,  #TEMPLISTTABLE   AS PRODUCT  where   C.serialnumber=PRODUCT.serialnumber          
                    ORDER BY C.CREATEDDATE DESC            
    FOR     XML AUTO ,            
                                ELEMENTS                      
                    RETURN                
                END              
             
        DROP TABLE #TEMPLISTTABLE        
  --DROP TABLE #tempPRGD      
        END             
 END         
          

      
      
      
