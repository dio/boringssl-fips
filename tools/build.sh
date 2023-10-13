#!/bin/bash

# This is adapted from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/external/boringssl_fips.genrule_cmd.

set -e

export CXXFLAGS=''
export LDFLAGS=''

# BoringSSL build as described in the Security Policy for BoringCrypto module (2022-05-06):
# https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4407.pdf

OS=`uname`
ARCH=`uname -m`
# This works only on Linux-x86_64 and Linux-aarch64.
if [[ "$OS" != "Linux" || ("$ARCH" != "x86_64" && "$ARCH" != "aarch64") ]]; then
  echo "ERROR: BoringSSL FIPS is currently supported only on Linux-x86_64 and Linux-aarch64."
  exit 1
fi

# Clang
VERSION="12.0.0"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="x86_64-linux-gnu-ubuntu-20.04"
  SHA256=a9ff205eb0b73ca7c86afc6432eed1c2d49133bd0d49e47b15be59bbf0dd292e
else
  PLATFORM="aarch64-linux-gnu"
  SHA256=d05f0b04fb248ce1e7a61fcd2087e6be8bc4b06b2cc348792f383abf414dec48
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
