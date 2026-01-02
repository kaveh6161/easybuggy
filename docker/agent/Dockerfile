# Jenkins Agent with DevSecOps Tools
# This agent is used for all pipeline stages except Kaniko image build

FROM jenkins/inbound-agent:latest-jdk17

# Metadata
LABEL maintainer="DevSecOps Team"
LABEL description="Jenkins agent with Maven, Snyk, Checkov, Node.js, and ZAP CLI"

# Switch to root to install packages
USER root

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (needed to run Kaniko and manage containers)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Maven
ENV MAVEN_VERSION=3.9.12
ENV MAVEN_HOME=/opt/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}

RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar xzf - -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn

# Install Python and Checkov
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/checkov-venv \
    && /opt/checkov-venv/bin/pip install --no-cache-dir --upgrade pip setuptools \
    && /opt/checkov-venv/bin/pip install --no-cache-dir checkov \
    && ln -s /opt/checkov-venv/bin/checkov /usr/local/bin/checkov

# Install Node.js (required for SonarQube JS/HTML analysis)
ENV NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Snyk CLI (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        curl -Lo /usr/local/bin/snyk https://static.snyk.io/cli/latest/snyk-linux-arm64; \
    else \
        curl -Lo /usr/local/bin/snyk https://static.snyk.io/cli/latest/snyk-linux; \
    fi && \
    chmod +x /usr/local/bin/snyk

# Install OWASP ZAP CLI
# We use the standalone ZAP CLI that can connect to a ZAP daemon
RUN pip3 install --no-cache-dir --break-system-packages zaproxy

# Create workspace directory with proper permissions
RUN mkdir -p /home/jenkins/agent/workspace \
    && chown -R jenkins:jenkins /home/jenkins

# Create directory for scan reports
RUN mkdir -p /home/jenkins/reports \
    && chown -R jenkins:jenkins /home/jenkins/reports

# Switch back to jenkins user
USER jenkins

# Set working directory
WORKDIR /home/jenkins/agent

# Verify installations
RUN mvn --version && \
    node --version && \
    npm --version && \
    snyk --version && \
    checkov --version && \
    python3 --version

