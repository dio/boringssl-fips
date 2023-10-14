FROM quay.io/centos/centos:stream8
RUN apt-get update && yum install -y gcc gcc-c++ xz-utils python3 ncurses-compat-libs curl libatomic binutils unzip
COPY ./tools/centos-stream8/build.sh /var/local/build.sh
RUN /var/local/build.sh
