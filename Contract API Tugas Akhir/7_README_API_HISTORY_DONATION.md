# 7. History
## My Donation History
```
Endpoint : GET /history/my-donations?status={status}&page={page}
```
### Headers
```
Authorization : Bearer {access_token}
```
### Query Parameters
```
status : optional, enum = all | posted | waiting | claimed | completed | expired | cancelled
page   : optional, integer, default 1
```
### Possible Status:
```
all
posted
waiting
claimed
completed
expired
cancelled
```
### Example Request 
```
GET /history/my-donations?status=all&page=1
```
### Response Success (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 45,
      "food_name": "Ayam Bakar Sisa MBG",
      "date": "2026-03-31",
      "time": "14:30",
      "status": "posted",
      "claimed_by": {
        "id": 88,
        "full_name": "Budi"
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
### Response Error (422 Unprocessable Entity - Invalid Status)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "status": [
      "Status must be one of: all, posted, waiting, claimed, completed, expired, cancelled"
    ]
  }
}
```
### Response Error (401 Unathorized)
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
## My Claim History
```
Endpoint : GET /history/my-claims?status={status}&page={page}
```
### Headers
```
Authorization : Bearer {access_token}
```
### Queri Parameters
```
status : optional, enum = all | waiting_confirmation | confirmed | completed | cancelled
page   : optional, integer, default 1
```
### Possble Status
```
all
waiting_confirmation
confirmed
completed
cancelled
```
### Example Request
```
GET /history/my-claims?status=all&page=1
```
### Response Success (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "claim_id": 77,
      "donation": {
        "id": 45,
        "food_name": "Ayam Bakar Sisa MBG"
      },
      "status": "confirmed",
      "claimed_at": "2026-03-31T10:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 10,
    "total": 8
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
### Response Error (422 Unprocessable Entity - Invalid Status)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "status": [
      "Status must be one of: all, waiting_confirmation, confirmed, completed, cancelled"
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