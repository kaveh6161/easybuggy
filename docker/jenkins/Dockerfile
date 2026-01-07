# Jenkins Controller - Minimal installation
# All build tools are installed on the Jenkins agent image instead
# This controller only orchestrates builds - jobs run on ephemeral Docker agents

FROM jenkins/jenkins:2.543

# Metadata
LABEL maintainer="DevOps Team"
LABEL description="Jenkins controller for DevOps pipeline (no build tools)"

# Switch to root for minimal setup
USER root

# Install Docker CLI (needed to spawn Docker agents)
# and essential utilities (curl for healthchecks, jq for JSON parsing)
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    jq \
    lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Create docker group with GID that matches host's docker socket group
# On macOS with Docker Desktop, the socket is owned by root, so we use a fixed GID
# and grant jenkins user access via group membership
ARG DOCKER_GID=999
RUN groupadd -g ${DOCKER_GID} docker || true \
    && usermod -aG docker jenkins

# Configure git to trust all directories (fixes "dubious ownership" errors)
# This is needed when running as root with workspace owned by jenkins
RUN git config --global --add safe.directory '*'

# Switch back to jenkins user
USER jenkins

# Configure git safe.directory for jenkins user too
RUN git config --global --add safe.directory '*'

# Copy plugins list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy Jenkins Configuration as Code
COPY casc_configs/ /var/jenkins_home/casc_configs/

