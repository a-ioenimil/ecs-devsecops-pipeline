Here is an industry-standard, professional Product Design Specification (PDS) that fully integrates the Infrastructure as Code (Terraform) layer with the AWS CodeDeploy mechanism and the DevSecOps pipeline.

This document is formatted to be presentation-ready for your portfolio or project submission.

---

# Product Design Specification (PDS)

**Project Name:** AuraScale DevSecOps Platform

**Document Version:** 1.0.0

**Target Environment:** Amazon ECS (Fargate/EC2)

**Author:** Isaac

**Date:** February 2026

---

## 1. Executive Summary

The AuraScale DevSecOps Platform is an automated, highly secure Continuous Integration and Continuous Deployment (CI/CD) system for a containerized FastAPI application. This specification defines a "Shift-Left" security architecture that blocks deployment upon the detection of critical vulnerabilities, hardcoded secrets, or dependency flaws. Furthermore, it outlines a zero-downtime Blue/Green deployment strategy orchestrated by AWS CodeDeploy and provisioned entirely via Terraform.

## 2. Infrastructure as Code (IaC) Architecture

All underlying AWS infrastructure required to support the AuraScale pipeline is defined declaratively using HashiCorp Terraform. This ensures the environment is reproducible, version-controlled, and immutable.

### 2.1 Terraform Module Design

The infrastructure is divided into logical modules to maintain a clean dependency graph:

* **Networking:** VPC, Public/Private Subnets, Security Groups, and Application Load Balancer (ALB).
* **Compute (ECS):** ECS Cluster, Task Definitions, and ECS Service configured with the `CODE_DEPLOY` deployment controller.
* **Routing:** Dual Target Groups (Blue/Green) and dual ALB Listeners (Production Port 80/443, Test Port 8080).
* **Delivery:** AWS CodeDeploy Application and Deployment Group configured for traffic shifting (e.g., `CodeDeployDefault.ECSAllAtOnce` or `ECSCanary10Percent5Minutes`).
* **Security & IAM:** Least-privilege IAM roles for Jenkins, ECS Task Execution, and CodeDeploy.

## 3. DevSecOps Quality Gates (The CI Pipeline)

The Continuous Integration pipeline (managed via Jenkins) enforces strict quality gates. If any stage returns a non-zero exit code due to a security finding, the pipeline immediately halts, preventing compromised artifacts from reaching the registry.

| Security Stage | Tooling | Execution Standard | Exit Condition |
| --- | --- | --- | --- |
| **Secret Scanning** | Gitleaks | Ephemeral container execution over source code. | Fails on any detected API keys/secrets. |
| **SAST** | SonarQube / CodeQL | Static analysis of Python (FastAPI) source code. | Fails on High/Critical logic or injection flaws. |
| **SCA** | Snyk / OWASP DC | Audit of `pyproject.toml` and `uv.lock`. | Fails on High/Critical dependency CVEs. |
| **Container Scan** | Trivy | Scanning the built Docker image (`app:latest`). | Fails on High/Critical OS/library CVEs. |
| **SBOM Generation** | Syft | Generates `sbom.json` in CycloneDX format. | N/A (Archived as build artifact). |

## 4. Continuous Deployment via AWS CodeDeploy

Once an image passes all security gates, it is pushed to Amazon ECR. Jenkins then hands over deployment orchestration to AWS CodeDeploy to execute a Blue/Green deployment.

### 4.1 Deployment Artifacts

The pipeline dynamically generates and registers the following files required by CodeDeploy:

1. **`taskdef.json`**: An updated ECS Task Definition referencing the newly built ECR image URI. It includes the `awslogs` log driver routing stdout/stderr to Amazon CloudWatch.
2. **`appspec.yaml`**: The CodeDeploy specification file detailing the ECS Service name, the newly registered Task Definition ARN, and the Container Port mapping (Port 8000).

### 4.2 Traffic Shifting & Automated Rollback

* **Traffic Routing:** CodeDeploy provisions the new "Green" task. Once healthy, the ALB listener rules are updated to shift traffic from the "Blue" Target Group to the "Green" Target Group.
* **Rollback Trigger:** CodeDeploy is integrated with CloudWatch Alarms (monitoring the Golden Signals: HTTP 5xx Error Rates and Latency). If an alarm triggers during the deployment window, CodeDeploy automatically halts traffic shifting and routes 100% of traffic back to the "Blue" environment.

## 5. Lifecycle Management & Cleanup

To optimize AWS costs and maintain environment hygiene, automated cleanup processes are integrated:

* **ECR Lifecycle Policies:** Configured via Terraform to automatically expire and delete untagged images or images older than 30 days.
* **ECS Task Revisions:** CodeDeploy automatically deregisters inactive ECS Task Definition revisions upon a successful Blue/Green deployment to prevent configuration sprawl.

## 6. Required Deliverables

To validate the implementation of this specification, the following artifacts must be provided:

1. **Infrastructure Code:** The `main.tf` and related Terraform files.
2. **Pipeline Configuration:** The complete `Jenkinsfile`.
3. **Security Evidence:** Failed pipeline logs demonstrating a blocked deployment after deliberately injecting a vulnerability.
4. **Deployment Evidence:** Screenshots of the AWS CodeDeploy console showing a successful Blue/Green traffic shift, and the generated `sbom.json` file.

---

This PDS gives a comprehensive, high-level view that covers all the lab requirements while sounding like a true Senior Platform Engineer wrote it.

**Would you like me to write the exact Terraform code (`main.tf`) that configures the ECS Service to use CodeDeploy and sets up those Blue/Green Target Groups?** 🛠️