FROM jenkins/jenkins:lts-jdk21

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