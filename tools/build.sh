#!/usr/bin/env bash

# This is adapted from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/external/boringssl_fips.genrule_cmd.

set -ex

# Allow to override BoringSSL source. The one that is blessed is the default values.
# The default values are from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/repository_locations.bzl#L142.
BORINGSSL_VERSION=${1-"0c6f40132b828e92ba365c6b7680e32820c63fa7"}
BORINGSSL_SHA256=${2-"62f733289f2d677c2723f556aa58034c438f3a7bbca6c12b156538a88e38da8a"}
BORINGSSL_SOURCE=${3-"https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-${BORINGSSL_VERSION}.tar.xz"}

export CXXFLAGS=''
export LDFLAGS=''

# BoringSSL build as described in the Security Policy for BoringCrypto module (2022-06-13):
# https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4735.pdf

OS=`uname`
ARCH=`uname -m`
# This works only on Linux-x86_64 and Linux-aarch64.
if [[ "$OS" != "Linux" || ("$ARCH" != "x86_64" && "$ARCH" != "aarch64") ]]; then
  echo "ERROR: BoringSSL FIPS is currently supported only on Linux-x86_64 and Linux-aarch64."
  exit 1
fi

# Clang
VERSION="14.0.0"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="x86_64-linux-gnu-ubuntu-18.04"
  SHA256=61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5
else
  PLATFORM="aarch64-linux-gnu"
  SHA256=1792badcd44066c79148ffeb1746058422cc9d838462be07e3cb19a4b724a1ee
fi

curl -fsLO https://github.com/llvm/llvm-project/releases/download/llvmorg-"$VERSION"/clang+llvm-"$VERSION"-"$PLATFORM".tar.xz \
  && echo "$SHA256" clang+llvm-"$VERSION"-"$PLATFORM".tar.xz | sha256sum --check
tar -xJf clang+llvm-"$VERSION"-"$PLATFORM".tar.xz

export HOME="$PWD"
printf "set(CMAKE_C_COMPILER \"clang\")\nset(CMAKE_CXX_COMPILER \"clang++\")\n" > ${HOME}/toolchain
export PATH="$PWD/clang+llvm-$VERSION-$PLATFORM/bin:$PATH"

if [[ `clang --version | head -1 | awk '{print $3}'` != "$VERSION" ]]; then
  echo "ERROR: Clang version doesn't match."
  exit 1
fi

# Go
VERSION="1.18.1"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="linux-amd64"
  SHA256=b3b815f47ababac13810fc6021eb73d65478e0b2db4b09d348eefad9581a2334
else
  PLATFORM="linux-arm64"
  SHA256=56a91851c97fb4697077abbca38860f735c32b38993ff79b088dac46e4735633
fi

curl -fsLO https://dl.google.com/go/go"$VERSION"."$PLATFORM".tar.gz \
  && echo "$SHA256" go"$VERSION"."$PLATFORM".tar.gz | sha256sum --check
tar -xzf go"$VERSION"."$PLATFORM".tar.gz

export GOPATH="$PWD/gopath"
export GOROOT="$PWD/go"
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"

if [[ `go version | awk '{print $3}'` != "go$VERSION" ]]; then
  echo "ERROR: Go version doesn't match."
  exit 1
fi

# Ninja
VERSION="1.10.2"
SHA256=ce35865411f0490368a8fc383f29071de6690cbadc27704734978221f25e2bed
curl -fsLO https://github.com/ninja-build/ninja/archive/refs/tags/v"$VERSION".tar.gz \
  && echo "$SHA256" v"$VERSION".tar.gz | sha256sum --check
tar -xzf v"$VERSION".tar.gz
cd ninja-"$VERSION"
CC=clang CXX=clang++ python3 ./configure.py --bootstrap

export PATH="$PWD:$PATH"

if [[ `ninja --version` != "$VERSION" ]]; then
  echo "ERROR: Ninja version doesn't match."
  exit 1
fi
cd ..

# CMake
VERSION="3.22.1"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="linux-x86_64"
  SHA256=73565c72355c6652e9db149249af36bcab44d9d478c5546fd926e69ad6b43640
else
  PLATFORM="linux-aarch64"
  SHA256=601443375aa1a48a1a076bda7e3cca73af88400463e166fffc3e1da3ce03540b
fi

curl -fsLO https://github.com/Kitware/CMake/releases/download/v"$VERSION"/cmake-"$VERSION"-"$PLATFORM".tar.gz \
  && echo "$SHA256" cmake-"$VERSION"-"$PLATFORM".tar.gz | sha256sum --check
tar -xzf cmake-"$VERSION"-"$PLATFORM".tar.gz

export PATH="$PWD/cmake-$VERSION-$PLATFORM/bin:$PATH"

if [[ `cmake --version | head -n1` != "cmake version $VERSION" ]]; then
  echo "ERROR: CMake version doesn't match."
  exit 1
fi

# Build and test BoringSSL.
VERSION="${BORINGSSL_VERSION}"
SHA256="${BORINGSSL_SHA256}"
curl -fsLO "${BORINGSSL_SOURCE}" \
  && echo "$SHA256" boringssl-"$VERSION".tar.xz | sha256sum --check

tar -xJf boringssl-"$VERSION".tar.xz

cd boringssl
patch -p1 < /var/local/no-check-time.patch
mkdir build && cd build && cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=${HOME}/toolchain -DFIPS=1 -DCMAKE_BUILD_TYPE=Release ..
ninja

# The result should be in:
#   boringssl/build/crypto/libcrypto.a
#   boringssl/build/ssl/libssl.a

# If you run this script using docker container, you can do:
#   CONTAINER_ID=$(docker create -it your-image-name)
#   docker cp $CONTAINER_ID:/boringssl/build/crypto/libcrypto.a ./libcrypto.a
#   docker cp $CONTAINER_ID:/boringssl/build/ssl/libssl.a ./libssl.a
#   tar -cJf boringssl-fips.tar.xz libcrypto.a libssl.a
