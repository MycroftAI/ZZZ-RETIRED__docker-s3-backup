FROM ubuntu:17.04

#RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash;
#RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
# cd s3fs-fuse; \
# git checkout tags/${S3FS_VERSION}; \
# ./autogen.sh; \
# ./configure --prefix=/usr; \
# make; \
# make install; \
# rm -rf /var/cache/apk/*;

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    s3fs \
    rsync \
    rdiff-backup

RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /s3-mount
RUN mkdir -p /volume-mount

COPY entrypoint.sh /

WORKDIR /

CMD ["./entrypoint.sh"]
