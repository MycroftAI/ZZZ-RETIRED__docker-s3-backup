FROM ubuntu:17.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    s3fs \
    pxz \
    curl

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /s3-mount
RUN mkdir -p /volume-mount

COPY entrypoint.sh /

WORKDIR /

CMD ["./entrypoint.sh"]
