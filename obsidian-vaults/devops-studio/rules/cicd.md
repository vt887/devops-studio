# CI/CD Rules — DevOps Studio

Rules for the `cicd-spec` agent and all pipeline configuration in this project.

## Pipeline Structure Requirements

Every pipeline must include these stages in order:

```
1. validate       → lint, format check, IaC validate
2. test           → unit tests (required), integration tests (if applicable)
3. build          → container image build + push
4. scan           → security scanning (SAST, SCA, image scan)
5. deploy-staging → non-production deployment
6. verify         → smoke tests, integration tests
7. gate           → approval gate (manual or automated)
8. deploy-prod    → production deployment
9. verify-prod    → production smoke tests, synthetic monitors
```

## Mandatory Pipeline Steps

### Security Scanning (required in every pipeline)

```yaml
security-scan:
  steps:
    - name: SAST scan
      uses: <sast-tool>   # semgrep, sonarqube, etc.
    
    - name: Dependency scan
      run: |
        # npm audit, pip-audit, snyk, etc.
    
    - name: Container image scan
      run: |
        trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE
    
    - name: IaC scan
      run: |
        checkov -d terraform/ --quiet
        tfsec terraform/
```

## Secrets Management

- **NEVER** store secrets in pipeline YAML files
- Use CI/CD platform secrets store (GitHub Actions secrets, GitLab CI variables)
- For production secrets, integrate with Vault or cloud secrets manager
- Rotate CI/CD secrets on a defined schedule (90 days max)

```yaml
# Good — reference from secrets store
env:
  API_KEY: ${{ secrets.API_KEY }}

# Bad — hardcoded value
env:
  API_KEY: "abc123secret"
```

## Docker Build Rules

```yaml
# Always use specific base image versions
FROM node:20.11.0-alpine3.19   # Good
FROM node:latest               # Bad

# Build with explicit build args, not env vars containing secrets
docker build \
  --build-arg VERSION=${VERSION} \
  --no-cache \
  --label "git-commit=${COMMIT_SHA}" \
  -t ${IMAGE_NAME}:${VERSION} .
```

## Deployment Gates

Before production deployment, the pipeline must verify:
- [ ] All tests passed (unit + integration)
- [ ] Security scan passed (no CRITICAL findings)
- [ ] Image built and pushed successfully
- [ ] Staging deployment succeeded
- [ ] Smoke tests on staging passed

## Rollback Requirements

Every deployment stage must have a documented rollback procedure:

```yaml
deploy-prod:
  steps:
    - name: Deploy
      run: kubectl set image deployment/$APP $APP=$IMAGE:$VERSION
    
    - name: Verify deployment
      run: kubectl rollout status deployment/$APP --timeout=5m
      
    # If verify fails, automatic rollback:
    - name: Rollback on failure
      if: failure()
      run: kubectl rollout undo deployment/$APP
```

## Artifact Management

- All container images tagged with: `<semver>` and `<git-sha>`
- Images stored with content digest for verification
- Image retention: keep last 10 versions, delete older than 90 days
- Build artifacts signed and stored with provenance

## Pipeline Security

- Use minimal permissions for CI/CD service accounts
- Use OIDC federation (no long-lived credentials)
- Pin action versions with commit SHA (not version tags for critical actions)
- Validate external actions before use

```yaml
# Good — pinned to commit SHA
uses: actions/checkout@v4.1.1

# Better — pinned to commit SHA
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
```

## Notification Requirements

- Notify team on deployment failure
- Notify team on security scan failures with findings
- Post deployment summary to team channel on success

## Forbidden Patterns

- ❌ Secrets in pipeline YAML (even if "encrypted in git")
- ❌ Skipping security scan stages
- ❌ Deploying to production on every commit without gate
- ❌ Using `continue-on-error: true` on security scan steps
- ❌ Unpinned action versions in production pipelines
- ❌ Running CI with admin/root permissions
