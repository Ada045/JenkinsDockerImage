# Jenkins Docker CI/CD Image

A custom Jenkins image with Git, Maven, and the Docker CLI already installed — so you don't have to set them up by hand every time you start a new Jenkins container.

![Jenkins](https://img.shields.io/badge/Jenkins-LTS-D24939?style=flat-square&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-CLI-2496ED?style=flat-square&logo=docker&logoColor=white)
![Java](https://img.shields.io/badge/Java-17-orange?style=flat-square&logo=openjdk&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

## The Problem

Every time I ran Jenkins in a new Docker container — on a new machine, or after rebuilding — I had to manually install the same tools before I could run any pipeline:

- Docker CLI (to build/push images)
- Git (to clone repos)
- Maven (to build Java projects)

That's five minutes of `apt-get install` every single time, on every server. Annoying, and easy to get wrong or forget a step.

## The Fix

Instead of installing those tools *after* the container starts, I baked them straight into a custom image. Now a new Jenkins container is ready to build things the moment it starts — nothing to install, nothing to configure.

```mermaid
flowchart LR
    A[Official Jenkins image] -->|add Git, Maven, Docker CLI| B[My custom image]
    B -->|docker push| C[(GitHub Container Registry)]
    C -->|docker pull + run, anywhere| D[Jenkins, ready to go]
```

## What's Inside

- Jenkins LTS (with Java 17 built in)
- Git
- Maven
- Docker CLI
- curl, wget, unzip, gnupg, ca-certificates (needed to add Docker's package repo)

## The Dockerfile

```dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    maven \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli

USER jenkins
```

**What each part does:**

1. **`FROM jenkins/jenkins:lts-jdk17`** — starts from the official Jenkins LTS image, which already includes Java 17.
2. **First `RUN`** — installs Git, Maven, and a few helper tools (`curl`, `wget`, `unzip`, `gnupg`, `ca-certificates`) needed for the next step.
3. **Second `RUN`** — adds Docker's official package repository and installs just the Docker **CLI** (not a full Docker daemon). Jenkins talks to the Docker daemon already running on the host machine.
4. **`USER jenkins`** — switches back to the regular Jenkins user so the container doesn't run as root.

## How I Built and Published It

```bash
# Build the image locally
docker build -t my-jenkins .

# Tag it for GitHub Container Registry
docker tag my-jenkins ghcr.io/your-username/my-jenkins:latest

# Push it
docker push ghcr.io/your-username/my-jenkins:latest
```

That's it — three commands, no extra config files.

## Running It

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/your-username/my-jenkins:latest
```

Mounting `/var/run/docker.sock` is what lets Jenkins run `docker build`/`docker push` commands using the host's Docker engine, without needing Docker installed *inside* the container itself.

Then open **http://localhost:8080** and finish the Jenkins setup screen.

## Using It on Any New Server

This is the whole point — no setup steps needed:

```bash
docker pull ghcr.io/your-username/my-jenkins:latest
docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/your-username/my-jenkins:latest
```

Git, Maven, and the Docker CLI are already there.

## Example Pipeline

A pipeline running on this image can go straight to building — no install steps in the Jenkinsfile:

```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-username/your-app.git'
            }
        }
        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t my-app:latest .'
            }
        }
    }
}
```

## Screenshots

_Add screenshots of the Jenkins dashboard and a pipeline run here._

## Lessons Learned

- Baking tools into the image once is a lot less work than installing them on every new container.
- Only the Docker **CLI** is needed inside the container — the container uses the host's Docker daemon through the mounted socket, so there's no need to run Docker-inside-Docker.
- A Dockerfile ends up being the clearest record of "what's installed on this server" — better than any notes or memory.

## Future Improvements

- [ ] Automate the build/push with GitHub Actions
- [ ] Add version tags instead of just `latest`
- [ ] Add optional support for other languages (Node.js, Python)

## License

MIT — see [LICENSE](./LICENSE).
