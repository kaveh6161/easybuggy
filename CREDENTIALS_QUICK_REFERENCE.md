# Jenkins Credentials Quick Reference

## 📋 Required Credentials Summary

| Credential Name | Type | Purpose | Where to Get It |
|----------------|------|---------|-----------------|
| **dockerlogin** | Username with password | Docker Hub authentication | https://hub.docker.com/ → Account Settings → Security → New Access Token |
| **SNYK_TOKEN** | Secret text | Snyk vulnerability scanning | https://app.snyk.io/ → Account settings → Auth Token |
| **SONAR_TOKEN** | Secret text | SonarQube code quality | http://localhost:9000 → My Account → Security → Generate Token |
| **NVD_API_KEY** | Secret text (optional) | NVD vulnerability database | https://nvd.nist.gov/developers/request-an-api-key |

---

## 🔐 Credential Details

### 1. Docker Hub Credentials (`dockerlogin`)

**Jenkins Configuration:**
```
Kind: Username with password
Scope: Global
Username: <your-docker-hub-username>
Password: <your-docker-hub-personal-access-token>
ID: dockerlogin
Description: Docker Hub PAT for CI/CD
```

**How to Create Docker Hub PAT:**
1. Go to https://hub.docker.com/
2. Login → Account Settings → Security
3. Click "New Access Token"
4. Description: `Jenkins CI/CD`
5. Permissions: **Read, Write, Delete**
6. Copy the token (starts with `dckr_pat_`)

**Token Format:**
```
dckr_pat_1234567890abcdefghijklmnopqrstuvwxyz
```

---

### 2. Snyk Token (`SNYK_TOKEN`)

**Jenkins Configuration:**
```
Kind: Secret text
Scope: Global
Secret: <your-snyk-api-token>
ID: SNYK_TOKEN
Description: Snyk API Token for vulnerability scanning
```

**How to Get Snyk Token:**
1. Go to https://app.snyk.io/
2. Sign in (or create free account)
3. Click your name (bottom-left) → Account settings
4. Scroll to "Auth Token" → Click to show
5. Copy the token

**Token Format:**
```
12345678-1234-1234-1234-123456789abc
```

---

### 3. SonarQube Token (`SONAR_TOKEN`)

**Jenkins Configuration:**
```
Kind: Secret text
Scope: Global
Secret: <your-sonarqube-token>
ID: SONAR_TOKEN
Description: SonarQube authentication token
```

**How to Create SonarQube Token:**
1. Go to http://localhost:9000
2. Login (default: admin/admin)
3. Click your avatar (top-right) → My Account
4. Click **Security** tab
5. Generate Token:
   - Name: `Jenkins`
   - Type: `User Token`
   - Expires: `No expiration` (or set expiry)
6. Click **Generate**
7. Copy the token immediately

**Token Format:**
```
squ_1234567890abcdefghijklmnopqrstuvwxyz
```

---

### 4. NVD API Key (`NVD_API_KEY`) - Optional

**Jenkins Configuration:**
```
Kind: Secret text
Scope: Global
Secret: <your-nvd-api-key>
ID: NVD_API_KEY
Description: NVD API Key for vulnerability database updates
```

**How to Get NVD API Key:**
1. Go to https://nvd.nist.gov/developers/request-an-api-key
2. Fill out the request form
3. Verify your email
4. Copy the API key from the email

**Token Format:**
```
12345678-1234-1234-1234-123456789abc
```

**Note:** Without this key, OWASP Dependency Check will use cached data only.

---

## ✅ Verification Checklist

### Before Running Pipeline:

- [ ] Docker Hub PAT created and added to Jenkins as `dockerlogin`
- [ ] Snyk token created and added to Jenkins as `SNYK_TOKEN`
- [ ] SonarQube token created and added to Jenkins as `SONAR_TOKEN`
- [ ] (Optional) NVD API key added to Jenkins as `NVD_API_KEY`
- [ ] `BUILD_DOCKER` set to `'true'` in Jenkinsfile.docker
- [ ] All credentials have **Global** scope
- [ ] Credential IDs match exactly (case-sensitive)

### Test Credentials:

```bash
# Test Docker Hub login
docker login -u YOUR_USERNAME -p YOUR_PAT

# Test Snyk authentication
snyk auth YOUR_TOKEN

# Test SonarQube connection
curl -u YOUR_TOKEN: http://localhost:9000/api/system/status
```

---

## 🚨 Common Issues

### Issue: "Credentials not found"
**Solution:** Verify credential ID matches exactly (case-sensitive)

### Issue: "Docker authentication failed"
**Solution:** Use Personal Access Token, not password

### Issue: "Snyk authentication failed"
**Solution:** Check token hasn't been revoked in Snyk dashboard

### Issue: "SonarQube 401 Unauthorized"
**Solution:** Regenerate token in SonarQube

---

## 📝 Adding Credentials via Jenkins UI

1. **Navigate to Credentials:**
   ```
   Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials (unrestricted)
   ```

2. **Click "Add Credentials"**

3. **Fill in the form** according to the tables above

4. **Click "Create"**

5. **Verify** the credential appears in the list

---

## 🔄 Rotating Credentials

### When to Rotate:
- Every 90 days (security best practice)
- When a team member leaves
- If credentials are accidentally exposed
- If you suspect compromise

### How to Rotate:

1. **Generate new token** in the respective service
2. **Update Jenkins credential**:
   - Go to credential → Click "Update"
   - Replace old token with new token
   - Click "Save"
3. **Test pipeline** to ensure it works
4. **Revoke old token** in the service

---

## 📚 Additional Resources

- **Docker Hub Tokens**: https://docs.docker.com/security/for-developers/access-tokens/
- **Snyk Authentication**: https://docs.snyk.io/snyk-api/authentication-for-api
- **SonarQube Tokens**: https://docs.sonarsource.com/sonarqube/latest/user-guide/user-account/generating-and-using-tokens/
- **NVD API**: https://nvd.nist.gov/developers/start-here

