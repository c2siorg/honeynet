# Contributor issues

Use this list when opening GitHub issues or planning pull requests. Status reflects the repository as of the `feature/terraform-multi-region-honeypot` branch.

| ID | Title | Status |
|----|--------|--------|
| 1 | Bootstrap Terraform layout and `.gitignore` | Done (addressed in branch) |
| 2 | AWS honeypot module (VPC, Cowrie, flow logs) | Done |
| 3 | Per-region `env/*.tfvars`, deploy script, and CI (`terraform fmt` / `validate`) | Done |
| 4 | Remote state: S3 + DynamoDB lock table + docs | Open |
| 5 | Second cloud provider module (GCP or Azure) | Open |
| 6 | Ship Cowrie / container logs to S3 or CloudWatch Logs | Open |
| 7 | Document threat-intel enrichment hooks (e.g. export to SIEM) | Open |

## Copy-paste for GitHub

### Issue 4 — Remote Terraform state

**Goal:** Add production-ready remote backend (S3 + locking) and short setup steps.

**Acceptance criteria:**

- `terraform/backend.tf.example` replaced or supplemented with documented bootstrap commands for bucket + DynamoDB table.
- README section explains one state file per region vs. workspace strategy.

### Issue 5 — Additional cloud provider

**Goal:** Mirror `modules/aws-honeypot` patterns for GCP or Azure (single-region module + variables).

**Acceptance criteria:**

- Module under `terraform/modules/<provider>-honeypot/`.
- Example tfvars under `terraform/env/`.

### Issue 6 — Honeypot log export

**Goal:** Persist Cowrie (or successor) logs for analytics.

**Acceptance criteria:**

- Logs land in S3 or CloudWatch Logs with retention configurable via Terraform.
- No secrets in Terraform state.

### Issue 7 — Enrichment / SIEM

**Goal:** Document and optionally script correlation with external feeds (STIX/TAXII, commercial TI) or forwarding to Splunk/Elastic.

**Acceptance criteria:**

- Architecture diagram or bullet flow in README.
- Optional Lambda/EventBridge stub for normalization (can be no-op with README explaining extension points).
