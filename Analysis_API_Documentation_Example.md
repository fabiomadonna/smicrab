# Analysis API Documentation Examples

## 1. Create Analysis
**Endpoint:** `POST /analysis/create`
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

## 1.2 Get User Analyses
**Endpoint:** `GET /analysis/user/{user_id}`
**Parameters:**
- user_id: "305a9694-3ed2-4589-b59e-b63a210103cb"

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
          "stat": "mean",
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

## 1.3 Save Analysis Parameters
**Endpoint:** `POST /analysis/parameters`
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
	"user_date_choice": "2011-01-01",
	"vec_options": {
    "groups": 1,
    "px.core": 1,
    "px.neighbors": 3,
    "t_frequency": 12,
    "na.rm": true,
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
    "status": "pending",
    "current_module": "load_module",
    "model_config_data": {
      "summary_stat": "mean",
      "bool_trend": true,
      "model_type": "Model6_HSDPD_user",
      "analysis_id": "45430d77-8720-4de5-9040-f9969da43ac5",
      "bool_update": true,
      "vec.options": {
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

## 1.4 Run Analysis
**Endpoint:** `POST /analysis/run`
**Request:**
```json
{
    "analysis_id": "f22926f0-6551-492a-91d0-b3145a3f415b",
    "model_type": "Model6_HSDPD_user"
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