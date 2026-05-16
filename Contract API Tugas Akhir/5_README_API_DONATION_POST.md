# 5. Donation Post
## Create Donation Post
```
Endpoint : POST /donations
```
### Headers
```
Authorization : Bearer {access_token}
Content-Type : multipart/form-data
```
### Form Data
```
food_name        : required, string, min 3 characters   
food_description : optional, string, max 500 characters
expired_at       : required, datetime, must be greater than current time  
latitude         : required, number, between -90 and 90  
longitude        : required, number, between -180 and 180  
location_text    : required, string   
photo            : required, file (jpg, jpeg, png, max 5 MB) 
```
### Example Request
```
food_name        = "Nasi Goreng 5 Porsi"  
food_description = "Masih hangat, dibuat sekitar 1 jam yang lalu"  
expired_at       = "2026-04-05T18:00:00Z"  
latitude         = -6.914744  
longitude        = 107.609810  
location_text    = "Jl. Asia Afrika No. 10, Bandung"   
photo            = [file]  
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Donation posted successfully",
  "data": {
    "id": 45,
    "status": "posted"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "food_name": [
      "Food name is required"
    ],
    "expired_at": [
      "Expired time is required"
    ],
    "latitude": [
      "Latitude is required"
    ],
    "longitude": [
      "Longitude is required"
    ],
    "location_text": [
      "Location is required"
    ],
    "photo": [
      "Photo is required"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid Expired Time)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "expired_at": [
      "Expired time must be greater than current time"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid Expired Time)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "expired_at": [
      "Expired time must be greater than current time"
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
### Response Error (422 Unprocessable Entity - Invalid Photo)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "photo": [
      "Photo must be a JPG, JPEG, or PNG file"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Photo Too Large)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "photo": [
      "Photo size must not exceed 5 MB"
    ]
  }
}
```

### Response Error (401 Unauthorized)
```json
{
  "success": false,
  "message": "Unauthorized",
  "errors": {
    "authorization": [
      "Access token is invalid or expired"
    ]
  }
}
```

### Possible Status : 
```
posted  
claimed  
completed  
expired  
cancelled  
```

## Get Nearby Donations
```
Endpoint : GET /donations?lat=-6.91&lng=107.60&radius=5&page=1
```
### Query Parameters
```
lat    : required, decimal, between -90 and 90
lng    : required, decimal, between -180 and 180
radius : optional, integer, default 5 (km)
page   : optional, integer, default 1
```
### Example Request
```
GET /donations?lat=-6.9181&lng=107.6080&radius=5&page=1
```
### Response Success (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 45,
      "food_name": "Ayam Bakar Sisa MBG",
      "food_description": "Makanan masih utuh di dalam kotak",
      "photo_url": "https://api.example.com/uploads/donations/45.jpg",
      "distance_km": 0.75,
      "uploaded_at": "5 minutes ago",
      "claim_deadline": "14:00",
      "status": "posted",
      "location": {
        "latitude": -6.91,
        "longitude": 107.60,
        "address": "Cipagalo, Bandung"
      },
      "owner": {
        "id": 12,
        "full_name": "Muna Verify"
      }
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 10,
    "total": 22
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "lat": [
      "Latitude is required"
    ],
    "lng": [
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
    "lat": [
      "Latitude must be between -90 and 90"
    ],
    "lng": [
      "Longitude must be between -180 and 180"
    ]
  }
}
```
### Response Success (200 OK - Empty Result)
```json
{
  "success": true,
  "data": [],
  "meta": {
    "page": 1,
    "per_page": 10,
    "total": 0
  }
}
```

## Get Donation Detail
```
Endpoint : GET /donations{id}
```
### Example Request 
```
GET /donations{1}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "data": {
    "id": 45,
    "food_name": "Ayam Bakar Sisa MBG",
    "food_description": "Makanan masih utuh di dalam kotak",
    "photo_url": "https://api.example.com/uploads/donations/45.jpg",
    "status": "posted",
    "uploaded_at": "2026-04-05T12:00:00Z",
    "expired_at": "2026-04-05T14:00:00Z",
    "location": {
      "latitude": -6.91,
      "longitude": 107.60,
      "address": "Cipagalo, Bandung"
    },
    "owner": {
      "id": 12,
      "full_name": "Muna Verify",
      "photo_url": null
    }
  }
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Donation not found"
}
```

## Update Donation
```
Endpoint : PUT /donations{id}
```
### Headers
```
Authorization : Bearer {access_token}
Content-Type : application/json
```
### Request
```json
{
  "food_name": "Ayam Goreng",
  "food_description": "Masih layak dimakan",
  "expired_at": "2026-03-31T14:00:00Z"
}
```
### Validation Rules
```
* food_name : optional, minimum 3 characters
* food_description : optional, maximum 500 characters
* expired_at : optional, datetime, must be greater than current time
* At least one field must be filled
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Donation updated successfully",
  "data": {
    "id": 45,
    "food_name": "Ayam Goreng",
    "food_description": "Masih layak dimakan",
    "expired_at": "2026-03-31T14:00:00Z",
    "status": "posted"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "food_name": [
      "Food name must be at least 3 characters"
    ],
    "expired_at": [
      "Expired time must be greater than current time"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Empty Request)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "request": [
      "At least one field must be provided"
    ]
  }
}
```
### Response Error (403 Forbidden - Not Owner)
```json
{
  "success": false,
  "message": "You are not allowed to update this donation"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Donation not found"
}
```
### Response Error (409 Conflict - Donation Already Claimed)
```json
{
  "success": false,
  "message": "Donation can no longer be updated",
  "errors": {
    "status": [
      "Donation has already been claimed or completed"
    ]
  }
}
```
## Delete Donation 
``` 
Endpoint : DELETE /donations{id}
```
### Headers
```
Authorization : Bearer {access_token}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Donation deleted successfully"
}
```
### Response Error (403 Forbidden - Not Owner)
```json
{
  "success": false,
  "message": "You are not allowed to delete this donation"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Donation not found"
}
```
### Response Error (409 Conflict - Donation Already Claimed)
```json
{
  "success": false,
  "message": "Donation cannot be deleted",
  "errors": {
    "status": [
      "Donation has already been claimed or completed"
    ]
  }
}
```
