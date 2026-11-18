FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY bitchord_addon_auth.py server.py .

ENV PORT=8080
ENV BITCHORD_HOSTS="bitchord.confih.tech"
ENV BITCHORD_AUTH_MODE="enforce"

EXPOSE 8080

CMD ["python", "server.py"]
