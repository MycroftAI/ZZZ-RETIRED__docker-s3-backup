FROM ubuntu:17.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    s3fs \
    pxz \
    curl \
    python \
    python-pip

RUN pip install sendgrid

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /s3-mount
RUN mkdir -p /volume-mount

COPY sendgrid.env /
COPY entrypoint.sh /
COPY mailer.py /

WORKDIR /

CMD ["./entrypoint.sh"]
