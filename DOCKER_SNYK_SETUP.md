# Docker Build & Snyk Container Scanning Setup Guide

## Overview
This guide explains how to enable Docker image building and container scanning with Snyk in your Jenkins pipeline.

---

## 🔑 Required Credentials

### 1. Docker Hub Personal Access Token (PAT)

**What is it?**
- A secure token used instead of your Docker Hub password for authentication
- Required for Jenkins to push/pull Docker images to/from Docker Hub

**How to create it:**

1. **Log in to Docker Hub**
   - Go to https://hub.docker.com/
   - Sign in with your Docker Hub account

2. **Navigate to Security Settings**
   - Click your username (top-right corner)
   - Select **Account Settings**
   - Click **Security** in the left sidebar

3. **Create New Access Token**
   - Click **New Access Token**
   - **Description**: `Jenkins CI/CD` (or any descriptive name)
   - **Access permissions**: Select **Read, Write, Delete** (for full CI/CD access)
   - Click **Generate**

4. **Copy the Token**
   - ⚠️ **IMPORTANT**: Copy the token immediately - you won't be able to see it again!
   - Store it securely (you'll add it to Jenkins next)

**Token Format:**
```
dckr_pat_1234567890abcdefghijklmnopqrstuvwxyz
```

---

### 2. Snyk API Token

**What is it?**
- Authentication token for Snyk's vulnerability scanning service
- Required for both SCA (Software Composition Analysis) and container scanning

**How to create it:**

1. **Log in to Snyk**
   - Go to https://app.snyk.io/
   - Sign in or create a free account

2. **Navigate to Account Settings**
   - Click your username (bottom-left corner)
   - Select **Account settings**

3. **Get Your API Token**
   - Scroll to the **General** section
   - Find the **Auth Token** field
   - Click **Click to show**
   - Copy the token

**Token Format:**
```
12345678-1234-1234-1234-123456789abc
```

---

## 🔧 Jenkins Credential Setup

### Add Docker Hub Credentials

1. **Navigate to Jenkins Credentials**
   - Go to: **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**
   - Click on **(global)** domain
   - Click **Add Credentials**

2. **Configure Docker Hub Credential**
   - **Kind**: `Username with password`
   - **Scope**: `Global`
   - **Username**: Your Docker Hub username (e.g., `johndoe`)
   - **Password**: Paste your Docker Hub Personal Access Token (PAT)
   - **ID**: `dockerlogin` (must match Jenkinsfile)
   - **Description**: `Docker Hub PAT for CI/CD`
   - Click **Create**

### Add Snyk Token (if not already added)

1. **Add Snyk Credential**
   - Click **Add Credentials** again
   - **Kind**: `Secret text`
   - **Scope**: `Global`
   - **Secret**: Paste your Snyk API token
   - **ID**: `SNYK_TOKEN` (must match Jenkinsfile)
   - **Description**: `Snyk API Token for vulnerability scanning`
   - Click **Create**

---

## 🚀 Enable Docker Build in Pipeline

### Update Environment Variable

In `Jenkinsfile.docker`, change:
```groovy
BUILD_DOCKER = 'false'
```

To:
```groovy
BUILD_DOCKER = 'true'
```

---

## 📋 What Happens When Enabled

### Stage 1: Build Docker Image
```groovy
stage('Build Docker Image') {
    when {
        environment name: 'BUILD_DOCKER', value: 'true'
    }
    steps {
        withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
            script {
                app = docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
            }
        }
    }
}
```

**Actions:**
- Authenticates to Docker Hub using your PAT
- Builds Docker image from `easybuggy/Dockerfile`
- Tags image as `easybuggy:<BUILD_NUMBER>`

### Stage 2: Container Security Scan with Snyk
```groovy
stage('Container Security Scan with Snyk') {
    when {
        environment name: 'BUILD_DOCKER', value: 'true'
    }
    steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
            sh '''
                snyk auth $SNYK_TOKEN
                snyk container test ${DOCKER_IMAGE}:${BUILD_NUMBER} --severity-threshold=high || true
            '''
        }
    }
}
```

**Actions:**
- Authenticates to Snyk using your API token
- Scans the Docker image for vulnerabilities
- Reports vulnerabilities with severity HIGH or above
- `|| true` prevents build failure (for demo purposes)

---

## 🔍 Verification Steps

### 1. Verify Credentials in Jenkins
```bash
# Check that credentials exist
Jenkins → Manage Jenkins → Credentials → (global)
```

You should see:
- ✅ `dockerlogin` (Username with password)
- ✅ `SNYK_TOKEN` (Secret text)
- ✅ `SONAR_TOKEN` (Secret text)

### 2. Test Docker Hub Authentication
```bash
# On Jenkins container
docker login -u YOUR_USERNAME -p YOUR_PAT
```

### 3. Test Snyk Authentication
```bash
# On Jenkins container
snyk auth YOUR_TOKEN
snyk test --help
```

---

## 🎯 Expected Pipeline Flow

With `BUILD_DOCKER='true'`:

1. ✅ **Checkout** - Clone repository
2. ✅ **Build and SonarQube Analysis** - Maven build + code quality scan
3. ✅ **OWASP Dependency Check** - Dependency vulnerability scan
4. ✅ **Build Docker Image** - Create container image
5. ✅ **Container Security Scan with Snyk** - Scan Docker image
6. ✅ **SCA Scan with Snyk** - Scan source code dependencies
7. ✅ **IaC Security Scan with Checkov** - Scan Terraform files

---

## 🛠️ Troubleshooting

### Docker Hub Authentication Fails
**Error**: `unauthorized: incorrect username or password`

**Solutions**:
1. Verify you're using a **Personal Access Token**, not your password
2. Check token has **Read, Write, Delete** permissions
3. Verify credential ID is exactly `dockerlogin`
4. Regenerate token if expired

### Snyk Authentication Fails
**Error**: `Authentication failed. Please check your token`

**Solutions**:
1. Verify token is copied correctly (no extra spaces)
2. Check token hasn't been revoked in Snyk dashboard
3. Verify credential ID is exactly `SNYK_TOKEN`

### Docker Build Fails
**Error**: `Cannot connect to the Docker daemon`

**Solutions**:
1. Verify Docker socket is mounted: `/var/run/docker.sock:/var/run/docker.sock`
2. Check Jenkins user has Docker permissions
3. Restart Jenkins container

---

## 📊 Next Steps

After enabling Docker build:

1. **Push to Registry** (optional):
   ```groovy
   stage('Push to Docker Hub') {
       steps {
           script {
               docker.withRegistry('', 'dockerlogin') {
                   app.push("${BUILD_NUMBER}")
                   app.push("latest")
               }
           }
       }
   }
   ```

2. **Deploy Container** (optional):
   - Add deployment stage to Kubernetes/Docker Swarm
   - Use the built image for testing

3. **Monitor Vulnerabilities**:
   - Review Snyk dashboard: https://app.snyk.io/
   - Set up Snyk notifications
   - Create suppression rules for false positives

