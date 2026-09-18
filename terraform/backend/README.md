# Remote State Bootstrap

This module provisions the shared backend infrastructure required by all other
Terraform modules in the Honeynet project.

## Resources

| Resource                                             | Purpose                                                     |
| ---------------------------------------------------- | ----------------------------------------------------------- |
| `aws_s3_bucket`                                      | Stores `.tfstate` files for all modules                     |
| `aws_s3_bucket_versioning`                           | Enables recovery from accidental state corruption           |
| `aws_s3_bucket_server_side_encryption_configuration` | AES-256 at-rest encryption                                  |
| `aws_s3_bucket_public_access_block`                  | Prevents any public exposure of state files                 |
| `aws_s3_bucket_lifecycle_configuration`              | Expires old state versions after 90 days                    |
| `aws_dynamodb_table`                                 | Prevents concurrent `terraform apply` races (state locking) |

## Usage

This module must be applied **once** using local state before any other modules
are initialised with the remote backend.

```bash
cd terraform/backend
terraform init
terraform apply
```

After apply, copy the `backend_config_snippet` output into each module's
`terraform` block.

## Security notes

- State files may contain sensitive values (IP addresses, credentials). The
  bucket is fully private with SSE-AES256 enabled.
- The DynamoDB table uses `PAY_PER_REQUEST` billing — no capacity planning
  needed, cost is effectively zero at this scale.
- Point-in-time recovery is enabled on the lock table as a precaution.

```

**PR title:** `feat(terraform): provision remote state backend with S3 and DynamoDB locking`

**PR description:**
```

## Summary

Sets up the shared remote state infrastructure for the project. Currently all modules use local state, which means state files sit on developer laptops and concurrent applies can silently corrupt each other. This PR fixes that permanently.

## Problem

Local Terraform state is fine for a solo experiment, but the moment two contributors run `terraform apply` at the same time against the same environment, state corruption is a real risk. For a distributed honeynet with nodes in multiple regions and eventually multiple cloud providers, a robust state strategy is non-negotiable.

## What this adds

A standalone `terraform/backend/` module that provisions:

- **S3 bucket** with versioning, AES-256 server-side encryption, and public access fully blocked — state files contain sensitive output values (IPs, ARNs) and must never be publicly accessible
- **S3 lifecycle rule** that expires noncurrent state versions after 90 days, keeping storage costs near zero
- **DynamoDB table** (`PAY_PER_REQUEST`) for state locking — this ensures only one `terraform apply` runs at a time across all contributors and CI jobs
- **Point-in-time recovery** on the DynamoDB table for extra durability

## How to use

```bash
cd terraform/backend
terraform init        # uses local state just for this bootstrap
terraform apply
```

The `backend_config_snippet` output will print the exact `backend "s3" {}` block to paste into any other module.

## Design decisions

- Kept as a completely separate module so it can be applied with local state first — bootstrapping a remote backend with itself is a chicken-and-egg problem
- `force_destroy = false` on the S3 bucket intentionally prevents accidental state deletion via Terraform
- No KMS CMK for now — AES-256 managed key is sufficient and avoids additional IAM complexity at this stage

## Relation to existing PRs

This module is fully isolated — it touches no files from PR #3, #5, or #7. Other modules can adopt the backend config at their own pace.

Addresses the state management concern raised by @Aditya in #honeynet Slack.
