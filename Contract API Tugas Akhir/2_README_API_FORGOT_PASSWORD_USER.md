# 2. Forgot Password
## Send Reset Via email
Endpoint : POST /auth/forgot-password/email

### Request 
```json
{
    "email": "muna@example.com"
}
```

### Validation Rules
* email : requred, valid email format

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Reset code sent to email",
  "data": {
    "identifier": "muna@example.com"
  }
}
```
### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": [
      "Email is required"
    ]
  }
}
```
### Response Error (404 Not Found - Email Not Registered)
```json
{
  "success": false,
  "message": "Email not registered",
  "errors": {
    "email": [
      "No account found with this email"
    ]
  }
}
```

## Send Reset Via Phone
Endpoint : POST /auth/forgot-password/phone

### Request 
```json
{
    "phone": "081234567890"
}
```

### Validation Rules 
* phone : required, valid phone number format

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Reset code sent to phone",
  "data": {
    "identifier": "081234567890"
  }
}
```
### Response Error (422 Unprocessable Entity - Validationn Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "phone": [
      "Phone is required"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid Phone Format)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "phone": [
      "Phone number format is invalid"
    ]
  }
}
```

### Response Error (404 Not Found - Phone Not Registered)
```json
{
  "success": false,
  "message": "Phone number not registered",
  "errors": {
    "phone": [
      "No account found with this phone number"
    ]
  }
}
```

## Verify Reset Code
Endpoint : POST /auth/forgot-password/verify

### Request 
```json
{
  "identifier": "muna@example.com",
  "code": "1234"
}
```
### Validation Rules
* identifier : required
* code : required, 4 digits

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Code valid",
  "data": {
    "reset_token": "reset_password_token"
  }
}
```

### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "identifier": [
      "Identifier is required"
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
### Response Error (401 Unauthorized - Invalid Reset Code)
```json
{
  "success": false,
  "message": "Invalid reset code",
  "errors": {
    "code": [
      "Reset code is incorrect"
    ]
  }
}
```
### Response Error (410 Gone - Reset Code Expired)
```json
{
  "success": false,
  "message": "Reset code expired",
  "errors": {
    "code": [
      "Reset code has expired"
    ]
  }
}
```

## Create New Password 
Endpoint : POST /auth/reset-password

### Request
```json
{
  "reset_token": "reset_password_token",
  "new_password": "NewPassword123"
}
```

### Validation Rules
* reset_token : required
* new_password : required, minimun 6 characters

### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Password has been reset successfully"
}
```

### Response Error (422 Unprocessable Entity - Validation Error)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "reset_token": [
      "Reset token is required"
    ],
    "new_password": [
      "New password is required"
    ]
  }
}
```
### Response Error (422 Unprocessable Entity - Invalid Password)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "new_password": [
      "Password must be at least 6 characters"
    ]
  }
}
```
### Response Error (401 Unauthorized - Invalid Reset Token)
```json
{
  "success": false,
  "message": "Invalid reset token",
  "errors": {
    "reset_token": [
      "Reset token is invalid"
    ]
  }
}
```
### Response Error (410 Gone - Reset Token Expired)
```json
{
  "success": false,
  "message": "Reset token expired",
  "errors": {
    "reset_token": [
      "Reset token has expired"
    ]
  }
}
```
### Response Error (409 Conflict - Same Password)
```json
{
  "success": false,
  "message": "New password cannot be the same as the old password",
  "errors": {
    "new_password": [
      "Please use a different password"
    ]
  }
}
```