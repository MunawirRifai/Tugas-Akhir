# 8. Notification
## Get Notifications
```
Endpoint : GET /notifications?page={page}
```
### Headers
```
Authorizations : Bearer {access_token}
```
### Query Parameters
```
page : optional, integer, default 1
```
### Response Success (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Donation Claimed",
      "body": "Your donation has been claimed by Budi",
      "is_read": false,
      "created_at": "2026-03-31T10:10:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 5,
    "unread_count": 2
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
    "per_page": 20,
    "total": 0,
    "unread_count": 0
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

## Mark Notification as Read
```
Endpoint : PATCH /notifications/{id}/read
```
### Headers
```
Authorization : Bearer {access_token}
```
### Response Success (200 OK)
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```
### Response Error (404 Not Found)
```json
{
  "success": false,
  "message": "Notification not found"
}
```
### Response Error (403 Forbidden)
```json
{
  "success": false,
  "message": "You are not allowed to access this notification"
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