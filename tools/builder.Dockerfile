FROM ubuntu:20.04
RUN apt-get update && apt-get install -y gcc g++ xz-utils python3 libncurses5 curl patch haveged
COPY ./tools/build.sh /var/local/build.sh
COPY ./tools/no-check-time.patch /var/local/no-check-time.patch
RUN /var/local/build.sh
