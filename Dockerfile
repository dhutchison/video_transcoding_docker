FROM ruby:3.3-slim

ARG VIDEO_TRANSCODING_VERSION

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

# Clone video_transcoding tools
RUN git clone --branch "$VIDEO_TRANSCODING_VERSION" --single-branch https://github.com/lisamelton/video_transcoding.git /opt/video_transcoding \
    && cd /opt/video_transcoding \
    && chmod +x transcode-video.rb detect-crop.rb convert-video.rb

# Add video_transcoding scripts to PATH
ENV PATH="/opt/video_transcoding:${PATH}"

# OCI metadata
LABEL org.opencontainers.image.title="video-transcoding"
LABEL org.opencontainers.image.version="${VIDEO_TRANSCODING_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/lisamelton/video_transcoding"


# Working directory for transcoding workloads
WORKDIR /work

CMD ["/bin/bash"]
