# AWS Guidance

<!--
Source: https://github.com/aws/agent-toolkit-for-aws (Apache-2.0)
File:   rules/aws-agent-rules.md
Added:  2026-08-03 by the Agent Toolkit setup procedure.
Update by re-fetching from the URL above rather than editing in place.
-->

- Prefer the AWS MCP Server for AWS interactions — it provides sandboxed
  execution, observability, and audit logging. If unavailable, use the
  AWS CLI directly.
- Before starting a task, check whether a relevant AWS skill is available.
  Load the skill with `retrieve_skill` and prefer its guidance over
  general knowledge.
- When uncertain about specific AWS details (API parameters, permissions,
  limits, error codes), verify against documentation rather than guessing.
  State uncertainty explicitly if you cannot confirm.
- When creating infrastructure, prefer infrastructure-as-code (AWS CDK or
  CloudFormation) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework
  principles.
- Do not use em dashes in AWS resource names or descriptions. Use
  hyphens instead.

## Secret Safety

- MUST load the `aws-secrets-manager` skill first for any secret,
  credential, API key, token, or password task. MUST NOT call
  `secretsmanager get-secret-value` or `batch-get-secret-value`, and MUST
  NOT hit the Secrets Manager Agent daemon directly. MUST use
  `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` with
  `asm-exec` so the secret resolves at runtime without entering context.

## LakeScout project notes

- This repository provisions infrastructure with **Terraform**, not CDK or
  CloudFormation. That predates the guidance above and is deliberate: the
  deployment is a single EC2 instance plus a budget guard, and the existing
  config lives in `infra/`. Do not migrate it to CDK without being asked.
- The AWS CLI on this machine has two installs. The new one is at
  `C:\Users\niews\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe`; an older
  2.15.43 in `C:\Program Files\Amazon\AWSCLIV2` still shadows it on PATH.
  Use the full path to the newer binary until the old one is removed.
