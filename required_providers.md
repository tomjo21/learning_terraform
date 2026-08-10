# Provider Configuration

The `required_providers` block in Terraform is used to declare and specify the required provider configurations for your Terraform module or configuration. It allows you to specify the provider name, source, and version constraints.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0, < 3.0"
    }
  }
}
```

## Breakdown

- **`terraform` block** — a top-level block used to configure Terraform's own behavior, including required providers, required Terraform version, and backend configuration.
- **`required_providers` block** — nested inside the `terraform` block, it lists every provider your configuration depends on.
- **Provider name** (e.g., `aws`, `azurerm`) — the local name used to reference the provider elsewhere in your configuration.
- **`source`** — the provider's source address, typically in the format `<NAMESPACE>/<PROVIDER>` (e.g., `hashicorp/aws`). This tells Terraform where to download the provider from (usually the Terraform Registry).
- **`version`** — a version constraint that restricts which provider versions Terraform is allowed to install.

## Version Constraint Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Exact version | `= 3.0.0` |
| `!=` | Excludes a version | `!= 3.0.0` |
| `>`, `>=`, `<`, `<=` | Comparison | `>= 2.0, < 3.0` |
| `~>` | Pessimistic constraint — allows only the rightmost version component to increment | `~> 3.0` allows `3.x` but not `4.0` |

## Why It Matters

- **Consistency** — ensures everyone working on the project, and any CI/CD pipeline, uses compatible provider versions.
- **Predictability** — prevents unexpected breaking changes from newer provider releases being installed automatically.
- **Multiple providers** — as shown above, you can declare several providers (e.g., `aws` and `azurerm`) in the same block when your configuration spans multiple platforms.

## Related: Provider Block vs required_providers Block

- The `required_providers` block only declares **which providers and versions** are needed — it does not configure the provider itself (like region or credentials).
- You still need a separate `provider` block (e.g., `provider "aws" { region = "us-east-1" }`) to actually configure the provider for use.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```