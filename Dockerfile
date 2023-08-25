FROM  python:slim-bookworm
WORKDIR /app
COPY ./requirements.txt .
COPY ./app.py  .
RUN chown nobody . -R
USER nobody
EXPOSE 5000
ENTRYPOINT opentelemetry-instrument uwsgi --http 0.0.0.0:5000 --wsgi-file app.py --callable app
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/healthz || exit 1