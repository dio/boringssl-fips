FROM ubuntu:20.04
RUN apt update && apt install -y build-essential curl
COPY ./tools/build.sh /var/local/build.sh
RUN /var/local/build.sh
