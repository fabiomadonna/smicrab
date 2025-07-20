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
* **Statistical Computing**: R integration via containerized execution
* **Containerization**: Docker & Docker Compose
* **Authentication**: JWT with passlib
* **API Documentation**: OpenAPI/Swagger

### Analysis Execution

The system uses a **containerized execution model** for running statistical analysis:

* **Isolated Execution**: Each analysis runs in a separate Docker container
* **Resource Management**: Memory limit of 8GB per container
* **Concurrent Analysis**: Maximum of 3 simultaneous analyses
* **Automatic Cleanup**: Containers are removed after completion
* **Persistent Results**: Analysis outputs are saved to `/tmp/analysis/<analysis_id>`

### Docker Architecture

The project includes three Dockerfiles, each with a specific role:

#### 🧩 Purpose of These Dockerfiles

The main reason for separating the Dockerfiles is to reduce the time-consuming process of building the server, especially when it includes R package installations. The backend build takes a long time mainly because of the R package installations. Many of these packages are large, have numerous dependencies, and need to be compiled from source — they don't include precompiled binaries or system libraries by default.

#### 🔧 Explanation of Dockerfiles

1. **Dockerfile**
   - This is the main Dockerfile used in the backend
   - Responsible for running the API server and handling analysis execution

2. **Dockerfile.analysis_packages**
   - Builds a custom image that includes all necessary R packages
   - Since installing R packages is time-consuming, this image is created once and then reused
   - This helps avoid repeated installations of the same packages
   - The resulting custom image is used as the base for the next Dockerfile

3. **Dockerfile.analysis**
   - Dedicated to executing statistical models
   - Uses the image built from Dockerfile.analysis_packages as its base
   - To build this image, the base image (smicrab-analysis-packages) must already be created
   - Benefits:
     - Model execution becomes fast and efficient
     - R packages don't need to be installed each time a model runs
     - When a user triggers an analysis request, the backend spins up a temporary container from this image to run the model
     - After execution is complete, the container is automatically removed to save system resources

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

---

## 4. Add Required Data

* Add your `.nc` NetCDF files to the `datasets/` directory

---

## 5. Setup & Execution Steps

Follow these steps in order to run the project properly:

### Step 1: Create Environment File

Copy the example environment file to start your configuration:

```bash
cp .env.example .env
```

Edit this file with your specific configuration values.

### Step 2: Build the R Packages Base Image

This step builds the base image with all R dependencies:

```bash
docker build -f Dockerfile.analysis_packages -t smicrab-analysis-packages:latest . --no-cache
```

⏳ **Note**: This may take a long time but is only required once. If you've already built it before, you can skip this step.

### Step 3: Build the Analysis Execution Image

This image should be rebuilt any time the server code changes:

```bash
docker build -f Dockerfile.analysis -t smicrab-analysis:latest . --no-cache
```

### Step 4: Run the Backend Server (API + Analysis Handler)

Finally, build and run the main backend container using Docker Compose:

```bash
docker-compose up -d --build
```

### Step 5: Initialize Database

Run database migrations to create the necessary tables:

```bash
docker exec smicrab_backend alembic upgrade head
```

### Step 6: Load Dataset Metadata

Load metadata from your NetCDF files into the database:

```bash
docker exec smicrab_backend python /app/resources/scripts/load_dataset_data.py
```

---

## 6. Access the System

### API Documentation

Once the above steps are complete, visit the following URL to view the API documentation (Swagger UI):

* **Local**: [http://localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs)
* **Production**: `<domain_name>/api/v1/docs`

### Database Management

* **pgAdmin**: [http://localhost:8080](http://localhost:8080)
  * Email: `admin@smicrab.com`
  * Password: `admin123`

---

## 7. Project Structure

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
├── tmp/                             # Temporary analysis files
├── Dockerfile                        # Main backend Dockerfile
├── Dockerfile.analysis_packages      # R packages base image
└── Dockerfile.analysis              # Analysis execution image
```

---

## 8. Configuration (.env)

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
PGADMIN_DEFAULT_EMAIL=admin@smicrab.com
PGADMIN_DEFAULT_PASSWORD=admin123
```

---

## 9. Troubleshooting & Logs

```bash
# View logs
docker-compose logs backend
docker-compose logs postgres

# Check services
docker-compose ps

# Restart a service
docker-compose restart backend

# Check Docker images
docker images | grep smicrab
```

---

## 10. Additional Notes

**Permission Issues**: If you encounter permission errors while running `.sh` scripts, ensure they have execution permissions:

```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```

**Rebuilding Images**: If you make changes to the R scripts or dependencies, you may need to rebuild the analysis images:

```bash
# Rebuild analysis packages (if R dependencies changed)
docker build -f Dockerfile.analysis_packages -t smicrab-analysis-packages:latest . --no-cache

# Rebuild analysis image (if server code changed)
docker build -f Dockerfile.analysis -t smicrab-analysis:latest . --no-cache
```



