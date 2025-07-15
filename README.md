# SMICRAB Backend

## Project Overview

SMICRAB (Spatial Modeling and Integrated Computational Risk Assessment Backend) is a sophisticated backend application designed for comprehensive spatio-temporal modeling and climate risk assessment. The system integrates Python FastAPI with R statistical computing to provide advanced analytical capabilities for climate data analysis.

## Architecture

The backend follows a modular, domain-driven architecture with the following key components:

### Core Modules

1. **Load Module**: Dataset selection, preprocessing, and configuration
2. **Describe Module**: Exploratory data analysis and statistical summaries
3. **Estimate Module**: Statistical modeling and parameter estimation
4. **Validate Module**: Model validation and diagnostic testing
5. **Risk Map Module**: Spatial risk mapping and visualization

### Technology Stack

* **Backend Framework**: FastAPI 0.115.5
* **Database**: PostgreSQL 15 with async support
* **ORM**: SQLAlchemy (Async) with Alembic migrations
* **Data Processing**: pandas, numpy, xarray, netCDF4
* **Statistical Computing**: R integration via rpy2
* **Containerization**: Docker & Docker Compose
* **Authentication**: JWT with passlib
* **API Documentation**: OpenAPI/Swagger

---

## 1. System Prerequisites

### Operating System

* Linux, macOS, or Windows with **WSL2** support

### Software

* Docker 20.10+
* Docker Compose
* Python 3.12+ (for local dev only)
* R 4.0+ (installed inside Docker)

---

## 2. Install Docker

### Windows

1. Download and install Docker Desktop from: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Enable **WSL2** backend (required)
3. Restart your machine after installation
4. Verify installation:

```bash
docker --version
docker-compose --version
```

### macOS

1. Download Docker Desktop for Mac: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Install and start Docker
3. Verify installation:

```bash
docker --version
docker-compose --version
```

### Linux (Ubuntu/Debian)

```bash
# Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt-get update && sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Run Docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

---

## 3. Clone the Repository

```bash
# Clone using HTTPS
git clone https://github.com/mahan66/smicrab_backend.git

# Or using SSH
git clone git@github.com:mahan66/smicrab_backend.git

cd smicrab_backend
```



## 4. Add Required Data

* Add your `.nc` NetCDF files to the `datasets/` directory




## 5. Automated Setup (Recommended)

```bash
chmod +x startup.sh
./startup.sh
```

This script:

* Builds Docker images
* Validates dataset files
* Generates CSVs with R
* Starts PostgreSQL
* Runs Alembic migrations
* Loads dataset metadata
* Starts backend and pgAdmin

---

## 6. Manual Setup (If Startup Fails)

If the automated setup fails, follow these manual steps. This approach allows you to run each step individually and troubleshoot issues as they arise.

### Step 1: Build Docker Images

```bash
docker-compose build
```

### Step 2: Start PostgreSQL

```bash
docker-compose up -d postgres
```

### Step 3: Start Backend

```bash
docker-compose up -d backend
```

### Step 4: Generate CSVs (Inside Backend Container)

```bash
docker exec -it smicrab_backend bash -c "cd /app/r_scripts/project_setup && Rscript generate_csv.R"
```

### Step 5: Run Database Migrations

```bash
docker exec -it smicrab_backend bash -c "alembic upgrade head"
```

### Step 6: Load Dataset Metadata

```bash
docker exec -it smicrab_backend bash -c "python /app/resources/scripts/load_dataset_data.py"
```

### Step 7: Verify Everything

```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/datasets
```

---

## 7. Access the System

* API Docs: [http://localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs)
* pgAdmin: [http://localhost:8080](http://localhost:8080)

  * Email: `admin@smicrab.com`
  * Password: `admin123`

---

## 8. Project Structure

```
smicrab-backend/
├── app/
│   ├── api/
│   │   ├── api.py                    # Main API router
│   │   └── router/                   # Module-specific routers
│   │
│   ├── domain/                       # Business logic layer
│   │
│   ├── infrastructure/
│   │   └── repositories/             # Data access layer
│   │
│   ├── Models/                       # SQLAlchemy models
│   │   ├── base_model.py
│   │   ├── analysis.py
│   │   ├── dataset.py
│   │   └── user.py
│   │
│   └── utils/                        # Utility functions
│
├── core/                             # Core configuration
│   ├── config.py                     # Application settings
│   └── logging_config.py             # Logging configuration
│
├── r_scripts/                        # R statistical computing
│
├── resources/
│   └── scripts/
│       └── load_dataset_data.py      # Dataset metadata loader
│
├── migrations/                       # Alembic database migrations
├── datasets/                         # NetCDF data files
├── logs/                            # Application logs
└── tmp/                             # Temporary analysis files
```
---

## 9. Configuration (.env)

```env
API_V1_STR=/api/v1
PROJECT_NAME=SMICRAB
ENVIRONMENT=development
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=<DB_NAME>
POSTGRES_USER=<DB_USER>
POSTGRES_PASSWORD=<DB_PASS>
DATABASE_URL=postgresql+asyncpg://<DB_USER>:<DB_PASS>@<POSTGRES_HOST>:<POSTGRES_PORT>/<DB_NAME>
LOG_LEVEL=INFO
```


## 10. Troubleshooting & Logs

```bash
# View logs
docker-compose logs backend
docker-compose logs postgres

# Check services
docker-compose ps

# Restart a service
docker-compose restart backend
```
---
**Permission Issues:** If you encounter permission errors while running `.sh` scripts, ensure they have execution permissions:
  ```sh
  find . -type f -name "*.sh" -exec chmod +x {} \;
  ```

