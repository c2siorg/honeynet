# Honeynet System Architecture & Threat Model

This document outlines the high-level architecture, data pipeline, and security boundaries of the Multi-Cloud Honeynet project.

## 1. High-Level Topology

The system is designed to be distributed across multiple cloud providers (AWS, GCP) to capture a diverse set of threat intelligence, while routing all telemetry back to a centralized, isolated management plane.

```mermaid
graph TD
    subgraph "GCP (Region A)"
        GCP_Node[Ubuntu Shielded VM<br/>Bait: 22, 23, 80]
        GCP_VPC[Isolated VPC]
        GCP_Node --- GCP_VPC
    end

    subgraph "AWS (Region B)"
        AWS_Node[EC2 Instance<br/>Bait: 2222, 8080]
        AWS_VPC[Isolated VPC]
        AWS_Node --- AWS_VPC
    end

    subgraph "Central Management Plane (AWS)"
        S3_State[(Terraform State S3)]
        S3_Logs[(Raw Log Sink S3)]
        ELK[Elasticsearch / Kibana]

        GCP_Node -- Filebeat / TLS --> S3_Logs
        AWS_Node -- Filebeat / TLS --> S3_Logs
        S3_Logs --> ELK
    end

## 2. Network Interaction Model ("Contain, Don't Propagate")

The core philosophy of this honeynet is that **nodes will inevitably be compromised, but they must never become launchpads for further attacks.**

* **Ingress:** Open strictly to designated bait ports (e.g., 22, 23, 80). Management access (SSH) is heavily restricted to specific operator IP ranges.
* **Egress:** Default deny-all. The nodes are only permitted outbound access to:
  * OS package repositories (for updates/fetching tools).
  * The centralized logging endpoint (over TLS port 443).

## 3. Threat Model

To ensure the safety of the honeynet operators and the cloud environments, we model the following threats:

| Asset | Threat | Mitigation Strategy |
| :--- | :--- | :--- |
| **Cloud Environment** | Attacker escapes VM and queries metadata service to pivot via IAM. | Least-privilege Service Accounts / IAM roles. Nodes possess zero cross-account or infrastructure-altering permissions. |
| **Log Integrity** | Attacker deletes local logs to cover their tracks. | Logs are immediately streamed off-host via Filebeat to an append-only S3 bucket. |
| **Terraform State** | Concurrent deployments corrupt the state file, or state is leaked. | Remote S3 backend with AES-256 encryption, blocked public access, and DynamoDB state locking. |
| **Other Networks** | Attacker uses the compromised honeypot to launch DDoS or scan other networks. | Strict egress firewall rules dropping outbound traffic to RFC1918 addresses and non-essential internet ports. |
```
