# 6. Claim Donation
## Claim a Donation
```
Endpoint : POST /donations/{id}/claim
```
### Headers 
```
Authorization : Bearer {access_token}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Donation claimed",
  "data": {
    "claim_id": 77,
    "status": "waiting_confirmation"
  }
}
```
### Reponse Error (401 Unauthorized)
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
### Reponse Error (403 Unauthorized)
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
### Reponse Error (404 Not Found)
```json
{
  "success": false,
  "message": "Donation not found"
}
```
### Reponse Error (409 Conflict - Already Claimed)
```json
{
  "success": false,
  "message": "Donation has already been claimed",
  "errors": {
    "status": [
      "Donation status is no longer posted"
    ]
  }
}
```
### Reponse Error (410 Gone - Donation Expired)
```json
{
  "success": false,
  "message": "Donation has expired"
}
```

## Cancel Claim
```
Endpoint : POST /claims/{id}/cancel
```
### Headers
```
Authorization: Bearer {access_token}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Claim cancelled successfully"
}
```
### Response Error (403 forbidden)
```json
{
  "success": false,
  "message": "You are not allowed to cancel this claim"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Claim not found"
}
```
### Response Error (403 Conflict - Claim Already Confirmed)
```json
{
  "success": false,
  "message": "Claim can no longer be cancelled",
  "errors": {
    "status": [
      "Claim has already been confirmed"
    ]
  }
}
```
## Confirm Claim by Owner
```
Endpoint : POST /claims/{id}/confirm
```
### Headers
```
Authentication: Bearer {access_token}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Claim confirmed",
  "data": {
    "claim_id": 77,
    "status": "confirmed"
  }
}
```
### Response Error (403 Forbidden - Not Donation Owner)
```json
{
  "success": false,
  "message": "You are not allowed to confirm this claim"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Claim not found"
}
```
### Response Error (409 Conflict - Invalid Status)
```json
{
  "success": false,
  "message": "Claim cannot be confirmed",
  "errors": {
    "status": [
      "Claim is not waiting for confirmation"
    ]
  }
}
```

## Complete Donation 
```
Endpoint : POST /claims/{id}/complete
```
### Headers
```
Authorization: Bearer {access_token}    
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Donation completed",
  "data": {
    "claim_id": 77,
    "status": "completed"
  }
}
```
### Response Error (403 Forbidden)
```json
{
  "success": false,
  "message": "You are not allowed to complete this donation"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Claim not found"
}
```
### Response Error (409 Conflict)
```json
{
  "success": false,
  "message": "Donation cannot be completed",
  "errors": {
    "status": [
      "Claim has not been confirmed yet"
    ]
  }
}
```