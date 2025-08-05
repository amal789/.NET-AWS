-- =====================================================
-- INDEXING RECOMMENDATIONS FOR GETASSOCIATEDPRODUCTSWITHORDERLIST
-- Comprehensive indexing strategy to optimize performance
-- =====================================================

-- ===================================================== 
-- 1. TEMPORARY TABLE INDEXING
-- ===================================================== 

-- Primary temporary table used throughout the procedure
-- Current: Only has clustered index on SERIALNUMBER

-- Enhanced indexing strategy for #TEMPLISTTABLE:
CREATE CLUSTERED INDEX IDX_TEMPLISTTABLE_CID ON #TEMPLISTTABLE(CID);
CREATE NONCLUSTERED INDEX IDX_TEMPLISTTABLE_SERIALNUMBER ON #TEMPLISTTABLE(SERIALNUMBER) INCLUDE (PRODUCTID, PRODUCTFAMILY, PRODUCTLINE);
CREATE NONCLUSTERED INDEX IDX_TEMPLISTTABLE_PRODUCTID ON #TEMPLISTTABLE(PRODUCTID) INCLUDE (SERIALNUMBER);
CREATE NONCLUSTERED INDEX IDX_TEMPLISTTABLE_PRODUCTGROUPID ON #TEMPLISTTABLE(PRODUCTGROUPID) INCLUDE (SERIALNUMBER, PRODUCTID);
CREATE NONCLUSTERED INDEX IDX_TEMPLISTTABLE_OWNEROFTHEPRODUCT ON #TEMPLISTTABLE(OWNEROFTHEPRODUCT) INCLUDE (SERIALNUMBER);

-- For pagination support (after adding ROWNUMBER column):
CREATE NONCLUSTERED INDEX IDX_TEMPLISTTABLE_ROWNUMBER ON #TEMPLISTTABLE(ROWNUMBER) INCLUDE (SERIALNUMBER, PRODUCTID);

-- For large datasets, consider columnstore index for analytical queries:
-- CREATE NONCLUSTERED COLUMNSTORE INDEX IDX_TEMPLISTTABLE_COLUMNSTORE 
-- ON #TEMPLISTTABLE (PRODUCTID, SERIALNUMBER, PRODUCTFAMILY, PRODUCTLINE, ACTIVEPROMOTION, PRODUCTGROUPID);

-- Secondary temporary table #tempPRGD:
CREATE CLUSTERED INDEX IDX_tempPRGD_SERIALNUMBER ON #tempPRGD(SERIALNUMBER);
CREATE NONCLUSTERED INDEX IDX_tempPRGD_CONTACTID ON #tempPRGD(CONTACTID) INCLUDE (SERIALNUMBER);
CREATE NONCLUSTERED INDEX IDX_tempPRGD_PRODUCTGROUPID ON #tempPRGD(PRODUCTGROUPID) INCLUDE (SERIALNUMBER);

-- ===================================================== 
-- 2. MAIN TABLE INDEXING RECOMMENDATIONS
-- ===================================================== 

-- CUSTOMERPRODUCTSSUMMARY Table - Most frequently accessed
-- Current indexes should be analyzed, but recommended additions:

-- For username-based queries:
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_USERNAME_USEDSTATUS 
ON CUSTOMERPRODUCTSSUMMARY(USERNAME, USEDSTATUS) 
INCLUDE (SERIALNUMBER, PRODUCTID, PRODUCTFAMILY, PRODUCTLINE, CREATEDDATE);

-- For serial number lookups (if not already exists):
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_SERIALNUMBER_USEDSTATUS 
ON CUSTOMERPRODUCTSSUMMARY(SERIALNUMBER, USEDSTATUS) 
INCLUDE (PRODUCTID, PRODUCTFAMILY, PRODUCTLINE, CREATEDDATE, USERNAME);

-- For product family filtering:
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_PRODUCTFAMILY_USEDSTATUS 
ON CUSTOMERPRODUCTSSUMMARY(PRODUCTFAMILY, USEDSTATUS) 
INCLUDE (SERIALNUMBER, PRODUCTID, USERNAME);

-- For product line filtering:
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_PRODUCTLINE_USEDSTATUS 
ON CUSTOMERPRODUCTSSUMMARY(PRODUCTLINE, USEDSTATUS) 
INCLUDE (SERIALNUMBER, PRODUCTID, USERNAME);

-- VCUSTOMER Table:
-- For username lookups:
CREATE NONCLUSTERED INDEX IDX_VCUSTOMER_USERNAME 
ON VCUSTOMER(USERNAME) 
INCLUDE (CONTACTID, ORGANIZATIONID, LARGECUSTOMER, ORGBASEDACCOUNT, PARTYID, EMAILADDRESS);

-- For organization-based queries:
CREATE NONCLUSTERED INDEX IDX_VCUSTOMER_ORGANIZATIONID 
ON VCUSTOMER(ORGANIZATIONID) 
INCLUDE (USERNAME, CONTACTID, PARTYID);

-- DEVICEASSOCIATION Table:
-- For association type queries:
CREATE NONCLUSTERED INDEX IDX_DEVICEASSOCIATION_ASSOCTYPE_PRIMARY 
ON DEVICEASSOCIATION(PRODUCTASSOCIATIONTYPEID, PRIMARYSERIALNUMBER) 
INCLUDE (CHILDSERIALNUMBER, CONNECTORNAME);

CREATE NONCLUSTERED INDEX IDX_DEVICEASSOCIATION_ASSOCTYPE_CHILD 
ON DEVICEASSOCIATION(PRODUCTASSOCIATIONTYPEID, CHILDSERIALNUMBER) 
INCLUDE (PRIMARYSERIALNUMBER, CONNECTORNAME);

-- PRODUCTGROUPDETAIL Table:
CREATE NONCLUSTERED INDEX IDX_PRODUCTGROUPDETAIL_SERIALNUMBER 
ON PRODUCTGROUPDETAIL(SERIALNUMBER) 
INCLUDE (PRODUCTGROUPID);

CREATE NONCLUSTERED INDEX IDX_PRODUCTGROUPDETAIL_PRODUCTGROUPID 
ON PRODUCTGROUPDETAIL(PRODUCTGROUPID) 
INCLUDE (SERIALNUMBER);

-- SERVICESSUMMARY Table:
-- For node count queries:
CREATE NONCLUSTERED INDEX IDX_SERVICESSUMMARY_SERIALNUMBER_SERVICEFAMILY 
ON SERVICESSUMMARY(SERIALNUMBER, SERVICEFAMILY) 
INCLUDE (NODECOUNT, EXPIRATIONDATE, CREATEDDATE);

-- For expiration date queries:
CREATE NONCLUSTERED INDEX IDX_SERVICESSUMMARY_EXPIRATIONDATE 
ON SERVICESSUMMARY(EXPIRATIONDATE) 
INCLUDE (SERIALNUMBER, SERVICEFAMILY, NODECOUNT);

-- PARTYGROUP related tables:
CREATE NONCLUSTERED INDEX IDX_PARTYGROUPDETAIL_PARTYID 
ON PARTYGROUPDETAIL(PARTYID) 
INCLUDE (PARTYGROUPID);

CREATE NONCLUSTERED INDEX IDX_PARTYGROUPDETAIL_PARTYGROUPID 
ON PARTYGROUPDETAIL(PARTYGROUPID) 
INCLUDE (PARTYID);

-- ===================================================== 
-- 3. PERFORMANCE-CRITICAL COMPOSITE INDEXES
-- ===================================================== 

-- For the most common query patterns in the procedure:

-- Multi-column index for product filtering with user context:
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_COMPOSITE_FILTER 
ON CUSTOMERPRODUCTSSUMMARY(USEDSTATUS, PRODUCTFAMILY, PRODUCTLINE, USERNAME) 
INCLUDE (SERIALNUMBER, PRODUCTID, CREATEDDATE, ACTIVEPROMOTION);

-- For MSSP user queries:
CREATE NONCLUSTERED INDEX IDX_CUSTOMERPRODUCTSSUMMARY_MSSP 
ON CUSTOMERPRODUCTSSUMMARY(MSSPMONTHLY, PRODUCTID) 
INCLUDE (SERIALNUMBER, USERNAME, PRODUCTFAMILY);

-- For party-product-group relationships:
CREATE NONCLUSTERED INDEX IDX_VWPARTYPRODUCTGROUPDETAIL_CONTACTID_SERIALNUMBER 
ON VWPARTYPRODUCTGROUPDETAIL(CONTACTID, SERIALNUMBER) 
INCLUDE (PARTYGROUPID, PARTYGROUPNAME, PRODUCTGROUPID, PRODUCTGROUPNAME);

-- ===================================================== 
-- 4. APPLICATION CONFIGURATION OPTIMIZATION
-- ===================================================== 

-- APPLICATIONCONFIGVALUE table (frequently accessed for config values):
CREATE NONCLUSTERED INDEX IDX_APPLICATIONCONFIGVALUE_NAME 
ON APPLICATIONCONFIGVALUE(APPLICATIONCONFIGNAME) 
INCLUDE (APPLICATIONCONFIGVALUE);

-- ===================================================== 
-- 5. STATISTICS MAINTENANCE
-- ===================================================== 

-- Update statistics on critical tables (should be scheduled):
-- UPDATE STATISTICS CUSTOMERPRODUCTSSUMMARY WITH FULLSCAN;
-- UPDATE STATISTICS VCUSTOMER WITH FULLSCAN;
-- UPDATE STATISTICS DEVICEASSOCIATION WITH FULLSCAN;
-- UPDATE STATISTICS SERVICESSUMMARY WITH FULLSCAN;

-- ===================================================== 
-- 6. INDEX MAINTENANCE STRATEGY
-- ===================================================== 

-- Weekly index maintenance script:
/*
-- Check index fragmentation
SELECT 
    DB_NAME() AS DatabaseName,
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
    AND ips.page_count > 1000
    AND i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- Rebuild highly fragmented indexes (>30% fragmentation)
-- ALTER INDEX [IndexName] ON [TableName] REBUILD WITH (ONLINE = ON);

-- Reorganize moderately fragmented indexes (10-30% fragmentation)  
-- ALTER INDEX [IndexName] ON [TableName] REORGANIZE;
*/

-- ===================================================== 
-- 7. MONITORING MISSING INDEXES
-- ===================================================== 

-- Query to identify missing indexes for this procedure:
/*
SELECT 
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
    'CREATE INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' + 
    REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '') +
    CASE WHEN mid.inequality_columns IS NOT NULL 
         THEN '_' + REPLACE(REPLACE(REPLACE(mid.inequality_columns, ', ', '_'), '[', ''), ']', '') 
         ELSE '' END + 
    ' ON ' + mid.statement + ' (' + ISNULL (mid.equality_columns,'')
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL 
           THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '') + ')' 
    + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.*,
    mid.database_id,
    mid.object_id
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10
    AND mid.database_id = DB_ID()
    AND OBJECT_NAME(mid.object_id) IN ('CUSTOMERPRODUCTSSUMMARY', 'VCUSTOMER', 'DEVICEASSOCIATION', 'SERVICESSUMMARY')
ORDER BY improvement_measure DESC;
*/

-- ===================================================== 
-- 8. COLUMNSTORE INDEX CONSIDERATIONS
-- ===================================================== 

-- For large analytical workloads, consider columnstore indexes:
-- Only implement if the tables are large (millions of rows) and primarily read-only during analysis

/*
-- Example for CUSTOMERPRODUCTSSUMMARY if it's very large:
CREATE NONCLUSTERED COLUMNSTORE INDEX IDX_CUSTOMERPRODUCTSSUMMARY_COLUMNSTORE
ON CUSTOMERPRODUCTSSUMMARY (
    PRODUCTID, SERIALNUMBER, PRODUCTFAMILY, PRODUCTLINE, 
    USEDSTATUS, ACTIVEPROMOTION, CREATEDDATE, USERNAME,
    PRODUCTGROUPID, PRODUCTGROUPNAME
);
*/

-- ===================================================== 
-- 9. IMPLEMENTATION PRIORITY
-- ===================================================== 

-- HIGH PRIORITY (Implement first):
-- 1. Enhanced #TEMPLISTTABLE indexing
-- 2. CUSTOMERPRODUCTSSUMMARY serial number and username indexes
-- 3. VCUSTOMER username index
-- 4. DEVICEASSOCIATION association type indexes

-- MEDIUM PRIORITY (Implement after monitoring):
-- 1. SERVICESSUMMARY indexes
-- 2. Product group related indexes
-- 3. Composite indexes for complex queries

-- LOW PRIORITY (Monitor and implement if needed):
-- 1. Columnstore indexes
-- 2. Additional covering indexes based on query plan analysis

-- ===================================================== 
-- 10. TESTING AND VALIDATION
-- ===================================================== 

-- Before implementing:
-- 1. Capture current execution plans
-- 2. Record current execution times
-- 3. Monitor index usage after implementation
-- 4. Check for increased maintenance overhead

-- Monitor index usage:
/*
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan,
    s.last_user_lookup
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) IN ('CUSTOMERPRODUCTSSUMMARY', 'VCUSTOMER', 'DEVICEASSOCIATION', 'SERVICESSUMMARY')
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
*/