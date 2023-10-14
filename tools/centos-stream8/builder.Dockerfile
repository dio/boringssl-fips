FROM quay.io/centos/centos:stream8
RUN yum install -y gcc gcc-c++ xz python3 ncurses-compat-libs libatomic unzip
COPY ./tools/centos-stream8/build.sh /var/local/build.sh
RUN /var/local/build.sh
