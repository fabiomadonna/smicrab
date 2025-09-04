# SMICRAB Analysis API Documentation

## Overview

The SMICRAB Analysis API provides comprehensive functionality for managing statistical analysis sessions, including data exploration, model estimation, validation, and risk mapping. All endpoints require authentication via JWT tokens.

## Authentication

All analysis endpoints require authentication. Include the JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Analysis Session Management

### 1. Create Analysis
**Endpoint:** `POST /api/v1/analysis/create`
**Authentication:** Required

**Request:**
```json
{
  "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "45430d77-8720-4de5-9040-f9969da43ac5",
    "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb",
    "status": "pending",
    "current_module": "load_module",
    "model_config_data": null,
    "model_type": null,
    "coordinates": null,
    "is_dynamic_output": false,
    "analysis_date": null,
    "expires_at": null,
    "created_at": "2025-07-05T12:58:07.645345",
    "updated_at": "2025-07-05T12:58:07.645345"
  },
  "message": "analysis created successfully"
}
```

### 2. Get User Analyses
**Endpoint:** `GET /api/v1/analysis/user/{user_id}`
**Authentication:** Required (User can only access their own analyses)

**Response:**
```json
{
  "success": true,
  "data": {
    "analyses": [
      {
        "id": "cb7fdf53-0c87-43ba-a296-fb77b193ebed",
        "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb",
        "status": "pending",
        "current_module": "load_module",
        "model_config_data": null,
        "model_type": null,
        "coordinates": null,
        "is_dynamic_output": false,
        "analysis_date": null,
        "expires_at": null,
        "created_at": "2025-07-02T23:20:03.343541",
        "updated_at": "2025-07-02T23:20:03.343541"
      },
      {
        "id": "9da4a613-9b6d-47d4-a81c-ad1782380799",
        "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb",
        "status": "completed",
        "current_module": "load_module",
        "model_config_data": {
          "summary_stat": "mean",
          "bool_trend": true,
          "model_type": "Model4_UHI",
          "bool_update": true,
          "user_coeff_choice": 1.0,
          "user_latitude_choice": 37.1,
          "user_longitude_choice": 17.2
        },
        "model_type": "Model4_UHI",
        "coordinates": {
          "latitude": 37.1,
          "longitude": 17.2
        },
        "is_dynamic_output": true,
        "analysis_date": "2025-07-03T10:33:57.744994",
        "expires_at": null,
        "created_at": "2025-07-03T10:33:12.573034",
        "updated_at": "2025-07-03T10:33:12.573034"
      }
    ]
  },
  "message": "user analyses retrieved successfully"
}
```

### 3. Save Analysis Parameters
**Endpoint:** `POST /api/v1/analysis/parameters`
**Authentication:** Required

**Request:**
```json
{
  "analysis_id": "45430d77-8720-4de5-9040-f9969da43ac5",
  "model_type": "Model6_HSDPD_user",
  "bool_update": true,
  "bool_trend": true,
  "summary_stat": "mean",
  "user_longitude_choice": 11.2,
  "user_latitude_choice": 45.1,
  "user_coeff_choice": 1.0,
  "bool_dynamic": true,
  "endogenous_variable": "mean_air_temperature_adjusted",
  "covariate_variables": ["mean_relative_humidity_adjusted", "black_sky_albedo_all_mean"],
  "covariate_legs": [1, 2],
  "user_date_choice": "2011-01-01",
  "vec_options": {
    "groups": 1,
    "px_core": 1,
    "px_neighbors": 3,
    "t_frequency": 12,
    "na_rm": true,
    "NAcovs": "pairwise.complete.obs"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "45430d77-8720-4de5-9040-f9969da43ac5",
    "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb",
    "status": "configured",
    "current_module": "load_module",
    "model_config_data": {
      "summary_stat": "mean",
      "bool_trend": true,
      "model_type": "Model6_HSDPD_user",
      "bool_update": true,
      "vec_options": {
        "na_rm": true,
        "NAcovs": "pairwise.complete.obs",
        "groups": 1,
        "px_core": 1,
        "t_frequency": 12,
        "px_neighbors": 3
      },
      "bool_dynamic": true,
      "user_date_choice": "2011-01-01",
      "user_coeff_choice": 1.0,
      "covariate_variables": [
        "mean_relative_humidity_adjusted",
        "black_sky_albedo_all_mean"
      ],
      "covariate_legs": [1, 2],
      "endogenous_variable": "mean_air_temperature_adjusted",
      "user_latitude_choice": 45.1,
      "user_longitude_choice": 11.2
    },
    "model_type": "Model6_HSDPD_user",
    "coordinates": {
      "latitude": 45.1,
      "longitude": 11.2
    },
    "is_dynamic_output": true,
    "analysis_date": "2011-01-01T00:00:00",
    "expires_at": null,
    "created_at": "2025-07-05T12:58:07.645345",
    "updated_at": "2025-07-05T12:58:07.645345"
  },
  "message": "analysis parameters saved successfully"
}
```

### 4. Run Analysis
**Endpoint:** `POST /api/v1/analysis/run`
**Authentication:** Required

**Request:**
```json
{
  "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "status": "in_progress",
    "model_type": "Model6_HSDPD_user",
    "execution_started": true,
    "message": "Analysis execution started with Model6_HSDPD_user"
  },
  "message": "analysis execution started successfully"
}
```

### 5. Get Analysis Status
**Endpoint:** `GET /api/v1/analysis/{analysis_id}/status`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "user_id": "305a9694-3ed2-4589-b59e-b63a210103cb",
    "status": "in_progress",
    "current_module": "describe_module",
    "model_config_data": {...},
    "model_type": "Model6_HSDPD_user",
    "coordinates": {...},
    "is_dynamic_output": true,
    "analysis_date": "2011-01-01T00:00:00",
    "expires_at": null,
    "created_at": "2025-07-05T12:58:07.645345",
    "updated_at": "2025-07-05T12:58:07.645345"
  },
  "message": "analysis status retrieved successfully"
}
```

### 6. Download Analysis Files
**Endpoint:** `GET /api/v1/analysis/{analysis_id}/download/{file_type}/{file_name}`
**Authentication:** Required

**File Types:** `plots`, `tables`, `maps`, `rdata`

**Example:**
```
GET /api/v1/analysis/45430d77-8720-4de5-9040-f9969da43ac5/download/plots/temperature_plot.png
```

### 7. Delete Analysis
**Endpoint:** `DELETE /api/v1/analysis/{analysis_id}`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "45430d77-8720-4de5-9040-f9969da43ac5",
    "deleted": true,
    "container_stopped": false,
    "message": "Analysis and associated resources deleted successfully"
  },
  "message": "analysis deleted successfully"
}
```

## Container Management

### 8. Get Running Analyses
**Endpoint:** `GET /api/v1/analysis/running`
**Authentication:** Not Required

**Response:**
```json
{
  "success": true,
  "data": {
    "running_analyses": [
      {
        "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
        "container_id": "abc123def456",
        "status": "running",
        "started_at": "2025-07-05T12:58:07.645345"
      }
    ],
    "count": 1
  },
  "message": "running analyses retrieved successfully"
}
```

### 9. Get Container Status
**Endpoint:** `GET /api/v1/analysis/container/{analysis_id}/status`
**Authentication:** Not Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "container_id": "abc123def456",
    "status": "running",
    "cpu_usage": "15.2%",
    "memory_usage": "512MB",
    "started_at": "2025-07-05T12:58:07.645345"
  },
  "message": "container status retrieved successfully"
}
```

### 10. Stop Analysis
**Endpoint:** `POST /api/v1/analysis/stop/{analysis_id}`
**Authentication:** Not Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "stopped": true
  },
  "message": "analysis stopped successfully"
}
```

## Module Outputs

### 11. Get Describe Module Outputs
**Endpoint:** `GET /api/v1/describe_module/outputs?analysis_id={analysis_id}`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "module": "describe_module",
    "outputs": {
      "plots": [
        {
          "name": "temperature_distribution.png",
          "path": "/analysis/f22926f0-6551-492a-91d0-b3145a3f415b/plots/temperature_distribution.png",
          "type": "histogram"
        }
      ],
      "tables": [
        {
          "name": "summary_statistics.csv",
          "path": "/analysis/f22926f0-6551-492a-91d0-b3145a3f415b/tables/summary_statistics.csv",
          "type": "csv"
        }
      ]
    }
  },
  "message": "Describe module outputs retrieved successfully"
}
```

### 12. Get Estimate Module Outputs
**Endpoint:** `GET /api/v1/estimate_module/outputs?analysis_id={analysis_id}`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "module": "estimate_module",
    "outputs": {
      "coefficient_plots": [...],
      "coefficient_tables": [...],
      "time_series_plots": [...],
      "csv_downloads": [...]
    }
  },
  "message": "Estimate module outputs retrieved successfully"
}
```

### 13. Get Validate Module Outputs
**Endpoint:** `GET /api/v1/validate_module/outputs?analysis_id={analysis_id}`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "module": "validate_module",
    "outputs": {
      "residual_analysis": [...],
      "diagnostic_tests": [...],
      "model_performance": [...],
      "goodness_of_fit": [...]
    }
  },
  "message": "Validate module outputs retrieved successfully"
}
```

### 14. Get Risk Map Module Outputs
**Endpoint:** `GET /api/v1/risk_map_module/outputs?analysis_id={analysis_id}`
**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "module": "risk_map_module",
    "outputs": {
      "risk_maps": [...],
      "threshold_analysis": [...],
      "spatial_visualizations": [...]
    }
  },
  "message": "Risk map module outputs retrieved successfully"
}
```

## Webhook Endpoints

### 15. Analysis Completion Webhook
**Endpoint:** `POST /api/v1/analysis/webhook/completion`
**Authentication:** Not Required (Internal use)

**Request:**
```json
{
  "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
  "status": "module_completed",
  "current_module": "describe_module",
  "next_module": "estimate_module"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "Module completed successfully",
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "updated_status": "in_progress"
  },
  "message": "analysis completion webhook processed successfully"
}
```

## Data Models

### Analysis Status Enum
- `pending`: Analysis created but not configured
- `configured`: Analysis parameters saved
- `in_progress`: Analysis is running
- `completed`: Analysis finished successfully
- `error`: Analysis failed

### Model Types
- `Model1_Simple`: Simple linear model
- `Model2_Autoregressive`: Autoregressive model
- `Model3_MB_User`: User-defined model
- `Model4_UHI`: Urban Heat Island model
- `Model5_RAB`: Regional analysis model
- `Model6_HSDPD_user`: High-dimensional spatial panel data model

### Analysis Variables
- `maximum_air_temperature_adjusted`
- `mean_air_temperature_adjusted`
- `minimum_air_temperature_adjusted`
- `mean_relative_humidity_adjusted`
- `accumulated_precipitation_adjusted`
- `mean_wind_speed_adjusted`
- `black_sky_albedo_all_mean`
- `LST_h18`

### Summary Statistics
- `mean`
- `standard_deviation`
- `min`
- `max`
- `median`
- `range`
- `count.NAs`

## Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authorization header missing",
  "data": null
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "You can only access your own analyses",
  "data": null
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Analysis not found",
  "data": null
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error occurred",
  "data": null
}
```

## Usage Examples

### Complete Analysis Workflow

1. **Create Analysis**
```bash
curl -X POST "http://localhost:8000/api/v1/analysis/create" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "305a9694-3ed2-4589-b59e-b63a210103cb"}'
```

2. **Save Parameters**
```bash
curl -X POST "http://localhost:8000/api/v1/analysis/parameters" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "analysis_id": "45430d77-8720-4de5-9040-f9969da43ac5",
    "model_type": "Model6_HSDPD_user",
    "summary_stat": "mean",
    "user_longitude_choice": 11.2,
    "user_latitude_choice": 45.1,
    "endogenous_variable": "mean_air_temperature_adjusted",
    "covariate_variables": ["mean_relative_humidity_adjusted"]
  }'
```

3. **Run Analysis**
```bash
curl -X POST "http://localhost:8000/api/v1/analysis/run" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"analysis_id": "45430d77-8720-4de5-9040-f9969da43ac5"}'
```

4. **Monitor Status**
```bash
curl -X GET "http://localhost:8000/api/v1/analysis/45430d77-8720-4de5-9040-f9969da43ac5/status" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

5. **Get Results**
```bash
curl -X GET "http://localhost:8000/api/v1/describe_module/outputs?analysis_id=45430d77-8720-4de5-9040-f9969da43ac5" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
```