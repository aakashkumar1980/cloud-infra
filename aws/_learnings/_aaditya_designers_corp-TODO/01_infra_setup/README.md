# Aaditya Designers Corp - Infrastructure Setup

Enterprise infrastructure for Aaditya Designers Corp with hybrid identity management.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Component Concepts](#component-concepts)
4. [Phase 1: Security Foundation](#phase-1-security-foundation)
5. [Phase 2: AD Infrastructure](#phase-2-ad-infrastructure)
6. [Phase 3: Identity Governance](#phase-3-identity-governance)
7. [Phase 4: Applications](#phase-4-applications)
8. [Phase 5: Monitoring & Backup](#phase-5-monitoring--backup)
9. [Phase 6: Azure Integration](#phase-6-azure-integration)
10. [Users](#users)
11. [Usage](#usage)

---

## Prerequisites

This module depends on the following infrastructure being deployed **FIRST**:

```
Step 1: Base Network
        cd aws/base_network
        terraform apply -var="profile=dev"

Step 2: VPC Peering (Same Region)
        cd aws/_learnings/vpc_connectivity/01_vpc_peering/01_same_region
        terraform apply -var="profile=dev"

Step 3: VPC Peering (Cross Region)
        cd aws/_learnings/vpc_connectivity/01_vpc_peering/02_different_region
        terraform apply -var="profile=dev"

Step 4: This Module (01_infra_setup)
        cd aws/_learnings/_aaditya_designers_corp/01_infra_setup
        terraform apply -var="profile=dev"
```

**Or use the automation scripts:**
- Linux/Mac: `./scripts/deploy.sh`
- Windows: `.\scripts\deploy.ps1`

---

## Architecture Overview

```
+-----------------------------------------------------------------------------+
|                         N. VIRGINIA (us-east-1)                              |
|                              VPC A (10.0.0.0/24)                             |
|  +-----------------------------------------------------------------------+  |
|  |  Private Subnet (10.0.0.32/27)                                        |  |
|  |  +-----------------------------+                                      |  |
|  |  |  Windows Server (AD DS)     |                                      |  |
|  |  |  - Active Directory         |                                      |  |
|  |  |  - Certificate Services     |                                      |  |
|  |  |  - DNS Server               |                                      |  |
|  |  +-----------------------------+                                      |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
                                    |
                           VPC Peering (Active)
                                    |
+-----------------------------------------------------------------------------+
|                           LONDON (eu-west-2)                                 |
|                            VPC C (192.168.0.0/26)                            |
|  +-----------------------------------------------------------------------+  |
|  |  Private Subnet (192.168.0.16/28)                                     |  |
|  |  +---------------------+  +---------------------+                     |  |
|  |  | Identity Server     |  | App Server          |                     |  |
|  |  | - Keycloak (SSO)    |  | - GitLab CE         |                     |  |
|  |  | - Apache Syncope    |  | - Wiki.js           |                     |  |
|  |  +---------------------+  +---------------------+                     |  |
|  +-----------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------+
```

---

## Component Concepts

### 1. AWS KMS (Key Management Service)

**What:** A managed service for creating and controlling encryption keys.

**Why Needed:**
- Encrypts EBS volumes (protects data at rest)
- Encrypts secrets in Secrets Manager
- Encrypts CloudWatch logs
- Provides audit trail of key usage

**How It Works:**
```
+------------------+
|  KMS Master Key  |  <-- Never leaves AWS, managed securely
+--------+---------+
         |
         v Generates
+------------------+
|   Data Key       |  <-- Used to encrypt your actual data
+--------+---------+
         |
         v Encrypts
+------------------+
|  EBS Volume      |  <-- Data encrypted at rest
|  (Your Data)     |
+------------------+
```

**Cost:** ~$1/month per key

---

### 2. AWS Secrets Manager

**What:** Secure storage for sensitive credentials like passwords, API keys, and certificates.

**Why Needed:**
- No hardcoded passwords in code or scripts
- Automatic password generation
- Encrypted with KMS
- Audit trail of access
- Can rotate secrets automatically

**How It Works:**
```
+------------+     PUT      +------------------+
| Terraform  | -----------> | Secrets Manager  |
| (DevOps)   |              | /aaditya/ad/pw   |
+------------+              +--------+---------+
                                     | Encrypted
                                     v
                            +------------------+
                            | Encrypted Secret |
                            +------------------+
                                     ^
+------------+     GET               |
| EC2        | ----------------------+
| (AD Server)| <-- Decrypted at runtime via IAM Role
+------------+
```

**Cost:** ~$0.40/secret/month

---

### 3. IAM Roles & Policies

**What:** Identity and permissions that AWS services (like EC2) can assume.

**Why Needed:**
- No hardcoded AWS credentials on EC2 instances
- Temporary credentials (auto-rotated)
- Least privilege access
- Audit trail via CloudTrail

**How It Works:**
```
+------------------+
| IAM Role         |
| "ad-server-role" |
+--------+---------+
         |
         | Attached to
         v
+------------------+     Assume Role    +------------------+
| EC2 Instance     | -----------------> | AWS STS          |
| (AD Server)      |                    | Temp Credentials |
+------------------+                    +------------------+
         |
         | Can access (per policy)
         v
+------------------+
| Secrets Manager  | <-- Only /aaditya/ad/* secrets
| CloudWatch Logs  | <-- Only aaditya-* log groups
+------------------+
```

**Cost:** FREE

---

### 4. Security Groups

**What:** Virtual firewalls that control inbound and outbound traffic to EC2 instances.

**Why Needed:**
- Network-level security
- Only allow required ports
- Micro-segmentation between services
- Defense in depth

**How It Works:**
```
+------------------------------------------------------------------+
|                     Security Group Rules                          |
|                                                                   |
|  AD Server (sg-ad-server):                                       |
|  +------------------+--------+---------------------+             |
|  | Port             | Proto  | Source              |             |
|  +------------------+--------+---------------------+             |
|  | 389 (LDAP)       | TCP    | VPC CIDR only      |             |
|  | 636 (LDAPS)      | TCP    | VPC CIDR only      |             |
|  | 88 (Kerberos)    | TCP/UDP| VPC CIDR only      |             |
|  | 53 (DNS)         | TCP/UDP| VPC CIDR only      |             |
|  | 3389 (RDP)       | TCP    | Bastion/SSM only   |             |
|  +------------------+--------+---------------------+             |
|                                                                   |
|  App Server (sg-app-server):                                     |
|  +------------------+--------+---------------------+             |
|  | Port             | Proto  | Source              |             |
|  +------------------+--------+---------------------+             |
|  | 443 (HTTPS)      | TCP    | VPC CIDR only      |             |
|  | 22 (SSH)         | TCP    | Bastion/SSM only   |             |
|  +------------------+--------+---------------------+             |
+------------------------------------------------------------------+
```

**Cost:** FREE

---

### 5. Active Directory Domain Services (AD DS)

**What:** Microsoft's directory service for Windows domain networks.

**Why Needed:**
- Centralized user authentication
- Group Policy management
- Kerberos authentication for Windows machines
- LDAP directory for applications

**How It Works:**
```
+------------------+     Kerberos     +------------------+
| Windows Desktop  | ---------------> | AD DS Server     |
| (Domain-joined)  |                  | (Domain Controller)|
+------------------+                  +------------------+
         ^                                    |
         |                                    |
         +------------------------------------+
              Group Policy, User Auth, DNS
```

---

### 6. Active Directory Certificate Services (AD CS)

**What:** Microsoft's PKI (Public Key Infrastructure) for issuing digital certificates.

**Why Needed:**
- Free internal SSL/TLS certificates
- Auto-enrollment for domain machines
- Certificates for LDAPS, HTTPS, code signing
- No need for expensive public CA for internal services

**How It Works:**
```
+------------------+     Request Cert    +------------------+
| GitLab Server    | ------------------> | AD CS            |
|                  |                     | (Internal CA)    |
+------------------+                     +------------------+
         |                                       |
         | <-------------------------------------+
         |           Certificate Issued
         v
+------------------+
| GitLab with SSL  |  <-- Trusted by all domain machines
+------------------+
```

---

### 7. Keycloak

**What:** Open-source Identity and Access Management (IAM) solution.

**Why Needed:**
- Single Sign-On (SSO) across applications
- Supports SAML, OIDC, OAuth 2.0
- Federates with AD DS via LDAP
- MFA support
- User self-service

**How It Works:**
```
+------------------+     Login      +------------------+
| User             | -------------> | Keycloak         |
| (Browser)        |                | (SSO Portal)     |
+------------------+                +--------+---------+
                                             |
                                             | LDAP Auth
                                             v
                                    +------------------+
                                    | AD DS            |
                                    +------------------+
                                             |
         +-----------------------------------+
         |           Token Issued
         v
+------------------+     Token      +------------------+
| User             | -------------> | GitLab/Wiki.js   |
| (Browser)        |                | (SSO Login)      |
+------------------+                +------------------+
```

---

### 8. Apache Syncope

**What:** Open-source Identity Governance and Administration (IGA) platform.

**Why Needed:**
- Access request portal (like SailPoint IIQ)
- Approval workflows
- Automated provisioning to applications
- Access certification/reviews
- Compliance and audit

**How It Works:**
```
+------------------+     Request Access   +------------------+
| Employee         | ------------------> | Apache Syncope   |
| (akhila)         |  "I need GitLab"    | (Request Portal) |
+------------------+                     +--------+---------+
                                                  |
                                                  | Approval Request
                                                  v
                                         +------------------+
                                         | Manager (aakash) |
                                         | Approves         |
                                         +--------+---------+
                                                  |
                                                  | Auto-Provision
                                                  v
                                         +------------------+
                                         | GitLab           |
                                         | (Account Created)|
                                         +------------------+
```

---

### 9. GitLab CE

**What:** Open-source Git repository management and CI/CD platform.

**Why Needed:**
- Source code management
- Merge/Pull requests
- Built-in CI/CD pipelines
- Issue tracking
- Container registry

---

### 10. Wiki.js

**What:** Modern open-source wiki/documentation platform.

**Why Needed:**
- Internal documentation
- Knowledge base
- Markdown support
- Full-text search
- Access control per page

---

## Phase 1: Security Foundation

| Component | Description | Cost |
|-----------|-------------|------|
| KMS | Encryption keys for EBS, Secrets | ~$1/month |
| Secrets Manager | Secure credential storage | ~$2.40/month |
| IAM Roles | EC2 instance permissions | FREE |
| Security Groups | Network firewalls | FREE |

**Total: ~$3.40/month**

---

## Phase 2: AD Infrastructure

| Component | Description | Cost |
|-----------|-------------|------|
| Windows EC2 | t3.small in N. Virginia | ~$15-20/month |
| AD DS | Domain Controller | Included |
| AD CS | Certificate Authority | Included |
| DNS | Integrated with AD | Included |

---

## Phase 3: Identity Governance

| Component | Description | Cost |
|-----------|-------------|------|
| Linux EC2 | t3.small in London | ~$8-10/month |
| Keycloak | SSO and Authentication | FREE |
| Apache Syncope | Access Request Portal | FREE |

---

## Phase 4: Applications

| Component | Description | Cost |
|-----------|-------------|------|
| Linux EC2 | t3.small in London | ~$8-10/month |
| GitLab CE | Git repository + CI/CD | FREE |
| Wiki.js | Documentation platform | FREE |

---

## Phase 5: Monitoring & Backup

| Component | Description | Cost |
|-----------|-------------|------|
| CloudWatch Logs | Centralized logging | ~$0.50/GB |
| CloudWatch Alarms | Alerting | ~$0.10/alarm |
| AWS Backup | Automated snapshots | Storage cost |

---

## Phase 6: Azure Integration

| Component | Description | Cost |
|-----------|-------------|------|
| Azure AD | Cloud identity | FREE tier |
| Azure AD Connect | Hybrid sync | FREE |
| Microsoft 365 | Email (optional) | Trial/Paid |

---

## Users

| Username | Full Name | Role |
|----------|-----------|------|
| aakash.kumar | Aakash Kumar | Admin |
| akhila.bezawada | Akhila Bezawada | Developer |

---

## Usage

### Using Automation Scripts (Recommended)

**Linux/Mac:**
```bash
# Deploy all infrastructure
./scripts/deploy.sh apply dev

# Destroy all infrastructure
./scripts/deploy.sh destroy dev

# Plan only (dry run)
./scripts/deploy.sh plan dev
```

**Windows:**
```powershell
# Deploy all infrastructure
.\scripts\deploy.ps1 -Action apply -Profile dev

# Destroy all infrastructure
.\scripts\deploy.ps1 -Action destroy -Profile dev

# Plan only (dry run)
.\scripts\deploy.ps1 -Action plan -Profile dev
```

### Manual Execution

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var="profile=dev"

# Apply changes
terraform apply -var="profile=dev"

# Destroy (when done)
terraform destroy -var="profile=dev"
```
