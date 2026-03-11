# API Documentation - DT_Mobile Backend

This document contains the API endpoints and dummy data for testing the backend.

**Base URL:** `http://localhost:5000`

---

## 1. Authentication

### **A. Register User**
Creates a new user account.

*   **URL:** `/api/auth/register`
*   **Method:** `POST`
*   **Content-Type:** `application/json`

#### **Request Body (Dummy Data)**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "workEmail": "john.doe@example.com",
  "password": "Security@123",
  "mobileNumber": "+919876543210",
  "role": "Admin",
  "designation": "Software Engineer",
  "department": "Engineering"
}
```

#### **Success Response (201 Created)**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid-v4-string",
    "workEmail": "john.doe@example.com"
  }
}
```

#### **Error Response (400 Bad Request)**
```json
{
  "message": "User with this email already exists"
}
```

---

### **B. Login User**
Authenticates a user and returns a JWT token.

*   **URL:** `/api/auth/login`
*   **Method:** `POST`
*   **Content-Type:** `application/json`

#### **Request Body (Dummy Data)**
```json
{
  "workEmail": "john.doe@example.com",
  "password": "Security@123"
}
```

#### **Success Response (200 OK)**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-v4-string",
    "firstName": "John",
    "lastName": "Doe",
    "role": "Admin"
  }
}
```

#### **Error Response (401 Unauthorized)**
```json
{
  "message": "Invalid credentials"
}
```

---

## 2. Delegation Management

### **A. Create Delegation**
Creates a new delegation record.

*   **URL:** `/api/delegations`
*   **Method:** `POST`
*   **Content-Type:** `application/json`

#### **Request Body (Dummy Data)**
```json
{
  "delegationName": "Project Review",
  "description": "Review the final project milestones",
  "delegatorId": "user-uuid-1",
  "assingDoerId": "user-uuid-2",
  "department": "Engineering",
  "priority": "High",
  "dueDate": "2024-03-10",
  "evidenceRequired": true
}
```

#### **Success Response (201 Created)**
```json
{
  "success": true,
  "message": "Delegation created successfully",
  "data": { "id": "delegation-uuid", ... }
}
```

---

### **B. List Delegations**
Fetches all delegations.

*   **URL:** `/api/delegations`
*   **Method:** `GET`

#### **Success Response (200 OK)**
```json
{
  "success": true,
  "data": [ { "id": "delegation-uuid", "delegationName": "..." } ]
}
```

---

### **C. Get Delegation Details**
Fetches a single delegation with its revision and remark history.

*   **URL:** `/api/delegations/:id`
*   **Method:** `GET`

#### **Success Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "delegationName": "...",
    "revision_history": [],
    "remarks": []
  }
}
```

---

### **D. Update Delegation**
Updates a delegation. Logs a revision history entry if `status` or `dueDate` changes.

*   **URL:** `/api/delegations/:id`
*   **Method:** `PATCH`
*   **Content-Type:** `application/json`

#### **Request Body (Example)**
```json
{
  "status": "In Progress",
  "reason": "Starting the review process",
  "changedBy": "user-uuid-1"
}
```

---

### **E. Add Remark**
Adds a remark to a specific delegation.

*   **URL:** `/api/delegations/:id/remarks`
*   **Method:** `POST`
*   **Content-Type:** `application/json`

#### **Request Body**
```json
{
  "assignedUserId": "user-uuid-2",
  "remark": "I have started working on this task."
}
```

---

### **F. Delete Delegation**
Permanently removes a delegation record.

*   **URL:** `/api/delegations/:id`
*   **Method:** `DELETE`

---

## 💡 Testing Tips
- **Pre-requisite:** Ensure the server is running (`npm run dev`) and you have pushed the schema to Neon (`npm run db:push`).
- **Postman:** You can also import the `postman_collection.json` provided in the brain artifacts directory.
- **Environment:** If you change the port in `.env`, update the Base URL accordingly.
