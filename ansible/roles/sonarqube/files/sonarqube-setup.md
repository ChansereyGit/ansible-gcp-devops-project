# SonarQube Initial Setup

## Default Credentials

- **Username:** `admin`
- **Password:** `admin`

⚠️ **Important:** You will be forced to change the password on first login.

## Post-Installation Steps

1. **Login to SonarQube**
   - Navigate to: `https://sonarqube.konpapa.online`
   - Login with default credentials
   - Change the password when prompted

2. **Create Project**
   - Click "Create Project" 
   - Choose "Manually"
   - Enter project key and display name
   - Generate a token for the project

3. **Configure Jenkins Integration**
   - In Jenkins, install SonarQube Scanner plugin
   - Configure SonarQube server in Jenkins:
     - Manage Jenkins → Configure System → SonarQube servers
     - Add SonarQube server with URL and authentication token

4. **Configure Quality Gates**
   - Quality Gates → Create custom gate
   - Set conditions (e.g., Coverage > 80%, Bugs = 0)

## Useful Commands

```bash
# View SonarQube logs
docker logs sonarqube -f

# Restart SonarQube
cd ~/sonarqube
docker compose restart

# Check SonarQube status
docker compose ps

# Access PostgreSQL database
docker exec -it sonarqube-postgres psql -U sonar -d sonarqube
```

## Backup

```bash
# Backup PostgreSQL data
docker exec sonarqube-postgres pg_dump -U sonar sonarqube > sonarqube_backup.sql

# Restore
cat sonarqube_backup.sql | docker exec -i sonarqube-postgres psql -U sonar sonarqube
```

## Troubleshooting

If SonarQube won't start:
1. Check vm.max_map_count: `sysctl vm.max_map_count`
2. Should be at least 262144
3. If not: `sudo sysctl -w vm.max_map_count=262144`
