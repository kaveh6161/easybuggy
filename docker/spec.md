# Technical Specification: Enhanced DevSecOps Pipeline

## Context

Enhance the existing Jenkins DevSecOps pipeline for the easybuggy project to:
1. Use ephemeral Docker agents instead of running jobs on the Jenkins master
2. Archive all security scan results as artifacts (not just console output)
3. Add DAST testing using OWASP ZAP against the running application

The current pipeline runs on Jenkins master with tools installed directly in the Jenkins container. This specification migrates to a more secure, scalable architecture using Kaniko for daemonless image builds and a local Docker registry.

## Specification

### Architecture Overview

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                        Docker Compose Network                                 │
├─────────────┬─────────────┬────────────────────┬─────────────┬────────────────┤
│  Jenkins    │  SonarQube  │  Registry          │  Jenkins    │  easybuggy     │
│  Controller │  Server     │  (registry:2)      │  Agent     │  (ephemeral)   │
│  :8080    │  :9000      │  :5000      │  (dynamic)  │  :8080         │
└─────────────┴─────────────┴────────────────────┴─────────────┴────────────────┘
```

### Core Technical Approach

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Jenkins Agent** | Custom Docker image | Ephemeral build agent with all DevSecOps tools |
| **Image Building** | Kaniko | Daemonless, rootless container image builds |
| **Image Registry** | registry:2 | Local Docker registry for built images |
| **DAST Scanner** | OWASP ZAP | Full active security scan of running application |
| **Artifact Format** | JSON / JUnit XML | Machine-readable security scan reports |

### Security Tools & Output Formats

| Tool | Scan Type | Output Format | Artifact Name |
|------|-----------|---------------|---------------|
| SonarQube | SAST | Push to server + JSON export | `sonar-report.json` |
| OWASP Dependency-Check | SCA | XML (JUnit compatible) | `dependency-check-report.xml` |
| Snyk | SCA | JSON | `snyk-sca-report.json` |
| Snyk Container | Container Scan | JSON | `snyk-container-report.json` |
| Checkov | IaC | JSON | `checkov-report.json` |
| OWASP ZAP | DAST | JSON + HTML | `zap-report.json`, `zap-report.html` |

## Requirements

### Functional Requirements

1. **FR-1**: Pipeline jobs MUST execute on ephemeral Docker agents, not Jenkins master
2. **FR-2**: Jenkins master MUST have `numExecutors: 0` (no local builds)
3. **FR-3**: All security scan results MUST be archived as Jenkins artifacts
4. **FR-4**: Artifacts MUST be retained for the last 10 builds
5. **FR-5**: All security scans MUST soft-fail (report but don't break build)
6. **FR-6**: DAST stage MUST deploy easybuggy container, scan with ZAP, then tear down
7. **FR-7**: ZAP MUST perform a full active scan (not baseline)
8. **FR-8**: Independent stages (Snyk SCA, Checkov) SHOULD run in parallel
9. **FR-9**: Docker images MUST be built using Kaniko (no Docker socket/DinD)
10. **FR-10**: Built images MUST be pushed to local registry at `registry:5000`

### Non-Functional Requirements

1. **NFR-1**: No Docker socket mounting or DinD for security
2. **NFR-2**: Agent image MUST be pre-built and available in docker-compose
3. **NFR-3**: Registry MUST be accessible within the docker-compose network
4. **NFR-4**: ZAP scan timeout MUST be configurable (default: 20 minutes)
5. **NFR-5**: All containers MUST have resource limits (CPU/memory) defined
6. **NFR-6**: Pipeline MUST switch agents mid-pipeline (Kaniko agent for build, custom agent for other stages)
7. **NFR-7**: SonarQube results SHOULD be exported via API as JSON artifact (best-effort)

## Expected Output

### Files to Create

| File | Purpose |
|------|---------|
| `easybuggy/docker/agent/Dockerfile` | Custom Jenkins agent with all DevSecOps tools |
| `easybuggy/docker/kaniko/config.json` | Kaniko registry configuration |

### Files to Modify

| File | Changes |
|------|---------|
| `easybuggy/docker/docker-compose.yml` | Add registry service, agent build, ZAP service |
| `easybuggy/docker/jenkins/Dockerfile` | Remove build tools (keep minimal for controller) |
| `easybuggy/docker/jenkins/casc_configs/jenkins.yaml` | Configure Docker cloud for agents, set numExecutors=0 |
| `easybuggy/docker/jenkins/plugins.txt` | Add any missing plugins for artifacts/agents |
| `easybuggy/Jenkinsfile.docker` | Rewrite with agent blocks, Kaniko, artifacts, ZAP stage |

## Constraints & Edge Cases

### Security Constraints

- **No Docker Socket**: Agent cannot mount `/var/run/docker.sock`
- **No DinD**: Agent cannot run Docker daemon inside container
- **No Privileged Mode**: Avoid `--privileged` flag where possible
- **Credential Isolation**: Secrets accessed only in stages that need them

### Technical Constraints

- **Kaniko Limitations**: Cannot run containers; only builds images
- **ZAP Container**: Must be started separately to scan easybuggy
- **Network Dependency**: All containers must be on `devsecops-network`
- **Registry Insecure**: Local registry uses HTTP (add to Kaniko/Docker insecure registries)

### Edge Cases

| Scenario | Handling |
|----------|----------|
| ZAP scan exceeds timeout | Fail gracefully, archive partial results |
| Registry unavailable | Pipeline fails at image push stage |
| easybuggy fails to start | DAST stage fails, other stages unaffected |
| Snyk token missing | Skip Snyk stages with warning |
| SonarQube unavailable | SAST stage fails, continue pipeline |

## Remarks

### Pipeline Stage Flow (Revised)

```
Checkout → Build & Test → SonarQube Analysis → OWASP Dep-Check
                                                      ↓
                              ┌───────────────────────┴───────────────────────┐
                              ↓                                               ↓
                    Snyk SCA Scan (parallel)                      Checkov IaC Scan (parallel)
                              ↓                                               ↓
                              └───────────────────────┬───────────────────────┘
                                                      ↓
                                        Build Image (Kaniko)
                                                      ↓
                                        Push to Registry
                                                      ↓
                                        Snyk Container Scan
                                                      ↓
                                    Deploy easybuggy Container
                                                      ↓
                                        ZAP DAST Scan
                                                      ↓
                                    Teardown & Archive Artifacts
```

### Future Enhancements

- Replace `registry:2` with Nexus for Maven dependency caching
- Add SARIF format export for GitHub Security integration
- Add Trivy as alternative container scanner

### References

- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [OWASP ZAP Docker](https://www.zaproxy.org/docs/docker/)
- [Jenkins Docker Agent Plugin](https://plugins.jenkins.io/docker-plugin/)
- [Jenkins Artifact Archiving](https://www.jenkins.io/doc/pipeline/steps/core/#archiveartifacts-archive-the-artifacts)

