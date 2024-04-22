FROM python:3.10-alpine
ARG ip

WORKDIR /app

COPY src/ .

RUN pip install -r requirements.txt

EXPOSE 8080
RUN sed -i "s/localhost/$ip/g" app.py

ENTRYPOINT ["python3"]
CMD ["app.py"]