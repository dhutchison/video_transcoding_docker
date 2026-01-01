ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG VIDEO_TRANSCODING_VERSION
ARG JAVA_VERSION

# Fail early if not provided
RUN test -n "$VIDEO_TRANSCODING_VERSION"

# Install HandBrakeCLI + FFmpeg + dependencies needed by video_transcoding
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    handbrake-cli \
    git \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Optional Corretto JDK (for Jenkins agent use)
RUN if [ -n "$JAVA_VERSION" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        wget gnupg \
      && wget -O- https://apt.corretto.aws/corretto.key | gpg --dearmor > /usr/share/keyrings/corretto.gpg \
      && echo "deb [signed-by=/usr/share/keyrings/corretto.gpg] https://apt.corretto.aws stable main" \
         > /etc/apt/sources.list.d/corretto.list \
      && apt-get update \
      && apt-get install -y --no-install-recommends \
         java-${JAVA_VERSION}-amazon-corretto-jdk \
      && rm -rf /var/lib/apt/lists/* ; \
    fi

# Clone video_transcoding tools
RUN git clone --branch "$VIDEO_TRANSCODING_VERSION" --single-branch https://github.com/lisamelton/video_transcoding.git /opt/video_transcoding \
    && cd /opt/video_transcoding \
    && chmod +x transcode-video.rb detect-crop.rb convert-video.rb

# Add video_transcoding scripts to PATH
ENV PATH="/opt/video_transcoding:${PATH}"

# OCI metadata
LABEL org.opencontainers.image.title="video-transcoding"
LABEL org.opencontainers.image.version="${VIDEO_TRANSCODING_VERSION}"
LABEL org.opencontainers.image.java="${JAVA_VERSION:-none}"
LABEL org.opencontainers.image.build-schema=$BUILD_SCHEMA_VERSION


# Working directory for transcoding workloads
# Making this writable by anyone so that we can supply
# different user ids at runtime and still have a working
# directory
WORKDIR /work
RUN ["chmod", "777", "/work"]

CMD ["/bin/bash"]
