# Project Docker Setup Documentation

The project includes **three Dockerfiles**, each with a specific role:

* `Dockerfile`
* `Dockerfile.analysis_packages`
* `Dockerfile.analysis`

---

## 🧩 Purpose of These Dockerfiles

The main reason for separating the Dockerfiles is to reduce the time-consuming process of building the server, especially when it includes R package installations.

As noted:

> *The backend build takes a long time mainly because of the R package installations. Many of these packages are large, have numerous dependencies, and need to be compiled from source — they don’t include precompiled binaries or system libraries by default.*

---

## 🔧 Explanation of Dockerfiles

### 1. `Dockerfile`

This is the **main Dockerfile** used in the backend. It is responsible for:

* Running the API server
* Handling analysis execution

### 2. `Dockerfile.analysis_packages`

This Dockerfile builds a **custom image** that includes all necessary R packages.
Since installing R packages is time-consuming, this image is created **once**, and then reused.

* This helps avoid repeated installations of the same packages.
* The resulting custom image is used as the base for the next Dockerfile.

### 3. `Dockerfile.analysis`

This Dockerfile is dedicated to **executing statistical models**.

* It uses the image built from `Dockerfile.analysis_packages` as its base.
* To build this image, the base image (`smicrab-analysis-packages`) must already be created.

**Benefits:**

* Model execution becomes fast and efficient.
* R packages don’t need to be installed each time a model runs.
* When a user triggers an analysis request, the backend spins up a **temporary container** from this image to run the model. After execution is complete, the container is automatically removed to save system resources.

### ⚠️ Previous vs. Current Behavior

In the earlier version, model analysis ran in a **thread inside the backend**, which often overloaded the server and caused crashes.
With the new architecture:

* Model execution happens in **isolated containers**.
* The backend remains stable and responsive, even under load.

---

## 🛠️ Setup & Execution Steps

Follow these steps in order to run the project properly:

### Step 1: Create Environment File

Copy the example environment file to start your configuration:

```bash
cp .env.example .env
```

---

### Step 2: Build the R Packages Base Image

This step builds the base image with all R dependencies:

```bash
docker build -f Dockerfile.analysis_packages -t smicrab-analysis-packages:latest . --no-cache
```

> ⏳ Note: This may take a long time but is only required **once**. If you’ve already built it before, you can skip this step.

---

### Step 3: Build the Analysis Execution Image

This image should be rebuilt **any time the server code changes**:

```bash
docker build -f Dockerfile.analysis -t smicrab-analysis:latest . --no-cache
```

---

### Step 4: Run the Backend Server (API + Analysis Handler)

Finally, build and run the main backend container using Docker Compose:

```bash
docker-compose up -d --build backend
```

---

## 🌐 Access the API Documentation

Once the above steps are complete, visit the following URL to view the API documentation (Swagger UI):

```
http://localhost:8000/api/v1/docs
```
or

```
<domain_name>/api/v1/docs
```
