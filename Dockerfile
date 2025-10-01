# ===== Stage 1: Build dependencies =====
FROM python:3.11-slim AS builder

# Set work directory
WORKDIR /app

# Install pip tools and dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Copy application code
COPY . .

# ===== Stage 2: Runtime =====
FROM python:3.11-slim AS runtime

# Set work directory
WORKDIR /app

# Copy only installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY --from=builder /app /app

# Expose port
EXPOSE 5000

# Run app
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
