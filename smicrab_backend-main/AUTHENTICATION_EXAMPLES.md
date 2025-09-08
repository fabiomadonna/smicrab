# SMICRAB Authentication System

## Overview

The SMICRAB backend implements a comprehensive JWT-based authentication system with the following features:

- User registration and login
- JWT access and refresh tokens
- Password hashing with bcrypt
- Email and password validation
- Protected API endpoints
- Rate limiting
- User profile management

## Authentication Endpoints

### 1. User Registration

**Endpoint:** `POST /api/v1/user/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Successful Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Failed Response Examples:**

**Invalid Email (400):**
```json
{
  "success": false,
  "message": "Invalid email format",
  "data": null
}
```

**Weak Password (400):**
```json
{
  "success": false,
  "message": "Password must be at least 8 characters long",
  "data": null
}
```

**User Already Exists (400):**
```json
{
  "success": false,
  "message": "User with this email already exists",
  "data": null
}
```

### 2. User Login

**Endpoint:** `POST /api/v1/user/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Successful Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com"
  }
}
```

**Failed Response Examples:**

**Invalid Credentials (401):**
```json
{
  "success": false,
  "message": "Incorrect email or password",
  "data": null
}
```

### 3. Token Refresh

**Endpoint:** `POST /api/v1/user/refresh`

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Successful Response (200):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  }}
```

**Failed Response Examples:**

**Invalid Refresh Token (401):**
```json
{
  "success": false,
  "message": "Could not validate credentials",
  "data": null
}
```

### 4. Get User Profile

**Endpoint:** `GET /api/v1/user/me`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Successful Response (200):**
```json
{
  "success": true,
  "message": "User profile retrieved successfully",
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**Failed Response Examples:**

**Missing Token (401):**
```json
{
  "success": false,
  "message": "Authorization header missing",
  "data": null
}
```

**Invalid Token (401):**
```json
{
  "success": false,
  "message": "Could not validate credentials",
  "data": null
}
```

## Protected Endpoints Examples

### 1. Create Analysis (Protected)

**Endpoint:** `POST /api/v1/analysis/create`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Failed Response Examples:**

**Without Authentication (401):**
```json
{
  "success": false,
  "message": "Authorization header missing",
  "data": null
}
```

### 2. Get User Analyses (Protected)

**Endpoint:** `GET /api/v1/analysis/user/{user_id}`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Failed Response Examples:**

**Accessing Another User's Analyses (403):**
```json
{
  "success": false,
  "message": "You can only access your own analyses",
  "data": null
}
```

**Analysis Not Found (404):**
```json
{
  "success": false,
  "message": "Analysis not found",
  "data": null
}
```

**Analysis Ownership Verification Failed (403):**
```json
{
  "success": false,
  "message": "Analysis does not belong to user",
  "data": null
}
```

### 3. Get Module Outputs (Protected)

**Endpoint:** `GET /api/v1/describe_module/outputs?analysis_id={analysis_id}`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```


## Public Endpoints (No Authentication Required)

### 1. Get All Datasets

**Endpoint:** `GET /api/v1/datasets/`


## Authentication Flow

### 1. Registration Flow
1. User submits registration with email and password
2. System validates email format and password strength
3. System checks if user already exists
4. Password is hashed using bcrypt
5. User is created in database
6. Success response is returned

### 2. Login Flow
1. User submits login credentials
2. System finds user by email
3. System verifies password hash
4. JWT access and refresh tokens are generated
5. Tokens are returned to user

### 3. Protected Resource Access Flow
1. User includes JWT token in Authorization header
2. Middleware validates token
3. User information is extracted from token
4. Request proceeds to endpoint handler
5. Endpoint can access current user via dependency injection

### 4. Token Refresh Flow
1. User submits refresh token
2. System validates refresh token
3. New access token is generated
4. New access token is returned

## Security Features

### 1. Password Security
- Passwords are hashed using bcrypt with salt
- Minimum 8 characters required
- Must contain uppercase, lowercase, and digit
- Passwords are never stored in plain text

### 2. JWT Security
- Access tokens expire after 30 minutes
- Refresh tokens expire after 7 days
- Tokens are signed with HMAC-SHA256
- Token payload includes user ID and email

### 3. Rate Limiting
- 60 requests per minute per IP address
- Prevents brute force attacks
- Configurable limits

### 4. Input Validation
- Email format validation using Pydantic
- Password strength validation
- Request body validation with Pydantic models

### 5. Error Handling
- Consistent error response format
- No sensitive information in error messages
- Proper HTTP status codes

## Best Practices

### 1. Token Management
- Store access tokens in memory (not localStorage)
- Store refresh tokens securely
- Implement automatic token refresh
- Clear tokens on logout

### 2. Error Handling
- Handle 401 errors by redirecting to login
- Handle 403 errors by showing appropriate message
- Implement retry logic for network errors

### 3. Security Headers
- Always include Authorization header for protected requests
- Use HTTPS in production
- Implement proper CORS configuration

### 4. User Experience
- Show loading states during authentication
- Provide clear error messages
- Implement remember me functionality
- Auto-logout on token expiration

## Configuration

### Environment Variables
```bash
# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key-change-this-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7


### Production Considerations
1. Use strong, unique secret keys
2. Store secrets in environment variables
3. Use HTTPS in production
4. Implement proper logging
5. Monitor authentication attempts
6. Regular security audits
7. Keep dependencies updated

## Testing Authentication

### 1. Registration Test
```bash
curl -X POST "http://localhost:8000/api/v1/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123"
  }'
```

### 2. Login Test
```bash
curl -X POST "http://localhost:8000/api/v1/user/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123"
  }'
```

### 3. Protected Endpoint Test
```bash
curl -X GET "http://localhost:8000/api/v1/user/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Token Refresh Test
```bash
curl -X POST "http://localhost:8000/api/v1/user/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check if Authorization header is present
   - Verify token format (Bearer <token>)
   - Check if token is expired
   - Ensure token is valid

2. **403 Forbidden**
   - Verify user has permission to access resource
   - Check if user is accessing their own data
   - Ensure proper user context

3. **400 Bad Request**
   - Check request body format
   - Verify email format
   - Ensure password meets requirements

4. **409 Conflict**
   - User already exists with that email
   - Use different email or login instead

### Debug Tips

1. Check server logs for authentication errors
2. Verify JWT token payload using jwt.io
3. Test endpoints with Postman or curl
4. Check database for user records
5. Verify environment variables are set correctly 