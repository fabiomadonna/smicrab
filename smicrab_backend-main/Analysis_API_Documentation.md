# Analysis API Documentation

## Overview
SMICRAB (Spatial-Temporal Model for Integrated Climate Risk Assessment and Biodiversity) API provides comprehensive endpoints for managing analysis sessions, configuring models, and executing spatial-temporal data analysis.


## Available Modules
- **ANALYSIS** - `/analysis/` (Session management, model configuration, execution)
- **USER** - `/user/` (User management)

## Common Response Format

All API responses follow this structure:
```json
{
  "success": boolean,
  "message": string,
  "data": object
}
```

## 1. ANALYSIS MODULE (`/analysis/`)

### 1.1 Create Analysis
**Endpoint:** `POST /analysis/create`
**Description:** Create a new analysis session

**Request Body:**
```json
{
  "user_id": "string (required) - User identifier"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "analysis created successfully",
  "data": {
    "id": "UUID - Analysis ID",
    "user_id": "UUID - User ID",
    "status": "AnalyzeStatus enum",
    "current_module": "ModuleName enum",
    "model_config_data": "Optional configuration data",
    "model_type": "Optional ModelType enum",
    "coordinates": "Optional geographic coordinates",
    "is_dynamic_output": "Optional boolean",
    "analysis_date": "Optional ISO datetime",
    "expires_at": "Optional ISO datetime",
    "created_at": "ISO datetime",
    "updated_at": "ISO datetime"
  },
  "code": 201
}
```

### 1.2 Get User Analyses
**Endpoint:** `GET /analysis/user/{user_id}`
**Description:** Retrieve all analyses for a specific user
**Parameters:**
- `user_id`: user identifier
**Response (200):**
```json
{
  "success": true,
  "message": "user analyses retrieved successfully",
  "data": {
    "analyses": [
      {
        "id": "UUID - Analysis ID",
        "user_id": "UUID - User ID",
        "status": "AnalyzeStatus enum",
        "current_module": "ModuleName enum",
        "model_config_data": "Optional configuration data",
        "model_type": "Optional ModelType enum",
        "coordinates": "Optional geographic coordinates",
        "is_dynamic_output": "Optional boolean",
        "analysis_date": "Optional ISO datetime",
        "expires_at": "Optional ISO datetime",
        "created_at": "ISO datetime",
        "updated_at": "ISO datetime"
      }
    ]
  },
  "code": 200
}
```

### 1.3 Save Analysis Parameters
**Endpoint:** `POST /analysis/parameters`
**Description:** Save specific analysis parameters

**Request Body:**
```json
{
  "analysis_id": "string (required) - Analysis identifier",
  "model_type": "ModelType enum (required)",
  "bool_update": "boolean (optional, default: false)",
  "bool_trend": "boolean (optional, default: false)",
  "summary_stat": "SummaryStat enum (required) - Summary statistic method",
  "user_longitude_choice": "number (required)",
  "user_latitude_choice": "number (required)",
  "user_coeff_choice": "number (optional, default: 1.0)",
  "bool_dynamic": "boolean (optional, default: false)",
  "endogenous_variable": "AnalysisVariable enum (required)",
  "covariate_variables": "array of AnalysisVariable enum (optional)",
  "user_date_choice": "Optional date string",
  "vec_options": {
    "groups": "number (optional, default: 1)",
    "px_core": "number (optional, default: 1)",
    "px_neighbors": "number (optional, default: 3)",
    "t_frequency": "number (optional, default: 12)",
    "na_rm": "boolean (optional, default: true)",
    "NAcovs": "string (optional, default: 'pairwise.complete.obs')"
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "analysis parameters saved successfully",
  "data": {
    "analysis_id": "string",
    "updated_parameters": {
      "model_type": "ModelType enum",
      "endogenous_variable": "string",
      "covariate_variables": "array of strings"
    }
  },
  "code": 200
}
```


### 1.4 Run Analysis
**Endpoint:** `POST /analysis/run`
**Description:** Initiate analysis run with specific parameters

**Request Body:**
```json
{
  "analysis_id": "string (required) - Analysis identifier",
  "model_type": "ModelType enum (required)"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Analysis run initiated",
  "data": {
    "analysis_id": "string",
    "status": "AnalyzeStatus enum",
    "model_type": "ModelType enum",
    "execution_started": true,
    "message": "Analysis execution in progress"
  },
  "code": 200
}
```

### 1.5 Analysis Completion Webhook (Not usable in Frontend)
**Endpoint:** `POST /analysis/webhook/completion`
**Description:** Webhook endpoint for analysis completion notification

**Request Body:**
```json
{
  "analysis_id": "string (required) - Analysis identifier",
  "status": "string (required) - 'done', 'error', or 'timeout'",
  "error_message": "Optional error message if status is error"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Webhook processed successfully",
  "data": {
    "success": true,
    "message": "Analysis completion processed",
    "analysis_id": "string",
    "updated_status": "AnalyzeStatus enum"
  },
  "code": 200
}
```
