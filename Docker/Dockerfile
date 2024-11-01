FROM swift:latest

LABEL org.opencontainers.image.source=https://github.com/gfusee/space-cli

VOLUME app
WORKDIR /

COPY generate_tag_script.sh generate_tag_script.sh

RUN apt update
RUN apt install binaryen

RUN chmod +x generate_tag_script.sh
RUN ./generate_tag_script.sh https://github.com/gfusee/space.git

RUN mkdir objects
COPY memcpy.c objects/memcpy.c
COPY libclang_rt.builtins-wasm32.a objects/libclang_rt.builtins-wasm32.a

RUN clang --target=wasm32 -O3 -c -o objects/memcpy.o objects/memcpy.c
