# 3. Profile

## Get My Profile

Endpoint : GET /me

### Headers
Authorization : Bearer {access_token}

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": 12,
    "full_name": "Muna Verify",
    "email": "muna@example.com",
    "phone": "081234567890",
    "photo_url": null,
    "created_at": "2026-04-04T08:00:00Z"
  }
}
```
### Response Error (401 Unathorized - Missing Token)
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
### Response Error (401 Unathorized - Invalid Token)
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
---
## Update Profile
Endpoint : PUT /me
### Headers
Authorization : Bearer {access_token}
### Request 
```json
{
  "full_name": "Muna V",
  "phone": "081298765432"
}
```
### Validation Rules
* full_name : optional, minimum 3 characters
* phone : optional, valid phone number format, unique
* At least one file must be filled

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 12,
    "full_name": "Muna V",
    "email": "muna@example.com",
    "phone": "081298765432",
    "photo_url": null
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "full_name": [
      "Full name must be at least 3 characters"
    ],
    "phone": [
      "Phone number format is invalid"
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
### Response Error (409 Conflict - Phone Already Registered)
```json
{
  "success": false,
  "message": "Phone already registered",
  "errors": {
    "phone": [
      "Phone number is already used by another account"
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
---
## Upload Profile Photo
Endpoint : POST /me/photo

### Headers
Authorization : Bearer {access_token}
Content-Type : multipart/form-data

### Form Data
photo : file (jpg, jpeg, png, max 5 MB)

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Profile photo uploaded successfully",
  "data": {
    "photo_url": "https://api.example.com/uploads/profile/user-12.jpg"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "photo": [
      "Photo is required"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid File Type)
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
### Response Error (422 Unprocessable Entity - File Too Large)
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
