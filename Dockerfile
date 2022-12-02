# -----------
# Build stage
# -----------

FROM ubuntu:22.04 AS build
LABEL maintainer=iluvatyr
WORKDIR /stk

# Install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
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
        dpkg
# Get code and assets
RUN git clone --branch command-manager-prototype --depth=1 https://github.com/iluvatyr/stk-code.git
# Build server
RUN mkdir stk-code/cmake_build && \
    cd stk-code/cmake_build && \
    cmake .. -DSERVER_ONLY=ON -USE_SQLITE3=ON -USE_SYSTEM_ENET=ON -DCHECK_ASSETS=off && \
    make -j$(nproc) && \
    make install

# -----------
# Final stage
# -----------

FROM ubuntu:22.04
ENV CUSERNAME="supertuxkart" \
    CGROUPNAME="supertuxkart" \
    DEBIAN_FRONTEND=noninteractive
#SETUP
LABEL maintainer=iluvatyr
WORKDIR /stk
# Install necessary packages
RUN apt-get update && apt-get install --no-install-recommends -y libcurl4-openssl-dev tzdata dnsutils curl ca-certificates sqlite3 unzip wget cron && rm -rf /var/lib/apt/lists/*
# Copy scripts to workdir
COPY entrypoint.sh server_config.xml update-addons.sh install-all-addons.sh start_stk.sh /stk
# Copy artifacts from build stage
COPY --from=build /usr/local/bin/supertuxkart /usr/local/bin
COPY --from=build /usr/local/share/supertuxkart /usr/local/share/supertuxkart
# Creating user for running supertuxkart
RUN useradd -m -u 1337 ${CUSERNAME} && chown -R ${CUSERNAME}:${CGROUPNAME} /stk && chmod u+x /stk/*.sh
#USER ${CUSERNAME}

# Expose the ports used to find and connect to the server
EXPOSE 2759
EXPOSE 2757

ENTRYPOINT ["/stk/entrypoint.sh"]
