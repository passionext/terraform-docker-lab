# 1. Use an official, lightweight Python image
FROM python:3.13-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy your actual Python API code into the container
COPY api.py .

# 5. Expose the port the app runs on
EXPOSE 8000

# 6. The command to run the app continuously when the container starts
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
