## Create Renewal/Security Contact API

### Overview
Create a Renewal Contact (default) or a Security Contact by calling the same endpoint and selecting the behavior via the `callerService` query parameter.

- **Base URL**: `https://mswrestapi-blr-dev.eng.sonicwall.com`
- **HTTP Method**: `POST`
- **Endpoint**: `/api/users/create-renewal-contact`

> Note: When `callerService` is not supplied, the service defaults to Renewal Contact creation (`RC`). Pass `SC` to create a Security Contact.

### Query parameters
- **callerService** (optional)
  - **Type**: string
  - **Default**: `RC`
  - **Allowed values**:
    - `RC` — Renewal Contact (default)
    - `SC` — Security Contact
  - **Behavior**: The endpoint switches functionality based on this value. If omitted, renewal contact creation runs. For values other than `RC`/`SC`, the service should reject the request.

### Request body
- **Content-Type**: `application/json`

- **Schema**
```json
{
  "renewalcontact": {
    "firstName": "string",
    "lastName": "string",
    "emailAddress": "string",
    "contactId": "string"
  },
  "adminEmail": "string"
}
```

- **Example**
```json
{
  "renewalcontact": {
    "firstName": "Amal",
    "lastName": "P",
    "emailAddress": "amal@sonicwall.com",
    "contactId": ""
  },
  "adminEmail": "tkanagaraj@sonicwall.com"
}
```

### Field notes and validation
- **renewalcontact.emailAddress**: May be any email domain the customer provides. The user does not need an active MSW account. There is no validation enforcing MSW account existence.
- Basic structural/syntactic checks (e.g., non-empty `emailAddress`) may still be applied by the service. Business rules beyond the above are out of scope of this document.

### Response
The exact response schema was not provided with the request. Below are illustrative examples; replace with the definitive schema once finalized.

- **Success (example)**
```json
{
  "success": true,
  "callerService": "RC",
  "contactId": "123456",
  "message": "Contact created successfully"
}
```

- **Error (example)**
```json
{
  "success": false,
  "errorCode": "INVALID_CALLER_SERVICE",
  "message": "callerService must be one of: RC, SC"
}
```

- **Typical HTTP status codes**
  - `200 OK` — Request processed successfully
  - `400 Bad Request` — Invalid input (e.g., unsupported `callerService`, malformed body)
  - `500 Internal Server Error` — Unexpected server-side error

### Examples
- **Create Renewal Contact (default `RC`)**
```bash
curl -X POST \
  'https://mswrestapi-blr-dev.eng.sonicwall.com/api/users/create-renewal-contact' \
  -H 'Content-Type: application/json' \
  -d '{
    "renewalcontact": {
      "firstName": "Amal",
      "lastName": "P",
      "emailAddress": "amal@sonicwall.com",
      "contactId": ""
    },
    "adminEmail": "tkanagaraj@sonicwall.com"
  }'
```

- **Create Security Contact (`callerService=SC`)**
```bash
curl -X POST \
  'https://mswrestapi-blr-dev.eng.sonicwall.com/api/users/create-renewal-contact?callerService=SC' \
  -H 'Content-Type: application/json' \
  -d '{
    "renewalcontact": {
      "firstName": "Amal",
      "lastName": "P",
      "emailAddress": "amal@anydomain.com",
      "contactId": ""
    },
    "adminEmail": "tkanagaraj@sonicwall.com"
  }'
```

### Flow functional diagram
```mermaid
flowchart TD
    A[Client] --> B[POST /api/users/create-renewal-contact<br/>?callerService=RC|SC]
    B --> C{callerService provided?}
    C -- No --> D[Set callerService = 'RC']
    C -- Yes --> E{callerService in {'RC','SC'}?}
    E -- No --> F[400 Bad Request<br/>(INVALID_CALLER_SERVICE)]
    E -- Yes --> G[Proceed with requested service]
    D --> G

    G --> H[Parse JSON body<br/>Content-Type: application/json]
    H --> I{emailAddress present?}
    I -- No --> J[400 Bad Request<br/>(MISSING_EMAIL)]
    I -- Yes --> K[Create contact record<br/>(Renewal or Security)]

    K --> L[Associate context with adminEmail if applicable]
    L --> M[Build response payload]

    M --> N[200 OK with success JSON]

    note right of H
      No validation is required that the
      email domain belongs to MSW or that
      the user has an MSW account.
    end
```

### Notes
- `callerService` toggles the behavior between renewal and security contact creation while keeping a single endpoint.
- The `emailAddress` field intentionally allows any domain and does not require the user to have an MSW account.
