FROM python:3.12-slim

# Install basic system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python packages
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy rest of the app
COPY . .

# Create folders
RUN mkdir -p logs tmp/analysis

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]