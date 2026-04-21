# Security Rules — DevOps Studio

Rules for the `security-director` and `security-scanner` agents. Security standards for all infrastructure.

## Core Security Principles

1. **Zero Trust** — No implicit trust. Every request authenticated and authorized.
2. **Least Privilege** — Minimum permissions required, nothing more.
3. **Defense in Depth** — Multiple security layers; no single point of failure.
4. **Shift Left** — Security in design and CI/CD, not just operations.
5. **Assume Breach** — Design for containment and minimal blast radius.

## IAM Standards

### AWS IAM
- No root account usage for operations (only for billing/recovery)
- MFA required for all human IAM users
- IAM roles for all service-to-service auth (no long-lived keys)
- OIDC federation for CI/CD pipelines
- No inline policies — use managed policies
- Permission boundaries for delegated admin

### Kubernetes RBAC
- No ClusterAdmin bindings for service accounts
- Use Roles (namespace-scoped) over ClusterRoles
- ServiceAccount per workload
- Minimal verb set per role

## Secrets Management

### Requirements
- **No secrets in git** — ever, even encrypted
- Secrets at rest: encrypted with customer-managed keys (KMS/CMEK)
- Secret rotation: automated, max 90-day rotation for service credentials
- Access logging: all secret access logged

### Approved Secrets Solutions
- HashiCorp Vault (preferred for multi-cloud)
- AWS Secrets Manager (AWS-native)
- GCP Secret Manager (GCP-native)
- Azure Key Vault (Azure-native)

### Forbidden
- Environment variables with plaintext secrets in container specs
- ConfigMaps with secret values
- .env files committed to git
- Hardcoded credentials anywhere

## Network Security

### Ingress
- All external traffic through WAF
- TLS 1.2 minimum (TLS 1.3 preferred)
- No direct SSH to production (use session manager/bastion)
- Allowlist-based ingress (deny all, allow specific)

### Egress
- Explicit egress rules (deny all by default in production)
- DNS filtering for production workloads
- No unrestricted internet access for data-processing workloads

### Kubernetes NetworkPolicy
- Default-deny policy in all namespaces
- Explicit allow policies per service pair
- No NetworkPolicy with empty podSelector + empty namespaceSelector (allows all)

## Encryption Standards

### At Rest
- AES-256 minimum
- Customer-managed keys for sensitive data
- Encryption enabled on: EBS, S3, RDS, ElasticSearch, backups

### In Transit
- TLS 1.2+ everywhere (TLS 1.3 preferred)
- mTLS for service-to-service in production (service mesh)
- No plain HTTP in production

## Vulnerability Management

### Scan Frequency
- Container images: every build + weekly scheduled scan
- IaC: every PR + weekly scheduled scan
- Dependencies: every build + daily scheduled scan
- Git history: weekly secrets scan

### SLA for Remediation
| Severity | Time to Remediate |
|----------|-------------------|
| Critical | 24 hours          |
| High     | 7 days            |
| Medium   | 30 days           |
| Low      | 90 days           |

## Compliance Controls

### Audit Logging (always required)
- Cloud provider audit logs (CloudTrail/Cloud Audit Logs)
- Kubernetes audit logs
- Application access logs
- Log retention: minimum 1 year (7 years for PCI/HIPAA)

### Incident Response
- Security incidents escalated immediately to security-director
- Incident declared within 15 minutes of confirmed security event
- Breach notification per applicable regulation (GDPR 72h, etc.)

## Security Review Triggers

A security review (spawn security-director) is REQUIRED when:
- New cloud resources with public internet exposure
- IAM role/policy changes
- Network topology changes
- New secrets or credential types introduced
- Third-party integrations added
- Compliance scope changes

## Forbidden Patterns

- ❌ Public S3 buckets (unless CDN/static site with explicit approval)
- ❌ Security groups with 0.0.0.0/0 ingress on port 22 or 3389
- ❌ Unencrypted data stores
- ❌ Wildcard IAM actions on sensitive resources
- ❌ Credentials in environment variables (use secrets manager)
- ❌ Self-signed certificates in production
- ❌ Container images running as root
- ❌ `privileged: true` in production Kubernetes pods
