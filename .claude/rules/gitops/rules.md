# GitOps Rules — DevOps Studio

Rules for the `gitops-spec` agent and all GitOps configuration in this project.

## Core GitOps Principles

1. **Declarative** — The entire system is described declaratively in Git
2. **Versioned** — Desired state is versioned in Git (immutable, auditable)
3. **Automated** — Approved changes are applied automatically by a controller
4. **Continuous** — Agents continuously observe and reconcile actual vs desired state

## Repository Structure

### Recommended: Mono-repo structure

```
gitops/
├── clusters/
│   ├── prod/
│   │   ├── flux-system/     # Flux bootstrap
│   │   └── apps/            # Application Kustomizations
│   └── staging/
│       ├── flux-system/
│       └── apps/
├── infrastructure/
│   ├── base/                # Shared infrastructure (cert-manager, ingress, etc.)
│   └── overlays/
│       ├── prod/
│       └── staging/
└── apps/
    ├── <service-a>/
    │   ├── base/
    │   └── overlays/
    └── <service-b>/
```

## Flux CD Rules

### HelmRelease requirements

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <release-name>
  namespace: <namespace>
spec:
  interval: 10m          # Reconcile every 10 minutes
  chart:
    spec:
      chart: <chart-name>
      version: ">=1.0.0 <2.0.0"  # Pin to major version
      sourceRef:
        kind: HelmRepository
        name: <repo-name>
  install:
    remediation:
      retries: 3         # Retry failed installs
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true  # Auto-remediate on failure
  values:
    <values>
```

### Kustomization requirements

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: <name>
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./gitops/apps/<service>/overlays/<env>
  prune: true            # Delete removed resources
  wait: true             # Wait for resources to be ready
  healthChecks:          # Define health checks
    - apiVersion: apps/v1
      kind: Deployment
      name: <name>
      namespace: <namespace>
  timeout: 5m
```

## ArgoCD Rules (if ArgoCD used instead of Flux)

### Application requirements

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <name>
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # Cascade delete
spec:
  project: <project-name>    # Never use 'default' project in production
  source:
    repoURL: <git-url>
    targetRevision: HEAD
    path: <path>
  destination:
    server: https://kubernetes.default.svc
    namespace: <namespace>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=false  # Namespaces managed separately
      - PrunePropagationPolicy=foreground
    retry:
      limit: 5
      backoff:
        duration: 5s
        maxDuration: 3m
```

## Sync Policies

| Environment | Sync Mode | Prune | Self-Heal | Approval |
|-------------|-----------|-------|-----------|----------|
| dev         | Automated | Yes   | Yes       | None |
| staging     | Automated | Yes   | Yes       | None |
| prod        | Automated | Yes   | Yes       | PR review required |

Production changes ALWAYS require:
1. Pull Request with at least 1 approval
2. CI pipeline passing (including security scan)
3. Successful staging deployment first

## Image Automation (Flux)

```yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: flux-system
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxbot@myorg.com
        name: FluxBot
      messageTemplate: "chore(gitops): update {{range .Updated.Images}}{{println .}}{{end}}"
    push:
      branch: gitops/image-updates  # Push to branch, not main directly
```

## Notification Requirements

Configure notifications for:
- Sync failures (Slack/Teams/PagerDuty)
- Health check failures
- Image update automation commits

## Forbidden Patterns

- ❌ Direct `kubectl apply` to production (everything through GitOps)
- ❌ Unreviewed commits directly to the production GitOps branch
- ❌ Secrets in GitOps manifests (use Sealed Secrets or External Secrets Operator)
- ❌ `prune: false` in production (leads to orphaned resources)
- ❌ `selfHeal: false` in production (allows config drift)
- ❌ Using `default` ArgoCD project for production apps
- ❌ Image tag pinned to `latest` in GitOps manifests
