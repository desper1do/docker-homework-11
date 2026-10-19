FROM python:3.12-slim

# Непривилегированный пользователь и каталог данных, принадлежащий ему.
# Именованный volume при первом монтировании копирует владельца этого каталога.
RUN useradd --system --uid 10001 app \
    && mkdir /data \
    && chown app:app /data

WORKDIR /app
COPY backend/server.py /app/server.py

USER app
EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)" || exit 1

CMD ["python3", "/app/server.py"]