# Nexus Repository Manager - Setup Guide

## Initial Login

1. **Get Initial Password**
   ```bash
   cat ~/nexus/data/admin.password
   ```

2. **Login**
   - Navigate to: `https://nexus.konpapa.online`
   - Username: `admin`
   - Password: (from admin.password file)

3. **Complete Setup Wizard**
   - Change admin password
   - Configure anonymous access (recommend: disable for production)
   - Setup complete!

## Configure Docker Registry

### 1. Create Docker Hosted Repository

1. Go to Settings (gear icon) → Repositories → Create repository
2. Select "docker (hosted)"
3. Configure:
   - **Name:** `docker-hosted`
   - **HTTP Port:** `5000`
   - **Enable Docker V1 API:** ✓ (if needed)
   - **Allow anonymous docker pull:** ✓ (optional)
   - **Deployment policy:** Allow redeploy

### 2. Configure Docker Client

On your machine:
```bash
# Add insecure registry (for HTTP) in /etc/docker/daemon.json
{
  "insecure-registries": ["nexus.konpapa.online:5000"]
}

# Restart Docker
sudo systemctl restart docker

# Login to Nexus Docker Registry
docker login nexus.konpapa.online:5000
```

### 3. Push/Pull Images

```bash
# Tag image
docker tag myimage:latest nexus.konpapa.online:5000/myimage:latest

# Push to Nexus
docker push nexus.konpapa.online:5000/myimage:latest

# Pull from Nexus
docker pull nexus.konpapa.online:5000/myimage:latest
```

## Configure Maven Repository

### 1. Create Maven Repositories

Nexus comes with default Maven repositories:
- **maven-central** (proxy to Maven Central)
- **maven-releases** (hosted)
- **maven-snapshots** (hosted)
- **maven-public** (group - combines all)

### 2. Configure Maven Settings

Add to `~/.m2/settings.xml`:
```xml
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>your-password</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.konpapa.online/repository/maven-public/</url>
    </mirror>
  </mirrors>
</settings>
```

### 3. Configure in pom.xml

```xml
<distributionManagement>
  <repository>
    <id>nexus</id>
    <url>https://nexus.konpapa.online/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>nexus</id>
    <url>https://nexus.konpapa.online/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>
```

## Configure npm Registry

### 1. Create npm Repository

1. Create repository → npm (hosted)
2. Name: `npm-hosted`

### 2. Configure npm Client

```bash
# Set Nexus as registry
npm config set registry https://nexus.konpapa.online/repository/npm-hosted/

# Login
npm login --registry=https://nexus.konpapa.online/repository/npm-hosted/

# Publish
npm publish --registry=https://nexus.konpapa.online/repository/npm-hosted/
```

## Jenkins Integration

### Upload Artifacts from Jenkins

1. Install plugin: "Nexus Artifact Uploader"
2. Configure in Jenkins pipeline:

```groovy
nexusArtifactUploader(
  nexusVersion: 'nexus3',
  protocol: 'https',
  nexusUrl: 'nexus.konpapa.online',
  groupId: 'com.example',
  version: '1.0.0',
  repository: 'maven-releases',
  credentialsId: 'nexus-credentials',
  artifacts: [
    [artifactId: 'myapp',
     classifier: '',
     file: 'target/myapp.jar',
     type: 'jar']
  ]
)
```

## Useful Commands

```bash
# View Nexus logs
docker logs nexus -f

# Restart Nexus
cd ~/nexus
docker compose restart

# Check Nexus status
docker compose ps

# Backup Nexus data
sudo tar czf nexus-backup-$(date +%Y%m%d).tar.gz ~/nexus/data

# Restore
sudo tar xzf nexus-backup-YYYYMMDD.tar.gz -C /
```

## User Management

1. **Create Users**
   - Security → Users → Create local user
   - Assign roles (e.g., nx-deployment for uploading)

2. **Create Roles**
   - Security → Roles → Create role
   - Assign privileges

## Cleanup Policies

Configure to automatically delete old artifacts:
1. Repository → Cleanup Policies → Create
2. Set criteria (e.g., last downloaded > 30 days)
3. Apply to repositories

## Health Check

Check Nexus status:
```bash
curl -u admin:password https://nexus.konpapa.online/service/rest/v1/status
```

## Troubleshooting

**Nexus won't start:**
- Check available disk space
- Check logs: `docker logs nexus`
- Verify permissions on data directory
- Ensure ports 8081 and 5000 are not in use

**Can't access after domain setup:**
- Verify nginx configuration
- Check SSL certificate
- Ensure firewall allows ports 80, 443
