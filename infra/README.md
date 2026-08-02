# Infrastructure

Terraform for the LakeScout deployment. Currently the budget guard only — compute
resources arrive in week 8.

## Order matters

The budget alarm is applied **before** anything that can cost money. That is a
non-functional requirement, not a preference.

## Usage

Copy the example variables and fill in the alert address:

```bash
cp example.tfvars lakescout.tfvars
```

```bash
terraform -chdir=infra init
```

```bash
terraform -chdir=infra plan -var-file=lakescout.tfvars
```

```bash
terraform -chdir=infra apply -var-file=lakescout.tfvars
```

AWS Budgets sends a confirmation email to each subscriber address. **Alerts do not
deliver until that email is confirmed** — applying the Terraform is not sufficient on its
own.

`lakescout.tfvars` is gitignored. `example.tfvars` is not; keep real addresses out of it.

## State

Local state for now. If this ever runs from more than one machine, move it to an S3
backend with DynamoDB locking before the second machine touches it.
