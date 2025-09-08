# SMICRAB-GUI Frontend

**Spatial Modeling and Integrated Computational Risk Assessment - Graphical User Interface**

A modern web application for environmental scientists and decision-makers to perform climate risk assessment and biodiversity analysis through an intuitive interface.


## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)
```bash
# 1. Clone the repository
git clone https://github.com/mahan66/smicrab_ui.git
cd smicrab_ui

# 2. Setup environment
cp .env.example .env

# 3. Build and run with docker-compose
docker-compose up --build -d

# 4. Access at http://localhost:3000
```

### Option 2: Local Development
```bash
# 1. Clone the repository
git clone https://github.com/mahan66/smicrab_ui.git
cd smicrab_ui

# 2. Install dependencies
npm install

# 3. Setup environment
cp .env.example .env

# 4. Start development server
npm run dev

# 5. Open http://localhost:3000
```

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

### For Local Development
- **Node.js 18+** - [Download here](https://nodejs.org/)
- **npm, yarn, pnpm, or bun** - Package manager
- **Git** - [Download here](https://git-scm.com/)
- **Access to SMICRAB backend API**

### For Docker Deployment
- **Docker** - [Installation guides below](#docker-installation)
- **Docker Compose** - Usually included with Docker Desktop
- **Git** - [Download here](https://git-scm.com/)

#### Docker Installation

<details>
<summary><strong>Windows</strong></summary>

1. Download Docker Desktop from [https://docker.com/products/docker-desktop](https://docker.com/products/docker-desktop)
2. Run the installer and follow the setup wizard
3. Restart your computer when prompted
4. Verify installation: `docker --version` and `docker-compose --version`
</details>

<details>
<summary><strong>macOS</strong></summary>

1. Download Docker Desktop from [https://docker.com/products/docker-desktop](https://docker.com/products/docker-desktop)
2. Drag Docker.app to Applications folder
3. Launch Docker from Applications
4. Verify installation: `docker --version` and `docker-compose --version`
</details>

<details>
<summary><strong>Linux (Ubuntu/Debian)</strong></summary>

```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker --version
sudo docker compose version
```
</details>

## 🛠️ Installation & Setup

### 1. Clone the Repository

```bash
# Using HTTPS
git clone https://github.com/mahan66/smicrab_ui.git

# Or using SSH (if you have SSH keys configured)
git clone git@github.com:mahan66/smicrab_ui.git

# Navigate to frontend directory
cd smicrab_ui
```

### 2. Environment Configuration

```bash
# Copy the example environment file
cp .env.example .env
```

Edit the `.env` file with your configuration:

```env
# Backend API URL - adjust based on your deployment
API_URL=http://localhost:8000/api/v1

# Public download URL for datasets  
DOWNLOAD_URL=http://localhost:8000
```

### 3. Install Dependencies

```bash
# Using npm
npm install

# Or using yarn
yarn install
```

### 4. Run Development Server

```bash
# Using npm
npm run dev

# Or using yarn
yarn dev
```

### 5. Access Application

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

The application is configured to use Docker Compose for easy deployment and integration with the backend.

#### Start the Application
```bash
# Build and start the frontend
docker-compose up -d --build

# View logs
docker-compose logs -f smicrab-ui

# Start without building (if image already exists)
docker-compose up -d
```

#### Container Management
```bash
# Stop the application
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# View real-time logs
docker-compose logs -f

# Access container shell
docker-compose exec smicrab-ui sh
```

#### Network Integration
The docker-compose.yml is configured to use an external network `smicrab_network`. This allows seamless communication with the SMICRAB backend when it's also running in Docker.

```yaml
# The frontend connects to this external network
networks:
  smicrab-ui:
    name: smicrab-ui
```

Make sure the network exists before starting:
```bash
# Create the network if it doesn't exist
docker network create smicrab-ui
```


**Note: Connecting to Docker Locally**

If you want to **connect to your Docker app locally** (e.g., accessing the API or frontend from a browser or another app), you need to **find your system's local IP address** and set it in the `.env` file along with port `8000`, like this:

```env
API_URL=http://192.168.1.4:8000/api/v1
DOWNLOAD_URL=http://192.168.1.4:8000
```


## Using Docker Directly

If you prefer to use Docker commands directly instead of docker-compose:

#### Build the Docker Image
```bash
docker build -t smicrab-ui:latest .
```

#### Run the Container
```bash
# With .env file (recommended)
docker run --network smicrab_network -d --name smicrab-ui -p 3000:3000 --env-file .env smicrab-ui:latest
```

#### Container Management
```bash
# View logs
docker logs -f smicrab-ui

# Stop container
docker stop smicrab-ui

# Remove container
docker rm smicrab-ui

# Remove image
docker rmi smicrab-ui:latest
```

**Note: Connecting to Docker Locally**

If you want to **connect to your Docker app locally** (e.g., accessing the API or frontend from a browser or another app), you need to **find your system's local IP address** and set it in the `.env` file along with port `8000`, like this:

```env
API_URL=http://192.168.1.4:8000/api/v1
DOWNLOAD_URL=http://192.168.1.4:8000
```

How to find your local IP address on different operating systems:

* **Linux**:

```bash
hostname -I
```

or:

```bash
ip a | grep inet
```

* **macOS**:

```bash
ipconfig getifaddr en0
```

*(If you're using Wi-Fi. If you're on Ethernet, try `en1`.)*

* **Windows**:

```powershell
ipconfig
```

Then look for the `IPv4 Address` under the section related to your active network connection.


## 🔧 Development

### Available Scripts

- `npm run dev` - Start development server with Turbopack
- `npm run build` - Build production application
- `npm run start` - Start production server
- `npm run lint` - Run ESLint for code quality

### Health Check

Verify the application is running:
```bash
curl http://localhost:3000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-27T12:00:00.000Z",
  "service": "smicrab-ui"
}
```

## 🌟 Project Overview

SMICRAB-GUI Frontend is a state-of-the-art React 19 and Next.js 15 application that serves as the primary interaction layer for SMICRAB's computational engine. It bridges complex scientific workflows with modern web technology, providing researchers with powerful tools for environmental analysis.

## 🏗️ Architecture

### Technology Stack

- **React 19** - Advanced concurrent features, server components, and enhanced hooks
- **Next.js 15** - Full-stack framework with App Router and server actions
- **TypeScript** - Strict typing for reliability and maintainability
- **Tailwind CSS** - Utility-first styling with consistent design system
- **ShadCN UI** - Accessible and modular component primitives
- **Lucide React** - Modern icon set with accessibility support

### Project Structure

```
smicrab-ui/
├── app/                    # App Router-based routing and pages
│   ├── analyses/          # Analysis management pages
│   ├── analysis/          # Individual analysis workflows
│   │   └── [analysisId]/  # Dynamic analysis routes
│   └── layout.tsx         # Root layout
├── components/            # Reusable UI components
│   ├── analysis/         # Analysis management components
│   ├── load-module/      # Load module workflow components
│   ├── describe/         # Describe module components
│   ├── estimate/         # Estimate module components
│   ├── validate/         # Validate module components
│   ├── riskmap/          # Risk map module components
│   └── ui/               # Base UI components (ShadCN)
├── actions/              # Server actions for backend communication
├── types/                # TypeScript interfaces and type definitions
├── lib/                  # Shared utilities and helpers
└── constants/            # Application-wide constants
```

## 🔬 Core Modules

The application is organized around five scientific modules, each representing a phase in the climate and biodiversity analysis pipeline:

1. Load Module
2. Describe Module
3. Estimate Module
4. Validate Module
5. Risk Map Module


## 🔄 Integration with Backend

The frontend communicates with the SMICRAB FastAPI backend through:

- **Server Actions** - Direct server-to-server communication
- **RESTful APIs** - Standard HTTP requests for data operations
- **Type Safety** - TypeScript interfaces matching backend Pydantic models
- **Real-time Updates** - Optimistic UI updates and concurrent rendering


## 🎨 Design System

Built on ShadCN UI components with Tailwind CSS:

- **Responsive Design** - Mobile-first approach
- **Dark/Light Mode** - Theme switching support
- **Consistent Styling** - Utility-first CSS approach
- **Component Library** - Reusable, tested components
