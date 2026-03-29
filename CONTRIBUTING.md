# Contributing to Honeynet

Thanks for contributing.

## Development Scope

This repository is building a Terraform-first, multi-region honeypot deployment framework.
Current focus:
- Reusable Terraform modules
- Region-based orchestration patterns
- Logging and threat-intel data contracts
- Automation for deployment and teardown

## Local Setup

1. Install Terraform 1.6+.
2. Clone the repository.
3. Run:

```bash
cd terraform
terraform init
terraform validate
```

## Contribution Rules

- Keep changes modular and cloud-agnostic where possible.
- Add or update documentation for new modules and variables.
- Include examples for user-facing Terraform inputs.
- Keep PRs focused and reviewable.

## Pull Request Checklist

- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` passes for changed stacks/modules
- [ ] Documentation updated (`README.md` and/or `docs/`)
- [ ] Backward compatibility considered for variables/outputs
