# -----------------------------------------------------------------------------
# PS2DED - PlayStation 2 DevEnv for Docker
#                                              PS2DEV PlayStation 2 SDK variant
# -----------------------------------------------------------------------------

# [ Builder stage ] - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FROM ubuntu:16.04 AS builder

# Install required packages for unpacking
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        flex \
        git \
        libucl-dev \
        p7zip \
        patch \
        texinfo \
        wget \
        zlib1g-dev

# Copy installation files
COPY install /tmp

# Clone sources repo
RUN git clone https://github.com/ps2dev/ps2dev /tmp/ps2dev

# Build toolchain
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=${PS2DEV}/ps2sdk \
    GSKIT=${PS2DEV}/gsKit
ENV PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin
    
RUN mkdir -p ${PS2SDK} && \
    mkdir -p ${GSKIT} && \
    cd /tmp/ps2dev && \
    ./build-all.sh

# Unpack dsnet binaries
RUN mkdir -p /tmp/dsnet && \
    mv /tmp/*dsnet*.7z /tmp/dsnet && \
    cd /tmp/dsnet && \
    p7zip -d *dsnet*.7z

# [ Application stage ] - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FROM ubuntu:16.04

# Install required packages for the SDK
RUN dpkg --add-architecture i386 && \
    apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        lib32z1 \
        patch \
        make \
        netbase \
        patch \
        rsync \
        zlib1g

# Set up environment variables
ENV DSNET=/usr/local/dsnet \
    PS2DEDPATH=/usr/local/ps2ded
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=${PS2DEV}/ps2sdk \
    GSKIT=${PS2DEV}/gsKit
ENV PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin:$DSNET:$PS2DEDPATH
ENV PS2IP=192.168.1.100

# Copy PS2DEV from builder stage
RUN mkdir -p ${PS2DEV}
COPY --from=builder ${PS2DEV} ${PS2DEV}

# Copy dsnetm binary from builder stage
RUN mkdir -p ${DSNET}
COPY --from=builder /tmp/dsnet/* ${DSNET}/

# Copy ps2ded scripts
RUN mkdir -p ${PS2DEDPATH}
COPY script ${PS2DEDPATH}
RUN chmod +x ${PS2DEDPATH}/*

# Expose DSNET server port
EXPOSE 8510

# Set working directory
WORKDIR /work