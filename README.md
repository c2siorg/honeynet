# Honeynet

Honeynet is a Terraform-first framework for deploying and managing distributed honeypot infrastructure across multiple geographic regions.

The goal is to help defenders collect richer threat intelligence by simulating realistic attack surfaces in diverse cloud environments.

## Project Vision

- Automated provisioning, scaling, and teardown of honeypot infrastructure.
- Region-aware deployments for broader attacker telemetry.
- Standardized deployment metadata that can feed logging, analytics, and threat-intel pipelines.
- Modular Terraform design to support future multi-cloud backends.

## Current Status (Introductory Baseline)

This repository now includes an initial Terraform architecture scaffold:

- Root stack for orchestrating multiple regions.
- Reusable `honeypot_region` module.
- Example input variables for two regions.
- Terraform CI workflow for fmt and validate checks.

This baseline is intentionally cloud-agnostic so contributors can collaborate on interfaces before provider-specific resources are added.

## Repository Structure

```text
.
|-- docs/
|   `-- ARCHITECTURE.md
|-- terraform/
|   |-- main.tf
|   |-- outputs.tf
|   |-- terraform.tfvars.example
|   |-- variables.tf
|   |-- versions.tf
|   `-- modules/
|       `-- honeypot_region/
|           |-- main.tf
|           |-- outputs.tf
|           `-- variables.tf
`-- .github/
	|-- pull_request_template.md
	`-- workflows/
		`-- terraform-ci.yml
```

## Quick Start

1. Install Terraform 1.6 or newer.
2. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`.
3. Initialize and validate:

```bash
cd terraform
terraform init
terraform validate
terraform plan
```

## Roadmap (High-Level)

1. Add provider-specific implementations (AWS, Azure, GCP) behind stable module inputs.
2. Integrate centralized logging and enrichment hooks.
3. Define data contracts for SIEM and threat-intel feed integration.
4. Add lifecycle automation for cost-controlled teardown and redeployment.

## Contributing

Please read `CONTRIBUTING.md` for contribution workflow, validation expectations, and PR checklist.

## License

This project is released under the terms of the Apache-2.0 license.
