FROM swift:latest

LABEL org.opencontainers.image.source=https://github.com/gfusee/space-cli

COPY space space

VOLUME app
WORKDIR /

RUN apt update
RUN apt install binaryen

RUN mkdir objects
COPY memcpy.c objects/memcpy.c
COPY libclang_rt.builtins-wasm32.a objects/libclang_rt.builtins-wasm32.a

RUN clang --target=wasm32 -O3 -c -o objects/memcpy.o objects/memcpy.c
