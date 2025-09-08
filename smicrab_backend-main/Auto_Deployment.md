
# SMICRAB Quick Deployment Guide

## 1. Directory Setup

Create a directory for auto deployment (e.g., `smicrab-deployment`).

---

## 2. .env File Setup

In the main project directory, create a file named `.env` with the following content.  
You **must edit the 3 placeholder values**:

```env
# 1. Set your server's public IP or domain name
SERVER_PUBLIC_ADDRESS=<your_public_server_ip_or_domain>

# 2. Set the absolute path to this project directory
PROJECT_PATH=</path/to/your/smicrab-deployment>

# 3. Set a secure password for the database
POSTGRES_PASSWORD=pass12

# --- No changes needed below this line ---
POSTGRES_HOST=postgres
POSTGRES_DB=smicrab
POSTGRES_USER=smicrab_user
POSTGRES_PORT=5432
DATABASE_URL=postgresql+asyncpg://smicrab_user:$pass12@postgres:5432/smicrab
WEBHOOK_URL=http://smicrab_backend:8000/api/v1/analysis/webhook/completion
LOG_LEVEL=INFO
MEMORY_LIMIT_PER_ANALYSIS=4g
CPU_LIMIT_PER_ANALYSIS=2.0
API_URL=http://smicrab_backend:8000/api/v1
DOWNLOAD_URL=http://smicrab_backend:8000
````

✅ To set the correct `PROJECT_PATH`, simply run the following command inside your project directory and paste the result:

```bash
pwd
```

## 3. Auto Deployment Script

The `auto_deployment.sh` script is an automation tool that simplifies the entire deployment process.

> **Note:**  
> The `auto_deployment.sh` file **must be placed inside the `smicrab-deployment` folder**, **in the same location as the `.env` file**, for it to work properly.

### ✅ What It Does:

* Detects your OS (Linux, WSL, macOS, Windows)
* Validates `.env` file
* Pulls required Docker images
* Sets up containers and networks
* Applies database migrations
* Seeds initial data
* Starts backend and frontend containers
* Creates a default user: `user@smicrab.com / user123`
* Verifies services are running

### ▶ How to Use:

```bash
chmod +x auto_deployment.sh
./auto_deployment.sh
```

### ⚠ Requirements:

* Must be run on **Linux or WSL (Windows Subsystem for Linux)**
* Ensure `.env` is configured before running the script
* Use `pwd` to set `PROJECT_PATH` properly


## 4. Manual Deployment

Run the following commands in your terminal.

### A. Pull Docker Images

```bash
# Login to the private registry (enter credentials when prompted)
docker login 131.175.206.80:5443

# Pull all required images
docker pull 131.175.206.80:5443/smicrab-backend:latest
docker pull 131.175.206.80:5443/smicrab-analysis:latest
docker pull 131.175.206.80:5443/smicrab-analysis-packages:latest
docker pull 131.175.206.80:5443/smicrab-ui:latest
docker pull postgres:15-alpine
```

### B. Launch the Stack

```bash
docker network create smicrab-net

# Run Database (then wait ~30 seconds)
docker run -d --name postgres \
  --network smicrab-net \
  --env-file .env \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:15-alpine

# Run Migrations
docker run --rm \
  --network smicrab-net \
  --env-file .env \
  131.175.206.80:5443/smicrab-backend:latest \
  alembic upgrade head

# Run Backend
docker run -d --name smicrab_backend \
  --network smicrab-net \
  --env-file .env \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "</path/to/your/smicrab-deployment>/tmp/analysis:/tmp/analysis" \
  --restart unless-stopped \
  131.175.206.80:5443/smicrab-backend:latest

# Seed Data
docker exec smicrab_backend python /app/resources/scripts/load_dataset_data.py

# Run Frontend
docker run -d --name smicrab_ui \
  --network smicrab-net \
  --env-file .env \
  -p 3000:3000 \
  --restart unless-stopped \
  131.175.206.80:5443/smicrab-ui:latest
```

---

## 5. Final Verification

* Run `docker ps` to ensure the `postgres`, `smicrab_backend`, and `smicrab_ui` containers are **Up**.
* UI Access: `http://<your_server_ip>:3000`
* API Docs: `http://<your_server_ip>:8000/api/v1/docs`
