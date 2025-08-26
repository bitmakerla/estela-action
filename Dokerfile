FROM python:3.9-slim

RUN pip install --no-cache-dir estela

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
