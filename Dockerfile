FROM  python:slim-bookworm
WORKDIR /app

COPY ./app.py  .
COPY requirements.txt .

RUN apt-get update --no-install-recommends &&     apt-get install --no-install-recommends -y gcc &&     pip install --no-cache-dir -r requirements.txt &&     chown nobody . -R

USER nobody
EXPOSE 5000
ENTRYPOINT uwsgi --http 0.0.0.0:5000 --wsgi-file app.py --callable app
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3     CMD curl -f http://localhost:5000/healthz || exit 1
