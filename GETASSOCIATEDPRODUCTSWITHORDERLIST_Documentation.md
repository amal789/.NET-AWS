# GETASSOCIATEDPRODUCTSWITHORDERLIST Stored Procedure Documentation

## Overview
The `GETASSOCIATEDPRODUCTSWITHORDERLIST` stored procedure is designed to retrieve associated products with order lists from a customer management system. This procedure supports various filtering options, localization, and output formats to accommodate different use cases.

## Purpose
This stored procedure retrieves product information associated with orders, including:
- Product details and status
- Association types and relationships
- License information and expiry dates
- Customer-specific product data
- Mobile and web application support

## Parameters

### Required Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `@USERNAME` | NVARCHAR(30) | User identifier for authentication and authorization |
| `@ORDERNAME` | VARCHAR(50) | Name of the order to retrieve products for |
| `@ORDERTYPE` | VARCHAR(30) | Type of order (e.g., STANDARD, PREMIUM, MOBILE) |

### Optional Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `@ASSOCTYPEID` | INT | 0 | Association type ID for filtering |
| `@ASSOCTYPE` | VARCHAR(30) | '' | Association type name |
| `@SERIALNUMBER` | VARCHAR(30) | '' | Specific serial number filter |
| `@LANGUAGECODE` | CHAR(2) | 'EN' | Language code for localization |
| `@SESSIONID` | VARCHAR(50) | NULL | Session identifier |
| `@PRODUCTLIST` | VARCHAR(100) | NULL | Comma-separated list of product IDs |
| `@OEMCODE` | CHAR(4) | 'SNWL' | OEM code |
| `@APPNAME` | VARCHAR(50) | 'MSW' | Application name |
| `@OutformatXML` | INT | NULL | Output format flag (1 for XML) |
| `@CallFrom` | VARCHAR(50) | NULL | Calling application identifier |
| `@IsMobile` | VARCHAR(50) | 'NO' | Mobile application flag |
| `@SOURCE` | VARCHAR(10) | '' | Source system identifier |
| `@SEARCHSERIALNUMBER` | VARCHAR(30) | '' | Serial number for search operations |
| `@ISPRODUCTGROUPTABLENEEDED` | VARCHAR(10) | 'YES' | Flag for product group table inclusion |

## Return Values
The procedure returns a result set containing product information with the following key fields:

### Core Product Information
- `PRODUCTID`: Unique product identifier
- `SERIALNUMBER`: Product serial number
- `NAME`: Product name
- `CUSTOMERPRODUCTID`: Customer-specific product ID
- `STATUS`: Product status
- `PRODUCTLINE`: Product line classification
- `PRODUCTFAMILY`: Product family classification

### Association Information
- `ASSOCIATIONTYPE`: Type of association
- `ASSOCIATIONTYPEID`: Association type identifier
- `OWNEROFTHEPRODUCT`: Product owner information
- `PRODUCTOWNER`: Product ownership details

### License and Support Information
- `LICENSEEXPIRYCNT`: Count of expiring licenses
- `SOONEXPIRINGCNT`: Count of soon-to-expire licenses
- `ACTIVELICENSECNT`: Count of active licenses
- `SUPPORTEXPIRYDATE`: Support expiration date
- `NONSUPPORTEXPIRYDATE`: Non-support expiration date

### Technical Information
- `FIRMWAREVERSION`: Current firmware version
- `REGISTRATIONCODE`: Product registration code
- `CREATEDDATE`: Product creation date
- `LASTPINGDATE`: Last ping date for connectivity

## Usage Examples

### Basic Usage
```sql
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'john.doe',
    @ORDERNAME = 'ORDER_2024_001',
    @ORDERTYPE = 'STANDARD'
```

### With Association Filtering
```sql
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'john.doe',
    @ORDERNAME = 'ORDER_2024_001',
    @ORDERTYPE = 'STANDARD',
    @ASSOCTYPEID = 1,
    @ASSOCTYPE = 'PRIMARY'
```

### Mobile Application Usage
```sql
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'mobile_user',
    @ORDERNAME = 'MOBILE_ORDER_001',
    @ORDERTYPE = 'MOBILE',
    @IsMobile = 'YES',
    @APPNAME = 'MSW'
```

### XML Output Format
```sql
EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
    @USERNAME = 'api_user',
    @ORDERNAME = 'API_ORDER_001',
    @ORDERTYPE = 'STANDARD',
    @OutformatXML = 1
```

## Business Logic

### User Authentication and Authorization
- Validates user credentials against `VCUSTOMER` view
- Checks user permissions and organization access
- Supports large customer and organization-based account types

### Product Association Logic
- Retrieves products based on order associations
- Supports multiple association types and relationships
- Handles product ownership and transfer scenarios

### Localization Support
- Supports multiple language codes
- Provides localized product names and descriptions
- Handles region-specific configurations

### Mobile and Web Optimization
- Optimizes queries for mobile applications
- Supports different output formats (standard vs XML)
- Handles session-based access control

## Performance Considerations

### Optimization Tips
1. **Always provide required parameters** for best performance
2. **Use specific serial numbers** when possible to reduce result sets
3. **Set `@ISPRODUCTGROUPTABLENEEDED = 'NO'`** if product group data is not needed
4. **Use appropriate language codes** to avoid unnecessary localization processing
5. **Consider using `@PRODUCTLIST`** to filter specific products
6. **Set `@IsMobile = 'YES'`** for mobile applications

### Indexing Recommendations
- Ensure proper indexing on `USERNAME`, `ORDERNAME`, and `ORDERTYPE`
- Index `SERIALNUMBER` for serial number-based queries
- Consider composite indexes for frequently used parameter combinations

## Error Handling

### Common Error Scenarios
- Invalid username or authentication failure
- Missing required parameters
- Database connection issues
- Permission denied errors

### Error Handling Example
```sql
BEGIN TRY
    EXEC [dbo].[GETASSOCIATEDPRODUCTSWITHORDERLIST]
        @USERNAME = 'valid_user',
        @ORDERNAME = 'TEST_ORDER',
        @ORDERTYPE = 'STANDARD'
END TRY
BEGIN CATCH
    PRINT 'Error occurred: ' + ERROR_MESSAGE()
    -- Handle specific error scenarios
END CATCH
```

## Dependencies

### Database Objects
- `VCUSTOMER`: Customer information view
- `CUSTOMERPRODUCTSSUMMARY`: Product summary table
- `SESSIONREV`: Session management table
- `APPLICATIONCONFIGVALUE`: Application configuration
- `APPLICATIONROLE`: Role management table

### Functions
- `DBO.FNISMSSPUSER`: MSSP user validation function

## Security Considerations

### Access Control
- User-based authentication and authorization
- Organization-based access control
- Role-based permissions
- Session-based security

### Data Protection
- Parameterized queries to prevent SQL injection
- Input validation and sanitization
- Audit trail support through session tracking

## Maintenance Notes

### Version Compatibility
- Compatible with SQL Server 2016 and later
- Supports both on-premises and cloud deployments
- Maintains backward compatibility with existing integrations

### Update Considerations
- Changes to this procedure may require updates to `SPUPDATEFIRMWARESERIALNUMBER`
- Test thoroughly when modifying parameter logic
- Consider impact on dependent applications and integrations

## Related Procedures
- `SPUPDATEFIRMWARESERIALNUMBER`: Related firmware update procedure
- Other product management procedures in the system

## Support and Troubleshooting

### Common Issues
1. **No results returned**: Check user permissions and order existence
2. **Performance issues**: Verify parameter values and indexing
3. **Localization problems**: Ensure correct language code usage
4. **Mobile app issues**: Verify `@IsMobile` parameter setting

### Debugging Tips
- Use PRINT statements to trace parameter values
- Check execution plans for performance bottlenecks
- Verify user permissions and organization access
- Review session and authentication logs