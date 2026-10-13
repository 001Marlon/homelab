FROM python:3.12-alpine

RUN pip install --no-cache-dir mcstatus

COPY watchdog.py /watchdog.py

CMD ["python", "/watchdog.py"]
