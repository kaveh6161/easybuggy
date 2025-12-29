# DevSecOps Docker Environment

This Docker Compose setup provides a complete DevSecOps CI/CD environment for the easybuggy project.

## Components

- **SonarQube** (port 9000): Code quality and security analysis
- **Jenkins** (port 8080): CI/CD automation with DevSecOps tools

## Pre-installed Tools in Jenkins

- Maven 3.8.7
- Docker CLI
- Snyk CLI
- Checkov
- Terraform

## Quick Start

1. **Start the environment:**
   ```bash
   cd easybuggy/docker
   docker-compose up -d --build
   ```

2. **Wait for services to be healthy:**
   ```bash
   docker-compose ps
   ```

3. **Access the services:**
   - Jenkins: http://localhost:8080 (admin/admin)
   - SonarQube: http://localhost:9000 (admin/admin)

## Initial Setup

### SonarQube Configuration

1. Login to SonarQube (admin/admin) - you'll be prompted to change the password
2. Generate a project token:
   - Go to Administration > Security > Users
   - Click on "Tokens" for the admin user
   - Generate a new token named `jenkins`
   - Copy the token

### Jenkins Configuration

1. Login to Jenkins (admin/admin)
2. Add the SonarQube token as a credential:
   - Go to Manage Jenkins > Credentials
   - Add a "Secret text" credential with ID `SONAR_TOKEN`
   - Paste the SonarQube token
3. Add Docker Hub credentials (if pushing images):
   - Add "Username with password" credential with ID `dockerlogin`
4. Add Snyk token (optional):
   - Add "Secret text" credential with ID `SNYK_TOKEN`
5. Add NVD API key (optional):
   - Add "Secret text" credential with ID `NVD_API_KEY`
   - Get an API key from https://nvd.nist.gov/developers/request-an-api-key

### Create a Pipeline Job

1. Create a new Pipeline job in Jenkins
2. Configure it to use `Jenkinsfile.docker` from your repository
3. Run the build!

## Stopping the Environment

```bash
docker-compose down
```

To remove all data (volumes):
```bash
docker-compose down -v
```

## Build Pipeline Flow

```mermaid
graph TB
    Start([Enable Docker Build]) --> Check{Credentials<br/>Ready?}
    
    Check -->|No| Setup[Setup Credentials]
    Check -->|Yes| Enable[Set BUILD_DOCKER='true']
    
    Setup --> Docker[Create Docker Hub PAT]
    Setup --> Snyk[Get Snyk API Token]
    
    Docker --> DockerSteps["1. hub.docker.com<br/>2. Account Settings → Security<br/>3. New Access Token<br/>4. Copy token (dckr_pat_...)"]
    Snyk --> SnykSteps["1. app.snyk.io<br/>2. Account settings<br/>3. Auth Token → Click to show<br/>4. Copy token"]
    
    DockerSteps --> AddDocker[Add to Jenkins as 'dockerlogin'<br/>Type: Username with password]
    SnykSteps --> AddSnyk[Add to Jenkins as 'SNYK_TOKEN'<br/>Type: Secret text]
    
    AddDocker --> Enable
    AddSnyk --> Enable
    
    Enable --> Run[Run Pipeline]
    
    Run --> Stage1[Stage 1: Checkout]
    Stage1 --> Stage2[Stage 2: Build & SonarQube]
    Stage2 --> Stage3[Stage 3: OWASP Dependency Check]
    Stage3 --> Stage4[Stage 4: Build Docker Image]
    Stage4 --> Stage5[Stage 5: Snyk Container Scan]
    Stage5 --> Stage6[Stage 6: Snyk SCA Scan]
    Stage6 --> Stage7[Stage 7: Checkov IaC Scan]
    Stage7 --> Success([Pipeline Complete])
    
    style Start fill:#e1f5ff,stroke:#0066cc,color:#000
    style Success fill:#d4edda,stroke:#28a745,color:#000
    style Docker fill:#fff3cd,stroke:#ffc107,color:#000
    style Snyk fill:#fff3cd,stroke:#ffc107,color:#000
    style Stage4 fill:#cfe2ff,stroke:#0d6efd,color:#000
    style Stage5 fill:#cfe2ff,stroke:#0d6efd,color:#000
    style Enable fill:#d1ecf1,stroke:#0c5460,color:#000
```
