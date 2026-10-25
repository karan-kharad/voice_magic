# Python 3.12 Slim Base Image
FROM python:3.12-slim-bookworm

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install system dependencies needed for compiling C extensions & psycopg
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements/base.txt requirements/production.txt /app/requirements/
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements/production.txt

# Copy project files
COPY . /app/
RUN chmod +x /app/docker-entrypoint.sh

# Create non-root user and staticfiles directory
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app/staticfiles /app/media /var/log/whatsapp-voice && \
    chown -R appuser:appuser /app /var/log/whatsapp-voice

USER appuser

EXPOSE 8000

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["gunicorn", "--workers", "3", "--threads", "2", "--bind", "0.0.0.0:8000", "--timeout", "30", "--access-logfile", "-", "--error-logfile", "-", "core.wsgi:application"]
