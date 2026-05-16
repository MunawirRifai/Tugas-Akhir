# 4. Location
## Save User Location
Endpoint : POST /me/location

### Headers
Authorization : Bearer {access_token}
Content-Type : application/json

### Request 
```json
{
  "latitude": -6.914744,
  "longitude": 107.609810
}
```

### Valiation Rules
* latitude : required, decimal, between -90 and 90
* longitude : required, decimal, between -180 and 180

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Location saved successfully",
  "data": {
    "latitude": -6.914744,
    "longitude": 107.609810,
    "updated_at": "2026-04-04T08:00:00Z"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "latitude": [
      "Latitude is required"
    ],
    "longitude": [
      "Longitude is required"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid Coordinate)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "latitude": [
      "Latitude must be between -90 and 90"
    ],
    "longitude": [
      "Longitude must be between -180 and 180"
    ]
  }
}
```
### Response Error (401 Unauthorized - Missing Token)
```json
{
  "success": false,
  "message": "Unauthorized",
  "errors": {
    "authorization": [
      "Access token is required"
    ]
  }
}
```
### Response Error (401 Unauthorized - Invalid Token)
```json
{
  "success": false,
  "message": "Invalid access token",
  "errors": {
    "authorization": [
      "Access token is invalid or expired"
    ]
  }
}
```

