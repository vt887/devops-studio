# Kubernetes Rules — DevOps Studio

Rules for the `k8s-spec` agent and all Kubernetes configuration in this project.

## Workload Security Standards

Every Pod/Deployment/StatefulSet must have:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000       # non-root UID
    fsGroup: 10000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
```

## Resource Requirements

Every container must define resources:

```yaml
resources:
  requests:
    cpu: "100m"      # Minimum guaranteed
    memory: "128Mi"
  limits:
    cpu: "500m"      # Maximum allowed
    memory: "512Mi"
```

## Required Labels

Every resource must have:
```yaml
labels:
  app: <service-name>
  version: <semver>
  environment: <dev|staging|prod>
  team: <team-name>
  managed-by: <helm|kustomize|manual>
```

## Probe Requirements

Every Deployment must have all three probes configured:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

## Image Policy

- **No `latest` tag** — always pin to specific digest or semver tag
- **Registry allowlist** — only use approved registries (define per project)
- **Image signing** — production images must be signed with Cosign

```yaml
# Good
image: myregistry.io/myapp:v1.2.3
# Good (digest)
image: myregistry.io/myapp@sha256:abc123...
# Bad
image: myapp:latest
```

## NetworkPolicy (required for production)

Every namespace must have a default-deny policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

Then explicitly allow required traffic only.

## RBAC Rules

- **No ClusterAdmin** without security-director approval
- **No wildcard verbs** in production (`*` in verbs)
- **ServiceAccount per workload** — never use the default ServiceAccount
- **Namespace-scoped Roles** preferred over ClusterRoles

## PodDisruptionBudget (required for production)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <service>-pdb
spec:
  minAvailable: 1  # or maxUnavailable: 1
  selector:
    matchLabels:
      app: <service>
```

## Namespace Strategy

- One namespace per environment per team
- Namespace names: `<team>-<env>` (e.g., `platform-prod`, `data-staging`)
- Resource quotas required on all namespaces

## Forbidden Patterns

- ❌ `hostNetwork: true` without documented justification
- ❌ `hostPID: true` or `hostIPC: true` without security-director approval
- ❌ `privileged: true` containers in production
- ❌ Missing resource limits (will be blocked by admission controller)
- ❌ Secrets mounted as environment variables (use volume mounts)
- ❌ EmptyDir volumes for sensitive data
