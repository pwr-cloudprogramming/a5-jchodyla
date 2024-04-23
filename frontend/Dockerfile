FROM busybox:1.35
ARG ip

RUN adduser -D stud
USER stud
WORKDIR /home/stud

COPY src/ .

EXPOSE 3000
RUN sed -i "s/44.210.105.217/$ip/g" index.html

ENTRYPOINT ["busybox"]
CMD ["httpd", "-f", "-v", "-p", "3000"]