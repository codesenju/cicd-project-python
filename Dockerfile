FROM python:3.11.7-slim-bookworm

WORKDIR /app

COPY ./web.py  .
COPY requirements.txt .

# Install required libraries
RUN apt-get update --no-install-recommends && \
    apt-get install --no-install-recommends -y gcc && \
    python -m pip install --no-cache-dir -r requirements.txt

# Change working directory ownership
RUN chown nobody:nogroup /app -R

USER nobody

# Expose port and configure gunicorn
EXPOSE 8000
ENTRYPOINT ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "web:app"]

# Add health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1
