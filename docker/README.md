# DevSecOps Docker Environment

This Docker Compose setup provides a complete DevSecOps CI/CD environment for the easybuggy project.

## Architecture

The environment uses ephemeral Docker agents for pipeline execution, with no builds running on the Jenkins controller. Images are built using Kaniko (daemonless) and stored in a local Docker registry.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        Docker Compose Network                              │
├─────────────┬─────────────┬─────────────┬─────────────┬────────────────────┤
│  Jenkins    │  SonarQube  │  Registry   │  OWASP ZAP  │  Jenkins Agent     │
│  Controller │  Server     │  (local)    │  (DAST)     │  (ephemeral)       │
│  :8080      │  :9000      │  :5050      │  :8090      │  (dynamic)         │
└─────────────┴─────────────┴─────────────┴─────────────┴────────────────────┘
```

## Components

| Service           | Port | Purpose                                     |
|------------------|------|---------------------------------------------|
| **Jenkins**  | 8080 | CI/CD controller (no local builds)          |
| **SonarQube**  | 9000 | SAST - Code quality and security            |
| **Registry**  | 5050 | Local Docker image registry                 |
| **OWASP ZAP**  | 8090 | DAST - Dynamic security scanning            |
| **Jenkins Agent**  |-    | Ephemeral agent with DevSecOps tools        |

## Security Tools

| Tool | Type | Output Format |
|------|------|---------------|
| SonarQube | SAST | JSON (via API) |
| OWASP Dependency-Check | SCA | XML/JSON |
| Snyk | SCA + Container | JSON |
| Checkov | IaC | JSON |
| OWASP ZAP | DAST | JSON + HTML |

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
   - Registry: http://localhost:5050/v2/_catalog
   - ZAP API: http://localhost:8090

## Initial Setup

### SonarQube Configuration

1. Login to SonarQube (admin/admin) - you'll be prompted to change the password
2. Generate a project token:
   - Go to Administration > Security > Users
   - Click on "Tokens" for the admin user
   - Generate a new token named `jenkins`
   - Copy the token

### Jenkins Credentials

Add the following credentials in Jenkins (Manage Jenkins > Credentials):

| Credential ID | Type | Purpose | Required |
|---------------|------|---------|----------|
| `SONAR_TOKEN` | Secret text | SonarQube authentication | Yes |
| `SNYK_TOKEN`  | Secret text | Snyk SCA and container scanning | Yes |
| `NVD_API_KEY` | Secret text | OWASP Dependency-Check updates | Optional |

**Get API Keys:**
- **Snyk**: https://app.snyk.io/account
- **NVD**: https://nvd.nist.gov/developers/request-an-api-key

### Create a Pipeline Job

1. Create a new Pipeline job in Jenkins
2. Configure it to use `Jenkinsfile.docker` from your repository
3. Run the build!

## Pipeline Artifacts

All security scan results are archived as Jenkins artifacts and retained for 10 builds:

- `sonar-report.json` - SonarQube issues
- `dependency-check-report.xml` - OWASP Dependency-Check
- `snyk-sca-report.json` - Snyk SCA findings
- `snyk-container-report.json` - Snyk container scan
- `checkov-report.json` - Checkov IaC findings
- `zap-report.json` / `zap-report.html` - OWASP ZAP DAST results

## Stopping the Environment

```bash
docker-compose down
```

To remove all data (volumes):
```bash
docker-compose down -v
```
