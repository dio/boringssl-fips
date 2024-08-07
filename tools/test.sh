#!/usr/bin/env bash

# This is adapted from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/external/boringssl_fips.genrule_cmd.

set -ex

VERSION="1.10.2"
cd ninja-"$VERSION"
export PATH="$PWD:$PATH"

cd boringssl/build

ninja run_tests
./crypto/crypto_test
