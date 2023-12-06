# FROM  python:slim-bookworm
FROM python:3.11.7-slim-bookworm
WORKDIR /app

COPY ./web.py  .
COPY requirements.txt .

# RUN apt-get update --no-install-recommends && \
RUN apt-get install --no-install-recommends -y gcc && \
    pip install --no-cache-dir -r requirements.txt && \
    chown nobody . -R

USER nobody
EXPOSE 8000
ENTRYPOINT  gunicorn -w 4 -b 0.0.0.0:8000 web:app
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8000/healthz || exit 1
