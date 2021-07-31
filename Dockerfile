# Install build dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential \
                       cmake \
                       git \
                       libcurl4-openssl-dev \
                       libenet-dev \
                       libssl-dev \
                       pkg-config \
                       subversion \
                       zlib1g-dev \
                       ca-certificates \
                       libsqlite3-dev \
                       libsqlite3-0 \
                       tzdata

# Get code and assets
RUN git clone --branch master --depth=1 https://github.com/kimden/stk-code
RUN svn checkout https://svn.code.sf.net/p/supertuxkart/code/stk-assets-release/${VERSION}/ stk-assets

# Build server
RUN mkdir stk-code/cmake_build && \
    cd stk-code/cmake_build && \
    cmake .. -DSERVER_ONLY=ON -USE_SQLITE3=ON -USE_SYSTEM_ENET=ON && \
    make -j$(nproc) && \
    make install

# -----------
# Final stage
# -----------

FROM ubuntu:20.04
LABEL maintainer=iluvatyr
WORKDIR /stk

# Install libcurl dependency
RUN apt-get update && \
    apt-get install --no-install-recommends -y libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy artifacts from build stage
COPY --from=build /usr/local/bin/supertuxkart /usr/local/bin
COPY --from=build /usr/local/share/supertuxkart /usr/local/share/supertuxkart
COPY docker-entrypoint.sh docker-entrypoint.sh

# Expose the ports used to find and connect to the server
EXPOSE 2759
EXPOSE 2757

ENTRYPOINT ["/stk/docker-entrypoint.sh"]
