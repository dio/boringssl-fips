#!/bin/bash

set -e

docker buildx build \
  --file tools/"$OS"/builder.Dockerfile \
  --load \
  --tag builder \
  --platform linux/"$ARCH" \
  --no-cache \
  .
  CONTAINER_ID=$(docker create -it builder)
  docker cp $CONTAINER_ID:/boringssl/build/crypto/libcrypto.a ./libcrypto.a
  docker cp $CONTAINER_ID:/boringssl/build/ssl/libssl.a ./libssl.a
  tar -cJf boringssl-fips-"$OS"-"$ARCH".tar.xz libcrypto.a libssl.a
  docker cp $CONTAINER_ID:/ninja-1.10.2/ninja ./ninja
  tar -cJf ninja-"$OS"-"$ARCH".tar.xz ninja
