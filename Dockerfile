FROM ruby:3.3-slim

# Install HandBrakeCLI + FFmpeg + dependencies needed by video_transcoding
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    handbrake-cli \
    git \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Clone video_transcoding tools
RUN git clone https://github.com/lisamelton/video_transcoding.git /opt/video_transcoding \
    && cd /opt/video_transcoding \
    && chmod +x transcode-video.rb detect-crop.rb convert-video.rb

# Add video_transcoding scripts to PATH
ENV PATH="/opt/video_transcoding:${PATH}"


# Working directory for transcoding workloads
WORKDIR /work

CMD ["/bin/bash"]
