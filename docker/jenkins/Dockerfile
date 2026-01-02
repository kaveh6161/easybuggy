FROM jenkins/jenkins:2.543

# Switch to root to install packages
USER root

# Install Docker CLI
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Maven
ENV MAVEN_VERSION=3.9.12
ENV MAVEN_HOME=/opt/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}

RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar xzf - -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn

# Install Python and pip for checkov
RUN apt-get update && apt-get install -y \
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
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Snyk CLI (detect architecture and download appropriate binary)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        curl -Lo /usr/local/bin/snyk https://static.snyk.io/cli/latest/snyk-linux-arm64; \
    else \
        curl -Lo /usr/local/bin/snyk https://static.snyk.io/cli/latest/snyk-linux; \
    fi && \
    chmod +x /usr/local/bin/snyk

# Install Terraform for IaC scanning
ENV TERRAFORM_VERSION=1.6.6
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin \
    && rm terraform.zip

# Switch back to jenkins user
USER jenkins

# Copy plugins list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy Jenkins Configuration as Code
COPY casc_configs/ /var/jenkins_home/casc_configs/

