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
    -- SELECT @APPLICA... (incomplete - appears to be cut off)

    -- TODO: Complete the stored procedure implementation
    
END