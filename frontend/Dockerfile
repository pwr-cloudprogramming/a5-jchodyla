FROM busybox:1.35
ARG IP=$IP_V4

RUN adduser -D stud
USER stud
WORKDIR /home/stud

COPY src/ .

RUN sed -i "s/localhost/$IP/g" index.html && \
    sed -i "s/localhost/$IP/g" board.js

ENTRYPOINT ["busybox"]
CMD ["httpd", "-f", "-v", "-p", "3000"]