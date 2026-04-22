# Use a proper base image
FROM python:3.11-slim

# Define a working directory
WORKDIR /app

# Install system dependencies required by the Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy only required files (for better caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application files
COPY . .

# Expose the correct port
EXPOSE 8000

# Start the application correctly
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
