# Honeynet Architecture (Initial Draft)

## Goal

Deploy and manage honeypot infrastructure across multiple regions using modular Terraform.

## High-Level Design

1. Root Terraform stack orchestrates target regions.
2. A reusable `honeypot_region` module defines per-region deployment intent.
3. Region modules emit structured metadata for automation and downstream ingestion.
4. Future integrations will attach cloud resources, telemetry pipelines, and enrichment jobs.

## Why This Structure

- Region isolation supports blast-radius control and staged rollouts.
- Module reuse keeps configuration consistent across regions.
- Structured outputs simplify SIEM/analytics integration later.

## Planned Evolution

- Add cloud provider implementations (AWS/Azure/GCP) behind stable module interfaces.
- Add logging collectors and threat-intel enrichment workers.
- Add automated teardown and retention controls for cost governance.
