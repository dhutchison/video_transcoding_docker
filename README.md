# video_transcoding_docker

## Overview

This repository provides ready-to-use Docker images packaging [Lisa Melton's video_transcoding tools](https://github.com/lisamelton/video_transcoding) with the FFmpeg and HandbrakeCLI dependencies included. Available in a standard and JDK included variant suitable for use as a  Jenkins agent, allowing use for both local transcoding and CI/CD pipeline integration. 

The images are automatically updated when new versions of video_transcoding are released, ensuring you always have access to the latest improvements. (Well, a GitHub action checks weekly for releases, so it won't be too far behind!)

## Quick Start

Note that `transcode-video` creates it's output in the working directory (`/work`), so if your input file is already a `.mkv` file it must be in a different directory, otherwise it will fail with a message about the file already existing. In the examples below I have made an `originals` directory inside `/path/to/videos`.

Transcode a video file with default settings:

```bash
docker run --rm -v /path/to/videos:/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  transcode-video.rb originals/input.mkv
```

Detect crop values for a video:

```bash
docker run --rm -v /path/to/videos:/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  detect-crop.rb originals/input.mkv
```

## Available Tags

All images are hosted on GitHub Container Registry (ghcr.io).

| Tag Pattern | Description | Use Case |
|-------------|-------------|----------|
| `2025.01.28` | Standard image with Ruby 3.4 | Local transcoding, general use |
| `2025.01.28-ruby3.4-jdk21` | Includes Amazon Corretto JDK 21 | Jenkins agent, CI/CD pipelines |
| `latest` | Points to most recent standard image version | Development (not recommended for production) |

Remember to always pin t specific version tags in production to ensure reproducible builds.

## Usage Examples

### Basic Transcoding

Transcode a single file with custom quality:

```bash
docker run --rm -v $(pwd):/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  transcode-video.rb --quality 20 originals/input.mkv
```

As this container just packages [Lisa Melton's video_transcoding tools](https://github.com/lisamelton/video_transcoding), see it's documentation for the full usage instructions. 

### Batch Processing

Process all MKV files in a directory:

```bash
docker run --rm -v /path/to/videos:/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  bash -c 'for f in originals/*.mkv; do transcode-video.rb "$f"; done'
```

### Using detect-crop

Find optimal crop values before transcoding:

```bash
docker run --rm -v $(pwd):/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  detect-crop.rb originals/input.mkv
```

### Converting with convert-video

Use the convert-video tool for quick conversions between formats without encoding:

```bash
docker run --rm -v $(pwd):/work \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  convert-video.rb originals/input.mkv
```

### Running with Different User ID

To avoid permission issues with output files:

```bash
docker run --rm -v $(pwd):/work \
  --user $(id -u):$(id -g) \
  ghcr.io/dhutchison/video_transcoding_docker:2025.01.28 \
  transcode-video.rb originals/input.mkv
```

## Jenkins Integration

While they container no Jenkins specific configuration or packages, the `-jdk21` tagged images can be used as Jenkins agents for automated transcoding pipelines.

### Jenkins Agent Configuration

1. **Install required plugins**: Docker plugin
2. **Add Docker cloud** in Jenkins configuration. I use the Configuration as Code plugin with this setup 

```
jenkins:
  numExecutors: 0

  clouds:
    - docker:
        name: "docker"
        dockerApi:
          dockerHost:
            uri: "unix:///var/run/docker.sock"
        templates:
          - labelString: "transcode-agent"
            dockerTemplateBase:
              image: "ghcr.io/dhutchison/video_transcoding_docker:2025.01.28-ruby3.4-jdk21"
              mounts:
                - "type=tmpfs,destination=/run"
                - "type=bind,source=/mnt/data-tank/encodes/_input,destination=/data/input"
                - "type=bind,source=/mnt/data-tank/encodes/_output,destination=/data/output"
            remoteFs: "/work"
            connector:
              attach:
                user: "568"
            instanceCapStr: "10"
            retentionStrategy:
              idleMinutes: 1

```
3. **Configure pipeline** with a definition that uses that agent.

### Example Pipeline

```groovy
pipeline {
    agent {
        label 'transcode-agent'
    }
    parameters {
        string(name: 'inputFile', description: 'The path to the file in the input directory to transcode.', trim: true)
    }
    stages {
        stage('Encode') {
            steps {
                sh 'transcode-video.rb --version'
                sh 'ls -l "/data/input/${inputFile}"'
                sh 'transcode-video.rb --add-audio all --add-subtitle all "/data/input/${inputFile}"'
                sh 'mv *.mkv /data/output/'
            }
        }
    }
}
```

You can get more advanced chaining the outputs of different commands if you need to, but personally I don't. 

```groovy
    stages {
        stage('Detect Crop') {
            steps {
                sh 'detect-crop.rb /data/input/input.mkv > crop-values.txt'
            }
        }
        stage('Transcode') {
            steps {
                sh 'transcode-video.rb --crop $(cat crop-values.txt) /data/input/input.mkv'
            }
        }
    }
}
```

## Configuration

### Volume Mounts

- `/work`: Working directory for transcoding operations
  - Mount your video files into a subdirectory of here (or a different location)
  - Output files will be written to this directory. The program includes checks that the output file does not already exist.
  - Permissions set to allow any user ID

## Building Locally

Clone the repository:

```bash
git clone https://github.com/dhutchison/video_transcoding_docker.git
cd video_transcoding_docker
```

Build the standard image:

```bash
docker build \
  --build-arg BASE_IMAGE=ruby:3.4 \
  --build-arg VIDEO_TRANSCODING_VERSION=2025.01.28 \
  -t video_transcoding:local .
```

Build the variant with java included:

```bash
docker build \
  --build-arg BASE_IMAGE=ruby:3.4 \
  --build-arg VIDEO_TRANSCODING_VERSION=2025.01.28 \
  --build-arg JAVA_VERSION=21 \
  -t video_transcoding:local-jdk .
```

## Automated Updates

This repository includes a GitHub Action that:
- Periodically checks for new video_transcoding releases
- Automatically builds and publishes updated images
- Tags images with the corresponding video_transcoding version

You can always find the latest available version in the [releases](https://github.com/lisamelton/video_transcoding/releases) of the upstream project.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Reporting Issues

- **Tool-specific issues**: Report to [video_transcoding](https://github.com/lisamelton/video_transcoding/issues)
- **Container-specific issues**: Report here

### Pull Requests

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request with a clear description

## License

This repository is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

The video_transcoding tools are created and maintained by Lisa Melton under their own license. Please see the [video_transcoding repository](https://github.com/lisamelton/video_transcoding) for details.

## Credits

This repository on it's own does not do much except package up existing tools - big thanks to the people who made the tools that make this all possible:

- **video_transcoding**: Created and maintained by [Lisa Melton](https://github.com/lisamelton/video_transcoding)
- **HandBrake**: The [HandBrake Team](https://handbrake.fr/)
- **FFmpeg**: The [FFmpeg Developers](https://ffmpeg.org/)