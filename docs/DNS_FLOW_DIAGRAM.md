# DNS Setup Flow Diagram

## Overview: How DNS Works for Your Setup

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER BROWSER                                    │
│              https://jenkins.konpapa.online                             │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ 1. DNS Query: What is jenkins.konpapa.online?
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        NAMECHEAP DNS SERVERS                            │
│                     (dns1.registrar-servers.com)                        │
│                                                                          │
│  DNS Records for konpapa.online:                                        │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ A Record | jenkins    | 34.142.147.236                      │      │
│  │ A Record | sonarqube  | 34.21.213.214                       │      │
│  │ A Record | nexus      | 34.21.132.214                       │      │
│  └──────────────────────────────────────────────────────────────┘      │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ 2. DNS Response: 34.142.147.236
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER BROWSER                                    │
│         Connects to https://34.142.147.236 (Jenkins VM)                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ 3. HTTPS Request
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     GCP JENKINS VM (34.142.147.236)                     │
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────┐                     │
│  │  Nginx (Port 80) │◄────────┤ Let's Encrypt SSL│                     │
│  │  Nginx (Port 443)│         └──────────────────┘                     │
│  └────────┬─────────┘                                                   │
│           │                                                              │
│           │ 4. Reverse Proxy to Jenkins                                 │
│           ▼                                                              │
│  ┌──────────────────┐                                                   │
│  │  Jenkins         │                                                   │
│  │  (Port 8080)     │                                                   │
│  └──────────────────┘                                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Step-by-Step DNS Resolution

### Before DNS Configuration ❌

```
User Types: https://jenkins.konpapa.online
      ↓
DNS Query: jenkins.konpapa.online
      ↓
Namecheap DNS: No record found
      ↓
Error: DNS_PROBE_FINISHED_NXDOMAIN (Domain doesn't exist)
```

### After DNS Configuration ✅

```
User Types: https://jenkins.konpapa.online
      ↓
DNS Query: jenkins.konpapa.online
      ↓
Namecheap DNS: Returns 34.142.147.236
      ↓
Browser: Connects to 34.142.147.236:443
      ↓
Nginx: Receives HTTPS request with Host: jenkins.konpapa.online
      ↓
Nginx: Proxies to localhost:8080 (Jenkins)
      ↓
Jenkins: Returns web page
      ↓
User: Sees Jenkins login page
```

## Complete Architecture with All 3 Services

```
                        Internet
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        │                  │                  │
   jenkins.konpapa     sonarqube.konpapa  nexus.konpapa
   .online (DNS)       .online (DNS)      .online (DNS)
        │                  │                  │
        ▼                  ▼                  ▼
   34.142.147.236     34.21.213.214      34.21.132.214
        │                  │                  │
        │                  │                  │
┌───────▼──────────┐ ┌─────▼───────────┐ ┌───▼──────────┐
│   Jenkins VM     │ │  SonarQube VM   │ │  Nexus VM    │
│   (GCP)          │ │  (GCP)          │ │  (GCP)       │
│                  │ │                 │ │              │
│ Nginx:80,443 ─┐  │ │ Nginx:80,443 ─┐ │ │Nginx:80,443─┐│
│       │       │  │ │       │       │ │ │      │      ││
│       ▼       │  │ │       ▼       │ │ │      ▼      ││
│ Jenkins:8080  │  │ │SonarQube:9000 │ │ │Nexus:8081   ││
│               │  │ │PostgreSQL:5432│ │ │Nexus:5000   ││
│ Docker        │  │ │Docker         │ │ │Docker       ││
└───────────────┘  └─────────────────┘ └───────────────┘
```

## What Happens When You Add DNS Records

### Timeline

```
T=0min    You add A records in Namecheap
          ↓
T=1min    Namecheap DNS servers update
          ↓
T=5min    Root DNS servers start propagating
          ↓
T=10min   Most ISP DNS servers have the update
          ↓
T=30min   Global DNS propagation mostly complete
          ↓
T=1-2hr   99% of DNS servers worldwide updated
```

### Testing at Different Stages

```bash
# T=0-5min: Probably not working yet
$ dig jenkins.konpapa.online +short
(no output or old IP)

# T=10-15min: Should start working
$ dig jenkins.konpapa.online +short
34.142.147.236

# T=30min: Definitely working
$ curl -I https://jenkins.konpapa.online
HTTP/2 200 OK
```

## Common DNS Issues

### Issue 1: Wrong IP Address

```
┌─────────────────────────────────────┐
│ Namecheap DNS Record (WRONG)        │
│                                     │
│ A Record | jenkins | 10.148.0.2    │ ← Internal IP (WRONG!)
│                                     │
└─────────────────────────────────────┘

User tries to connect to 10.148.0.2 → FAILS (internal IP not accessible)
```

**Solution:** Use EXTERNAL IP (34.x.x.x, not 10.x.x.x)

### Issue 2: Typo in Host Field

```
┌─────────────────────────────────────┐
│ Namecheap DNS Record (WRONG)        │
│                                     │
│ A Record | jenkin | 34.142.147.236 │ ← Missing 's' (WRONG!)
│                                     │
└─────────────────────────────────────┘

jenkins.konpapa.online → DNS_PROBE_FINISHED_NXDOMAIN
jenkin.konpapa.online  → Works (but wrong URL)
```

**Solution:** Double-check spelling: `jenkins`, `sonarqube`, `nexus`

### Issue 3: Using Custom Nameservers

```
┌─────────────────────────────────────┐
│ Domain: konpapa.online              │
│ Nameservers: Cloudflare (WRONG)     │
│   - dns1.cloudflare.com             │
│   - dns2.cloudflare.com             │
└─────────────────────────────────────┘

You add records in Namecheap → Records ignored!
(Cloudflare is managing DNS, not Namecheap)
```

**Solution:** Use Namecheap BasicDNS nameservers

## Quick Commands Reference

```bash
# 1. Get your VM IPs
cat ~/ansible-gcp-devops-project/ansible/inventory/hosts.ini

# 2. Test DNS resolution (after adding records)
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short

# 3. Test with specific DNS server (Google DNS)
nslookup jenkins.konpapa.online 8.8.8.8

# 4. Check DNS propagation status
# Visit: https://dnschecker.org
# Enter: jenkins.konpapa.online

# 5. Test HTTP connectivity
curl -I http://jenkins.konpapa.online
curl -I http://sonarqube.konpapa.online
curl -I http://nexus.konpapa.online

# 6. Test HTTPS (after SSL setup)
curl -I https://jenkins.konpapa.online
```

## Summary Checklist

Before configuring DNS:
- ✅ 3 VMs created on GCP
- ✅ Know external IP of each VM
- ✅ Have Namecheap account credentials
- ✅ Domain konpapa.online registered

DNS Configuration Steps:
- ✅ Login to Namecheap
- ✅ Go to Advanced DNS
- ✅ Add A record for jenkins → Jenkins VM IP
- ✅ Add A record for sonarqube → SonarQube VM IP
- ✅ Add A record for nexus → Nexus VM IP
- ✅ Click Save All Changes
- ✅ Wait 10-30 minutes
- ✅ Test with dig/nslookup

After DNS works:
- ✅ Run configuration playbook: `ansible-playbook playbooks/03-configure-all.yaml`
- ✅ Setup SSL: `ansible-playbook playbooks/setup-ssl.yaml`
- ✅ Access services via HTTPS
