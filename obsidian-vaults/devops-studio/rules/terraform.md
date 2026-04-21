# Terraform Rules — DevOps Studio

Rules for the `terraform-spec` agent and all Terraform code in this project.

## Structure Rules

1. **Module-first** — All reusable infrastructure is a module. No copy-paste of resource blocks across environments.
2. **Environment separation** — Each environment (`dev`, `staging`, `prod`) has its own root module in `terraform/environments/<env>/`.
3. **State isolation** — Each environment has its own remote state backend. Never share state between environments.
4. **Module versioning** — Pin module versions. Never use unpinned sources.

## Naming Conventions

```hcl
# Resources: <project>-<env>-<component>-<role>
resource "aws_instance" "prod_api_server" {}

# Variables: snake_case, descriptive
variable "cluster_node_count" {}

# Outputs: snake_case, descriptive
output "cluster_endpoint" {}
```

## Security Rules

1. **No hardcoded secrets** — Use `var` with sensitive=true, or reference from secrets manager
2. **No plaintext passwords** — Passwords via SSM Parameter Store or Secrets Manager
3. **Encryption by default** — All EBS, S3, RDS, ElasticSearch must have encryption enabled
4. **Least privilege IAM** — No wildcard actions (`*`) in production IAM policies
5. **Private by default** — S3 buckets private, public-access-block enabled
6. **Logging everywhere** — CloudTrail, S3 access logs, VPC flow logs enabled

## Required Tags

Every resource must include:
```hcl
tags = {
  Environment = var.environment  # dev/staging/prod
  Project     = var.project_name
  Team        = var.team_name
  ManagedBy   = "terraform"
  CostCenter  = var.cost_center
}
```

## State Management

```hcl
# Required backend configuration
terraform {
  backend "s3" {
    bucket         = "<project>-terraform-state"
    key            = "<env>/<component>/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "<project>-terraform-locks"
  }
}
```

## Provider Pinning

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Pin to major version
    }
  }
}
```

## Module Structure

Every module must contain:
```
terraform/modules/<module-name>/
├── main.tf        # Primary resources
├── variables.tf   # Input variables with descriptions and validations
├── outputs.tf     # Outputs with descriptions
└── README.md      # Module documentation (usage, inputs, outputs)
```

## Variable Validation

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Forbidden Patterns

- ❌ `terraform apply -auto-approve` in CI/CD without explicit gate approval
- ❌ `count` for resources that differ in config (use `for_each` instead)
- ❌ Interpolation in `depends_on` lists
- ❌ Local backends in non-development environments
- ❌ `ignore_changes` on security-relevant attributes without documented justification
