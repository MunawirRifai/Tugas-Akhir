# API Contract – Food Donation Mobile App

## Base URL

```
/api/v1
```

---

## Standard Response Format

### Success

```json
{
  "success": true,
  "message": "Login successful",
  "data": {}
}
```

### Error

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["Email is required"]
  }
}
```

---

# 1. Authentication

* ## Register

Endpoint : POST /auth/register

### Request

```json
{
  "full_name": "Muna Verify",
  "phone": "081234567890",
  "email": "muna@example.com",
  "password": "Password123"
}
```

### Validation Rules

* full_name : required
* phone : required, unique, valid phone number format
* email : required, valid email format, unique
* password : required, min 6 karakter

### Response Success (201)

```json
{
  "success": true,
  "message": "Verification code sent",
  "data": {
    "user_id": 12,
    "verification_token": "temp_register_token"
  }
}
```

### Response Error (422 Unprocessable Entity - Validation Error)

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "full_name": ["Full name is required"],
    "phone": ["Phone is required"],
    "email": ["Email is required"],
    "password": ["Password is required"]
  }
}
```

### Response Error (422 Email & Password not Valid - Validation Error)

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": [
      "Email format is invalid"
    ],
    "password": [
      "Password must be at least 6 characters"
    ]
  }
}
```

### Response Error (409 Conflict - Email Already Registered)
```json
{
  "success": false,
  "message": "Email already registered",
  "errors": {
    "email": [
      "Email already registered"
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
      "Phone already registered"
    ]
  }
}
```
---
* ## Verify Registration Code

Endpoint : POST /auth/verify-register

### Request
```json
{
  "verification_token": "temp_register_token",
  "code": "1234"
}
```

### Validation Rules 
* verification_token : required
* code : required, 4 digits

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Account verified",
  "data": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```

### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "verification_token": [
      "Verification token is required"
    ],
    "code": [
      "Code is required"
    ]
  }
}
```

### Response Error (422 Unprocessable Entity - Invalid Code Format)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "code": [
      "Code must be 4 digits"
    ]
  }
}
```

### Response Error (401 Unauthorized - Invalid Verification Code)
```json
{
  "success": false,
  "message": "Invalid verification code",
  "errors": {
    "code": [
      "Verification code is incorrect"
    ]
  }
}
```

### Response Error (401 Unauthorized - Invalid Verification Token)
```json
{
  "success": false,
  "message": "Invalid verification token",
  "errors": {
    "verification_token": [
      "Verification token is invalid or expired"
    ]
  }
}
```

### Response Error (410 Gone - Verification Code Expired)
```json
HTTP/1.1 410 Gone

{
  "success": false,
  "message": "Verification code expired",
  "errors": {
    "code": [
      "Verification code has expired"
    ]
  }
}
```

### Response Error (409 Conflict - Account Already Verified)
```json
{
  "success": false,
  "message": "Account already verified"
}
```


---
* ## Login
Endpoint : POST /auth/login

### Request 
```json
{
  "email": "muna@example.com",
  "password": "Password123"
}
```

### Validation Rules 
* email : required, valid email format
* password : required

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 12,
      "full_name": "Muna Verify",
      "email": "muna@example.com",
      "phone": "081234567890",
      "photo_url": null
    },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token"
  }
}
```
## Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": [
      "Email is required"
    ],
    "password": [
      "Password is required"
    ]
  }
}
```

## Response Error (422 Unprocessable Entity - Invalid Email Format)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": [
      "Email format is invalid"
    ]
  }
}
```

## Response Error (401 Unathorized - Invalid Credentials)
```json
{
  "success": false,
  "message": "Invalid email or password",
  "errors": {
    "email": [
      "Email or password is incorrect"
    ]
  }
}
```
## Response Error (403 Forbidden - Account Not Verified)
```json
{
  "success": false,
  "message": "Account is not verified",
  "errors": {
    "email": [
      "Please verify your account before login"
    ]
  }
}
```
## Response Error (403 Forbidden - Account Suspended)
```json
{
  "success": false,
  "message": "Account has been suspended",
  "errors": {
    "account": [
      "Your account has been suspended. Please contact support"
    ]
  }
}
```
## Response Error (429 Too Many Request - Too Many Login Attemps)
```json
{
  "success": false,
  "message": "Too many login attempts",
  "errors": {
    "login": [
      "Please try again in 15 minutes"
    ]
  }
}
```

---
* ## Refresh Token
Endpoint : POST /auth/refresh

### Request 
```json
{
  "refresh_token": "refresh_token"
}
```
### Validation Rules
* refresh_token : required

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "access_token": "new_access_token",
    "refresh_token": "new_refresh_token"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "refresh_token": [
      "Refresh token is required"
    ]
  }
}
```
### Response Error (401 Unathorized - Invalid Refresh Token)
```json
{
  "success": false,
  "message": "Invalid refresh token",
  "errors": {
    "refresh_token": [
      "Refresh token is invalid"
    ]
  }
}
```
### Response Error (410 Gone - Refresh Token Expired)
```json
{
  "success": false,
  "message": "Refresh token expired",
  "errors": {
    "refresh_token": [
      "Refresh token has expired"
    ]
  }
}
```
### Response Error (401 Unauthorized - Refresh Token Revoked)
```json
{
  "success": false,
  "message": "Refresh token has been revoked",
  "errors": {
    "refresh_token": [
      "Please login again"
    ]
  }
}
```
---
* ## Logout
Endpoint : POST /auth/logout

### Headers 
Authorization: Bearer {access_token}

### Request
```json
{}
```

### Validation Rules
* Authorization header : required
* refresh_token : optional/required

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Logout successful"
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
### Response Error (401 Unauthorized - Invalid Refresh Token)
```json
{
  "success": false,
  "message": "Invalid refresh token",
  "errors": {
    "refresh_token": [
      "Refresh token is invalid"
    ]
  }
}
```
---
